#!/usr/bin/env bash
# Levelupp Stop hook (M_AIDLC Plugin §5.3) — best-effort structured audit line to the session
# cache (who/what/when). Never blocks; never writes into the customer repo. Mirrors the playbook
# audit_log.sh, retargeted off the repo to the cache dir.
set -uo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/levelupp"
mkdir -p "$CACHE_DIR" 2>/dev/null || true

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"
printf '{"ts":"%s","event":"stop","git_remote":"%s"}\n' "$TS" "$REMOTE" \
  >> "$CACHE_DIR/audit.jsonl" 2>/dev/null || true

exit 0
