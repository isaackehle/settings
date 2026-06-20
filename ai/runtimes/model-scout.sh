#!/opt/homebrew/bin/bash
# model-scout.sh — fetch current model recommendations and update config

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "model-scout.sh must be executed, not sourced." >&2
  return 1 2>/dev/null || exit 1
fi

if [ -z "${SETTINGS_BASE:-}" ]; then
  SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

SCOUT_PY="${SETTINGS_BASE}/scripts/model-scout.py"
[[ -f "$SCOUT_PY" ]] || die "model-scout.py not found at $SCOUT_PY"
command -v python3 >/dev/null 2>&1 || die "python3 not found"

# ── Select target machine and deploy mode ────────────────────────────────────
mem_class=$(prompt_machine_class)    || die "No machine selected."
deploy_mode=$(prompt_deployment_mode)

machine_dir="$SETTINGS_BASE/${MACHINE_DIRS[$mem_class]:-}"
[[ -d "$machine_dir" ]] || die "Machine directory not found: $machine_dir"

# Source models to get current values for the selected machine
local_models_file="$machine_dir/models.sh"
[[ -f "$local_models_file" ]] && source "$local_models_file"

# ── Run scout ────────────────────────────────────────────────────────────────
log_info "Launching model scout…"
echo ""

declare -A UPDATES=()
while IFS='=' read -r role model; do
  [[ -z "$role" || -z "$model" ]] && continue
  UPDATES["$role"]="$model"
done < <(python3 "$SCOUT_PY")

if [[ ${#UPDATES[@]} -eq 0 ]]; then
  log_warning "No roles updated."
  exit 0
fi

# ── Preview changes ──────────────────────────────────────────────────────────
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  Change Summary                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

declare -A AGENT_KEY=(
  [coding]=code [reasoning]=think [research]=research [writing]=write [planning]=plan
)

for role in "${!UPDATES[@]}"; do
  new_model="${UPDATES[$role]}"
  key="${AGENT_KEY[$role]:-}"
  current="${OPENCODE_AGENTS[$key]:-<unset>}"
  printf "  %-12s  %s  →  %s\n" "$role" "$current" "$new_model"
done

echo ""
read -r -p "Apply these changes? (y/n): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { log_info "Cancelled."; exit 0; }

# ── Apply updates ────────────────────────────────────────────────────────────
echo ""
for role in "${!UPDATES[@]}"; do
  new_model="${UPDATES[$role]}"
  key="${AGENT_KEY[$role]:-}"
  current="${OPENCODE_AGENTS[$key]:-}"

  log_info "Updating $role: $current → $new_model"

  update_models_sh       "$role" "$mem_class" "$current" "$new_model" "$deploy_mode"
  update_continue_config "$machine_dir" "$current" "$new_model" "$deploy_mode"
  update_claude_settings "$machine_dir" "$current" "$new_model" "$deploy_mode"
  update_opencode_config "$machine_dir" "$current" "$new_model" "$deploy_mode"
  update_grok_config     "$machine_dir" "$current" "$new_model" "$deploy_mode"

  [[ "$role" == "research" ]] && \
    update_obsidian_profile "$mem_class" "$current" "$new_model"
done

echo ""
log_success "Done. Commit when ready."
