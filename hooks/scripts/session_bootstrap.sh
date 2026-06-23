#!/usr/bin/env bash
# Levelupp SessionStart hook (M_AIDLC Plugin §5.1) — inject the live workspace constitution
# (Plane 2) and write the session classification cache the PreToolUse hook reads.
#
# Implemented as a command hook (HTTP GET), NOT mcp_tool: MCP servers typically fire before
# servers finish connecting at SessionStart, so an mcp_tool fetch here is racy (Plugin §6, F1).
#
# NEVER blocks session start and NEVER writes into the customer repo (cache under
# $XDG_CACHE_HOME/levelupp). AIDLC off → {enabled:false} → inject nothing, mark gate inactive,
# exit 0. Unreachable / not registered → short notice, exit 0.
set -uo pipefail

BASE_URL="${LEVELUPP_BASE_URL:-https://levelupp.misikiri.com}"
API_KEY="${LEVELUPP_API_KEY:-}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/levelupp"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

# Resolve the git remote from the cwd (best-effort).
GIT_REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"

emit_context() {
  # $1 = additionalContext string
  python3 - "$1" <<'PY'
import json, sys
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": sys.argv[1]}}))
PY
}

write_cache() {
  # $1 = gate state (active|inactive), $2 = constitution JSON ("" when none)
  printf '%s' "${2:-{}}" > "$CACHE_DIR/constitution.json" 2>/dev/null || true
  printf '%s' "$1" > "$CACHE_DIR/gate_state" 2>/dev/null || true
}

if [ -z "$API_KEY" ]; then
  write_cache "inactive" ""
  emit_context "Levelupp: LEVELUPP_API_KEY not set — guidance and gating inactive this session."
  exit 0
fi

RESP="$(curl -fsS --max-time 8 \
  -H "X-API-Key: $API_KEY" \
  "$BASE_URL/builder/aidlc/constitution?git_remote=$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$GIT_REMOTE")" 2>/dev/null)"
CURL_RC=$?

if [ $CURL_RC -ne 0 ] || [ -z "$RESP" ]; then
  # Unreachable or not registered — fail open, never block (Plugin §5.1 step 5).
  write_cache "inactive" ""
  emit_context "Levelupp: server unreachable or repo not registered — guidance and gating inactive this session; run aidlc_status."
  exit 0
fi

# Parse the payload: {enabled:false} → dormant; else inject rendered_markdown + cache the map.
python3 - "$RESP" "$CACHE_DIR" <<'PY'
import json, sys, os
resp, cache_dir = sys.argv[1], sys.argv[2]
try:
    data = json.loads(resp)
except Exception:
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart",
        "additionalContext": "Levelupp: unexpected response — gating inactive this session."}}))
    sys.exit(0)

if data.get("enabled") is False:
    # AIDLC off for this workspace — installed but dormant.
    open(os.path.join(cache_dir, "gate_state"), "w").write("inactive")
    open(os.path.join(cache_dir, "constitution.json"), "w").write("{}")
    print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": ""}}))
    sys.exit(0)

# Active — cache the classification map + open riders for the PreToolUse hook, inject the markdown.
cache = {
    "classification_map": data.get("classification_map", {}),
    "open_riders": data.get("open_riders", []),
}
open(os.path.join(cache_dir, "gate_state"), "w").write("active")
open(os.path.join(cache_dir, "constitution.json"), "w").write(json.dumps(cache))
md = data.get("rendered_markdown", "")
print(json.dumps({"hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": md}}))
PY
exit 0
