#!/opt/homebrew/bin/bash
# tool-scout.sh — Wrapper for scripts/tool-scout.py
#
# Usage: tool-scout list|search|add|remove|sync|find-brew|find-npm|find-vscode
#
# This is the CLI entrypoint. tool-scout.py contains the catalog and logic.

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "tool-scout.sh must be executed, not sourced." >&2
  return 1 2>/dev/null || exit 1
fi

if [ -z "${SETTINGS_BASE:-}" ]; then
  SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

SCOUT_PY="${SETTINGS_BASE}/scripts/tool-scout.py"
[[ -f "$SCOUT_PY" ]] || die "tool-scout.py not found at $SCOUT_PY"
command -v python3 >/dev/null 2>&1 || die "python3 not found"

# ── Run scout ─────────────────────────────────────────────────────────────
log_info "Launching tool scout..."
python3 "$SCOUT_PY" "$@"

# Passthrough exit code
exit ${PIPESTATUS[0]}
