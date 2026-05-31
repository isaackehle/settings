#!/opt/homebrew/bin/bash
# agent-scout.sh — Discover new terminal-based AI agents not yet in the repo
#
# Usage:
#   agent-scout.sh [--json]
#   agent-scout.sh --generate <name>
#
# Mirrors model-scout.sh but for AI agents/tools rather than LLM models.

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "agent-scout.sh must be executed, not sourced." >&2
  return 1 2>/dev/null || exit 1
fi

if [ -z "${SETTINGS_BASE:-}" ]; then
  SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

SCOUT_PY="${SETTINGS_BASE}/scripts/agent-scout.py"
[[ -f "$SCOUT_PY" ]] || die "agent-scout.py not found at $SCOUT_PY"
command -v python3 >/dev/null 2>&1 || die "python3 not found"

generate_agent() {
  local name="$1"
  log_info "Generating stub for $name ..."
  python3 "$SCOUT_PY" --repo-root "$SETTINGS_BASE" --generate "$name"
}

# ── Run scout ─────────────────────────────────────────────────────────────
log_info "Launching agent scout..."
echo ""

if [[ "${1:-}" == "--generate" ]]; then
  shift
  generate_agent "${1:-}"
  exit 0
fi

if [[ "${1:-}" == "--json" ]]; then
  python3 "$SCOUT_PY" --repo-root "$SETTINGS_BASE" --json
  exit 0
fi

# Default: show fzf-friendly list with option to generate
declare -a _entries=()
while IFS=$'\t' read -r name display_line; do
  [[ -z "$name" ]] && continue
  _entries+=("$name|$display_line")
done < <(python3 "$SCOUT_PY" --repo-root "$SETTINGS_BASE")

if [[ ${#_entries[@]} -eq 0 ]]; then
  log_status "No new agents found — your catalog is current."
  exit 0
fi

# Show via fzf if available
if command -v fzf >/dev/null 2>&1; then
  _lines=()
  for e in "${_entries[@]}"; do
    _lines+=("$(echo "$e" | cut -d'|' -f2)")
  done
  _selected="$(printf '%s\n' "${_lines[@]}" | fzf --header "Select agent to generate (Esc=quit)" --layout=reverse)"
  if [[ -n "$_selected" ]]; then
    for e in "${_entries[@]}"; do
      _disp="$(echo "$e" | cut -d'|' -f2)"
      if [[ "$_disp" == "$_selected" ]]; then
        _name="$(echo "$e" | cut -d'|' -f1)"
        read -p "Generate ai/${_name}.sh + default config? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
          _stub="$(generate_agent "$_name")"
          _dest="${SETTINGS_BASE}/ai/${_name}.sh"
          echo "$_stub" > "$_dest"
          chmod +x "$_dest"
          log_status "Created $_dest"

          # Generate default config
          _ext="$(python3 -c "
import json,sys
c=[c for c in json.load(open('${SCOUT_PY}'.replace('.py','_catalog.json') if False else '${SCOUT_PY}'))]
print('')
" 2>/dev/null || echo "")"
          # Fallback: infer from stub content
          _cfg_dir="${SETTINGS_BASE}/ai/profiles/default/${_name}"
          mkdir -p "$_cfg_dir"
          python3 "$SCOUT_PY" --repo-root "$SETTINGS_BASE" --generate "$_name" 2>/dev/null | head -1 || true
          # Best-effort: create empty config placeholder
          touch "$_cfg_dir/.gitkeep"
          log_info "Config dir prepared: $_cfg_dir"
          log_info "Next steps:"
          log_info "  1. Review $_dest"
          log_info "  2. Add profile-specific configs under ai/profiles/<machine>/${_name}/"
          log_info "  3. Register the tool in setup_ai.sh (source, TOOL_GROUPS, GROUP_SETUP_FUNCS, ...)"
        fi
        break
      fi
    done
  fi
else
  # No fzf — just print
  for e in "${_entries[@]}"; do
    echo "$(echo "$e" | cut -d'|' -f2)"
  done
  echo ""
  echo "Run with fzf installed for interactive generation, or:"
  echo "  bash agent-scout.sh --generate <name>"
fi

echo ""
log_success "Done."
