#!/usr/bin/env bash
# Levelupp PreToolUse (Bash) hook (M_AIDLC Plugin §5.2, v2 §7) — the runtime gate.
#
# Order (each step short-circuits):
#   0. Gate inactive (AIDLC off / unreachable, from the SessionStart cache) → exit 0 (allow).
#   1. Local classification (NO network for the common case): match the command against the
#      cached classification map. No gated class → exit 0 (allow) immediately.
#   2. Offline MUST-NEVER hard-floor (v2 §7, F6): if the class is MUST-NEVER (protected-branch
#      push, commit secrets, hard data-delete), DENY locally — no server call, NOT fail-open.
#   3. Other gated class → curl authorize-action; map decision → permissionDecision.
#   4. Server unreachable for a SOFTER class → fail-open (user scope) with a warning, unless
#      LEVELUPP_FAIL_CLOSED is set (managed scope) → deny.
#
# Treats the command as DATA (never eval). Conservative matching (false positive → an extra call,
# never a missed gate). Reads the tool-call JSON on stdin.
set -uo pipefail

BASE_URL="${LEVELUPP_BASE_URL:-https://levelupp.misikiri.com}"
API_KEY="${LEVELUPP_API_KEY:-}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/levelupp"
GATE_STATE="$(cat "$CACHE_DIR/gate_state" 2>/dev/null || echo "inactive")"

INPUT="$(cat)"

# 0. Gate inactive → allow.
if [ "$GATE_STATE" != "active" ]; then exit 0; fi

allow() { exit 0; }
deny()  { # $1 = reason
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
    "permissionDecision": "deny", "permissionDecisionReason": sys.argv[1]}}))
PY
  exit 0
}
ask()   { # $1 = reason
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
    "permissionDecision": "ask", "permissionDecisionReason": sys.argv[1]}}))
PY
  exit 0
}

# 1 + 2. Classify locally against the cached map; apply the offline MUST-NEVER floor.
#    Emits one of: "allow" | "MUSTNEVER <class>" | "GATED <class>".
CLASSIFY="$(python3 - "$INPUT" "$CACHE_DIR/constitution.json" <<'PY'
import json, re, sys, os
raw, cache_path = sys.argv[1], sys.argv[2]
try:
    cmd = json.loads(raw).get("tool_input", {}).get("command", "") or ""
except Exception:
    cmd = ""
try:
    cm = json.load(open(cache_path)).get("classification_map", {})
except Exception:
    cm = {}

def glob_to_re(g):
    return re.escape(g).replace(r"\*", ".*")

def matches_any(patterns):
    return any(re.search(glob_to_re(p), cmd, re.IGNORECASE) for p in (patterns or []))

cls = None
# protected-branch push
if "git push" in cmd:
    for b in cm.get("protected_branches", []):
        if re.search(r"(\s|:)" + glob_to_re(b) + r"(\s|$)", cmd):
            cls = "push_protected"; break
    if cls is None and re.search(r"git push[^|;&]*(--force|--force-with-lease|\s-f)(\s|$)", cmd):
        cls = "push_protected"
if cls is None and matches_any(cm.get("data_delete_patterns")):   cls = "data_delete"
if cls is None and matches_any(cm.get("secret_patterns")):        cls = "secret_access"
if cls is None and matches_any(cm.get("release_globs")):          cls = "release"
if cls is None and matches_any(cm.get("infra_patterns")):         cls = "infra_change"

if cls is None:
    print("allow")
else:
    must_never = set(cm.get("must_never", []))
    print(("MUSTNEVER " if cls in must_never else "GATED ") + cls)
PY
)"

case "$CLASSIFY" in
  allow|"") allow ;;
  MUSTNEVER*)
    CLASS="${CLASSIFY#MUSTNEVER }"
    deny "Blocked by the Levelupp MUST-NEVER floor: '$CLASS' is prohibited without explicit human sign-off (offline, network-independent). Open a PR / get the named gate owner's approval." ;;
esac

# 3. Other gated class → call the server.
CLASS="${CLASSIFY#GATED }"
GIT_REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"
BO_ID="$(cat "$CACHE_DIR/bo_id" 2>/dev/null || echo "")"

if [ -z "$API_KEY" ]; then
  # No key — softer-class fail-open/closed decision.
  if [ -n "${LEVELUPP_FAIL_CLOSED:-}" ]; then deny "Levelupp unreachable (no key) and fail-closed is set — '$CLASS' denied."; fi
  ask "Levelupp: no API key — cannot verify the gate for '$CLASS'. Proceed only with human sign-off."
fi

BODY="$(python3 - "$GIT_REMOTE" "$CLASS" "$BO_ID" "$INPUT" <<'PY'
import json, sys
remote, cls, bo, raw = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
details = {}
try:
    details["command"] = json.loads(raw).get("tool_input", {}).get("command", "")
except Exception:
    pass
out = {"git_remote": remote, "action_class": cls, "details": details}
if bo:
    out["bo_id"] = bo
print(json.dumps(out))
PY
)"

RESP="$(printf '%s' "$BODY" | curl -fsS --max-time 6 -X POST \
  -H "X-API-Key: $API_KEY" -H "Content-Type: application/json" \
  --data @- "$BASE_URL/builder/aidlc/authorize-action" 2>/dev/null)"
CURL_RC=$?

if [ $CURL_RC -ne 0 ] || [ -z "$RESP" ]; then
  # 4. Server unreachable for a softer class → fail-open (warning) unless fail-closed.
  if [ -n "${LEVELUPP_FAIL_CLOSED:-}" ]; then deny "Levelupp unreachable and fail-closed is set — '$CLASS' denied."; fi
  ask "Levelupp unreachable — could not verify the gate for '$CLASS' (failing open with a warning). Proceed only with human sign-off."
fi

# Map decision → permissionDecision.
python3 - "$RESP" <<'PY'
import json, sys
try:
    d = json.loads(sys.argv[1])
except Exception:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
        "permissionDecision": "ask", "permissionDecisionReason": "Levelupp returned an unparseable response — proceed only with human sign-off."}}))
    sys.exit(0)
decision = d.get("decision", "ask")
reason = d.get("reason", "")
owner = d.get("owner")
riders = d.get("open_riders") or []
if owner:
    reason += f" Owner: {owner.get('display_name')} ({owner.get('delivery_role')})."
if riders:
    reason += f" Open riders: {', '.join(riders)}."
pd = {"allow": "allow", "deny": "deny", "ask": "ask"}.get(decision, "ask")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "PreToolUse",
    "permissionDecision": pd, "permissionDecisionReason": reason}}))
PY
exit 0
