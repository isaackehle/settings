#!/opt/homebrew/bin/bash
# swap-model.sh — interactively replace a model for a given role and machine
# Cascades the change to all affected config files.
# Usage: swap-model.sh [--help]

set -euo pipefail

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SETTINGS_BASE/.." && pwd)"

# Source models.sh to load current mappings (provides OPENCODE_AGENTS_*, CLAUDE_CODE_*, etc.)
# shellcheck source=models.sh
source "$SETTINGS_BASE/models.sh"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Machine key → repo subdirectory name
declare -A MACHINE_DIRS=(
    ["64gb"]="macbook-m5-64gb"
    ["48gb"]="macbook-m5-48gb"
    ["m1"]="macbook-m1"
    ["m2"]="macmini-m2"
)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log_info()    { echo -e "${BLUE}ℹ${NC} $*"; }
log_success() { echo -e "${GREEN}✓${NC} $*"; }
log_warn()    { echo -e "${YELLOW}⚠${NC} $*"; }
log_error()   { echo -e "${RED}✗${NC} $*" >&2; }
die()         { log_error "$*"; exit 1; }

# Ollama colon form → LiteLLM dash form  (qwen3-32b:q5 → qwen3-32b-q5)
colon_to_dash() { echo "${1//:/-}"; }

# Return the agent-map array name for a given machine key
agents_array_for() {
    case "$1" in
        64gb) echo "OPENCODE_AGENTS_64GB" ;;
        48gb) echo "OPENCODE_AGENTS_48GB" ;;
        m1|m2) echo "OPENCODE_AGENTS_16GB" ;;
    esac
}

# ============================================================================
# MENU / PROMPT FUNCTIONS
# ============================================================================

show_role_menu() {
    local mem_class="$1"
    local arr_name
    arr_name=$(agents_array_for "$mem_class")
    
    # Read current models from the sourced associative array
    local -n _agents="$arr_name"
    
    echo ""
    echo "── CURRENT MODELS ($mem_class) ──────────────────────────────────"
    local roles=("coding" "reasoning" "research" "writing" "planning")
    local keys=("code"    "think"     "research" "write"   "plan")
    for i in "${!roles[@]}"; do
        printf "  %d) %-12s  %s\n" "$((i+1))" "${roles[$i]}" "${_agents[${keys[$i]}]:-<unset>}"
    done
    echo ""
}

prompt_role_menu() {
    local mem_class="$1"
    show_role_menu "$mem_class"
    
    local num_roles=5
    while true; do
        read -r -p "Select role [1-$num_roles]: " role_idx
        if [[ "$role_idx" =~ ^[1-5]$ ]]; then break; fi
        log_error "Invalid selection. Please enter 1-$num_roles."
    done
    
    case "$role_idx" in
        1) echo "coding" ;;
        2) echo "reasoning" ;;
        3) echo "research" ;;
        4) echo "writing" ;;
        5) echo "planning" ;;
    esac
}

prompt_machine_class() {
    echo ""
    echo "── SELECT MACHINE ──────────────────────────────────────────────────"
    echo "  1) 64GB   (M5 Max MacBook 64GB)"
    echo "  2) 48GB   (M5 Max MacBook 48GB)"
    echo "  3) M1     (MacBook M1)"
    echo "  4) M2     (Mac mini M2)"
    echo ""
    
    while true; do
        read -r -p "Select machine [1-4]: " mc_idx
        if [[ "$mc_idx" =~ ^[1-4]$ ]]; then break; fi
        log_error "Invalid selection. Please enter 1-4."
    done
    
    case "$mc_idx" in
        1) echo "64gb" ;;
        2) echo "48gb" ;;
        3) echo "m1" ;;
        4) echo "m2" ;;
    esac
}

# ============================================================================
# FILE UPDATE FUNCTIONS
# ============================================================================

# Update models.sh: agent map entry + CLAUDE_CODE_* var + CONTINUE_ROLES entry
update_models_sh() {
    local role="$1"
    local mem_class="$2"
    local old_colon="$3"
    local new_colon="$4"
    
    local new_dash
    new_dash=$(colon_to_dash "$new_colon")
    local old_dash
    old_dash=$(colon_to_dash "$old_colon")
    
    local arr_name
    arr_name=$(agents_array_for "$mem_class")
    local suffix="${mem_class^^}"  # 64GB→64GB, 48GB→48GB, m1→M1, m2→M2
    
    # Map role name → array key
    local agent_key
    case "$role" in
        coding)   agent_key="code" ;;
        reasoning) agent_key="think" ;;
        research) agent_key="research" ;;
        writing)  agent_key="write" ;;
        planning) agent_key="plan" ;;
    esac
    
    log_info "Updating models.sh..."
    
    # 1. Update OPENCODE_AGENTS_* entry (colon form in array)
    sed -i '' "/declare -A ${arr_name}=/,/^)/s|\[${agent_key}\]=\"${old_colon}\"|[${agent_key}]=\"${new_colon}\"|" \
    "$SETTINGS_BASE/models.sh"
    log_success "  models.sh: OPENCODE_AGENTS_${suffix}[$agent_key]"
    
    # 2. Update CONTINUE_ROLES_* entry for coding→chat, reasoning→think (colon form)
    local continue_key=""
    case "$role" in
        coding)   continue_key="chat" ;;
    esac
    if [[ -n "$continue_key" && ( "$mem_class" == "64gb" || "$mem_class" == "48gb" ) ]]; then
        local continue_arr="CONTINUE_ROLES_${suffix}"
        sed -i '' "/declare -A ${continue_arr}=/,/^)/s|\[${continue_key}\]=\"${old_colon}\"|[${continue_key}]=\"${new_colon}\"|" \
        "$SETTINGS_BASE/models.sh"
        log_success "  models.sh: ${continue_arr}[$continue_key]"
    fi
    
    # 3. Update CLAUDE_CODE_* variable (colon form stored in models.sh)
    case "$role" in
        coding)
            local sonnet_var="CLAUDE_CODE_SONNET_${suffix}"
            sed -i '' "s|${sonnet_var}=\"${old_colon}\"|${sonnet_var}=\"${new_colon}\"|" \
            "$SETTINGS_BASE/models.sh"
            log_success "  models.sh: ${sonnet_var}"
        ;;
        planning)
            local haiku_var="CLAUDE_CODE_HAIKU_${suffix}"
            sed -i '' "s|${haiku_var}=\"${old_colon}\"|${haiku_var}=\"${new_colon}\"|" \
            "$SETTINGS_BASE/models.sh"
            log_success "  models.sh: ${haiku_var}"
        ;;
    esac
    
    # 4. Warn about CUSTOM_MODELS if coding role — chain aliases need manual update
    if [[ "$role" == "coding" ]]; then
        log_warn "  models.sh: CUSTOM_MODELS_${suffix} base/32k/220k aliases need manual update"
        log_warn "  → Edit CUSTOM_MODELS_${suffix} in models.sh to update source URL + derived aliases"
    fi
}

update_litellm_yaml() {
    local machine_dir="$1"
    local old_colon="$2"
    local new_colon="$3"
    
    local old_dash new_dash
    old_dash=$(colon_to_dash "$old_colon")
    new_dash=$(colon_to_dash "$new_colon")
    local litellm_file="$machine_dir/litellm/litellm.yaml"
    
    if [[ ! -f "$litellm_file" ]]; then
        log_warn "LiteLLM config not found: $litellm_file"
        return
    fi
    
    log_info "Updating $(basename "$machine_dir")/litellm/litellm.yaml..."
    
    # model_name: qwen3-coder-30b-32k-q5   (unquoted dash form)
    sed -i '' "s|model_name: ${old_dash}|model_name: ${new_dash}|g" "$litellm_file"
    
    # model: ollama_chat/qwen3-coder-30b-32k:q5   (colon form)
    sed -i '' "s|ollama_chat/${old_colon}|ollama_chat/${new_colon}|g" "$litellm_file"
    
    # router alias values: "qwen3-coder-30b-32k-q5"  (quoted dash form)
    sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$litellm_file"
    
    log_success "  $(basename "$machine_dir")/litellm/litellm.yaml"
}

update_continue_config() {
    local machine_dir="$1"
    local old_colon="$2"
    local new_colon="$3"
    
    local old_dash new_dash
    old_dash=$(colon_to_dash "$old_colon")
    new_dash=$(colon_to_dash "$new_colon")
    local continue_file="$machine_dir/continue/config.yaml"
    
    if [[ ! -f "$continue_file" ]]; then
        log_warn "Continue config not found: $continue_file"
        return
    fi
    
    log_info "Updating $(basename "$machine_dir")/continue/config.yaml..."
    
    # model: "qwen3-coder-30b-32k-q5"  (quoted dash form)
    sed -i '' "s|model: \"${old_dash}\"|model: \"${new_dash}\"|g" "$continue_file"
    
    log_success "  $(basename "$machine_dir")/continue/config.yaml"
}

update_claude_settings() {
    local machine_dir="$1"
    local old_colon="$2"
    local new_colon="$3"
    
    local old_dash new_dash
    old_dash=$(colon_to_dash "$old_colon")
    new_dash=$(colon_to_dash "$new_colon")
    local claude_file="$machine_dir/claude/settings.json"
    
    if [[ ! -f "$claude_file" ]]; then
        log_warn "Claude settings not found: $claude_file"
        return
    fi
    
    log_info "Updating $(basename "$machine_dir")/claude/settings.json..."
    
    # "qwen3-coder-30b-32k-q5"  (quoted dash form — both env values and "model" key)
    sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$claude_file"
    
    log_success "  $(basename "$machine_dir")/claude/settings.json"
}

update_opencode_config() {
    local machine_dir="$1"
    local old_colon="$2"
    local new_colon="$3"
    
    local opencode_file="$machine_dir/opencode/opencode.jsonc"
    
    if [[ ! -f "$opencode_file" ]]; then
        log_warn "OpenCode config not found: $opencode_file"
        return
    fi
    
    log_info "Updating $(basename "$machine_dir")/opencode/opencode.jsonc..."
    
    # Model list keys + agent values use colon form (direct Ollama, port 11434)
    # "qwen3-coder-30b-32k:q5": { ... }
    sed -i '' "s|\"${old_colon}\"|\"${new_colon}\"|g" "$opencode_file"
    # ollama/qwen3-coder-30b-32k:q5
    sed -i '' "s|ollama/${old_colon}|ollama/${new_colon}|g" "$opencode_file"
    
    log_success "  $(basename "$machine_dir")/opencode/opencode.jsonc"
}

update_grok_config() {
    local machine_dir="$1"
    local old_colon="$2"
    local new_colon="$3"
    
    local old_dash new_dash
    old_dash=$(colon_to_dash "$old_colon")
    new_dash=$(colon_to_dash "$new_colon")
    local grok_file="$machine_dir/grok/grok.json"
    
    if [[ ! -f "$grok_file" ]]; then
        log_warn "Grok config not found: $grok_file"
        return
    fi
    
    log_info "Updating $(basename "$machine_dir")/grok/grok.json..."
    
    # Grok routes through LiteLLM → dash form
    sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$grok_file"
    
    log_success "  $(basename "$machine_dir")/grok/grok.json"
}

update_obsidian_profile() {
    local mem_class="$1"
    local old_colon="$2"
    local new_colon="$3"
    
    local obsidian_file="$REPO_ROOT/config/profile.d/_obsidian"
    
    if [[ ! -f "$obsidian_file" ]]; then
        log_warn "_obsidian profile not found"
        return
    fi
    
    log_info "Updating config/profile.d/_obsidian..."
    
    # The profile uses colon form for Ollama direct calls
    sed -i '' "s|${old_colon}|${new_colon}|g" "$obsidian_file"
    
    log_success "  config/profile.d/_obsidian"
}

# ============================================================================
# MAIN FLOW
# ============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           SWAP AI MODEL — Interactive Configuration             ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    
    # Select machine
    local mem_class
    mem_class=$(prompt_machine_class)
    echo ""
    log_info "Machine: $mem_class (${MACHINE_DIRS[$mem_class]})"
    
    # Select role — reads current models from sourced arrays
    local role
    role=$(prompt_role_menu "$mem_class")
    echo ""
    log_info "Role: $role"
    
    # Look up current model from sourced array
    local arr_name
    arr_name=$(agents_array_for "$mem_class")
    local -n _cur_agents="$arr_name"
    
    local agent_key
    case "$role" in
        coding)   agent_key="code" ;;
        reasoning) agent_key="think" ;;
        research) agent_key="research" ;;
        writing)  agent_key="write" ;;
        planning) agent_key="plan" ;;
    esac
    
    local current_model="${_cur_agents[$agent_key]:-}"
    if [[ -z "$current_model" ]]; then
        die "Could not determine current model for $role on $mem_class"
    fi
    
    # Prompt for replacement
    echo ""
    echo "  Current: $current_model"
    echo ""
    read -r -p "New model alias (Ollama colon form, e.g. qwen3-32b:q6): " new_alias
    new_alias="${new_alias// /}"  # trim whitespace
    
    if [[ -z "$new_alias" ]]; then
        die "Model alias cannot be empty."
    fi
    
    local new_dash
    new_dash=$(colon_to_dash "$new_alias")
    
    # Confirm
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                       CHANGE SUMMARY                            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "  %-12s %s\n" "Machine:"  "$mem_class (${MACHINE_DIRS[$mem_class]})"
    printf "  %-12s %s\n" "Role:"     "$role"
    printf "  %-12s %s\n" "Old:"      "$current_model"
    printf "  %-12s %s  →  %s\n" "New:" "$new_alias" "$new_dash"
    echo ""
    echo "  Files that will be updated:"
    echo "    scripts/models.sh"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/litellm/litellm.yaml"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/continue/config.yaml"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/claude/settings.json"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/opencode/opencode.jsonc"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/grok/grok.json"
    [[ "$role" == "research" ]] && echo "    config/profile.d/_obsidian"
    echo ""
    
    read -r -p "Continue? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    echo ""
    local machine_dir="$SETTINGS_BASE/${MACHINE_DIRS[$mem_class]}"
    if [[ ! -d "$machine_dir" ]]; then
        die "Machine directory not found: $machine_dir"
    fi
    
    # Apply all updates
    update_models_sh    "$role" "$mem_class" "$current_model" "$new_alias"
    update_litellm_yaml "$machine_dir" "$current_model" "$new_alias"
    update_continue_config "$machine_dir" "$current_model" "$new_alias"
    update_claude_settings "$machine_dir" "$current_model" "$new_alias"
    update_opencode_config "$machine_dir" "$current_model" "$new_alias"
    update_grok_config  "$machine_dir" "$current_model" "$new_alias"
    
    if [[ "$role" == "research" ]]; then
        update_obsidian_profile "$mem_class" "$current_model" "$new_alias"
    fi
    
    echo ""
    log_success "Done. Changes applied to repo — commit when ready."
    echo ""
    
    # Offer to pull and install the new model
    echo ""
    read -r -p "Pull new model via install_coding_assistants? (y/n): " install_choice
    if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
        # install_coding_assistants is a bash function defined in install-models.sh
        source "$SETTINGS_BASE/install-models.sh"
        install_coding_assistants
    fi
    
    echo ""
}

main "$@"
