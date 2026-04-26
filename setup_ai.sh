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
"
            [ -d "$target" ] && rm -rf "$target"
            ln -s "$personal_skills_repo/$skill" "$target"
            echo "  linked $skill -> $personal_skills_repo/$skill"
        done
    else
        echo "  (skip) personal skills repo not found at $personal_skills_repo"
    fi

    # --- MCP config (~/.mcp.json) ---
    echo ""
    echo "MCP Servers"
    echo "-----------"
    read -p "Install Claude MCP servers? (y/n) " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local mcp_dest="$HOME/.mcp.json"
        local mcp_src
        mcp_src=$(find_source "mcp.json")
        [ -z "$mcp_src" ] && mcp_src="$SETTINGS_BASE/2-ai/mcp.json"

        local do_install=true
        if [ -f "$mcp_dest" ]; then
            read -p "  ~/.mcp.json already exists. Overwrite? (y/n) " -n 1 -r; echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && do_install=false
        fi

        if [ "$do_install" = true ] && [ -f "$mcp_src" ]; then
            [ -L "$mcp_dest" ] && rm "$mcp_dest"
            cp "$mcp_src" "$mcp_dest"
            echo "  copied $mcp_src -> $mcp_dest"

            if grep -q "home-assistant" "$mcp_dest"; then
                echo ""
                echo "  Home Assistant server detected."
                read -p "    URL (enter = ${HOMEASSISTANT_URL:-keep placeholder}): " HA_URL
                HA_URL="${HA_URL:-$HOMEASSISTANT_URL}"
                [ -n "$HA_URL" ] && sed -i '' "s|YOUR_HOMEASSISTANT_URL|$HA_URL|g" "$mcp_dest" && echo "    Set HOMEASSISTANT_URL."
                read -p "    Long-lived token (enter = keep placeholder): " HA_TOKEN
                HA_TOKEN="${HA_TOKEN:-$HOMEASSISTANT_TOKEN}"
                [ -n "$HA_TOKEN" ] && sed -i '' "s|YOUR_LONG_LIVED_TOKEN|$HA_TOKEN|g" "$mcp_dest" && echo "    Set HOMEASSISTANT_TOKEN."
            fi
            chmod 600 "$mcp_dest"
        else
            [ "$do_install" = false ] && echo "  Skipped."
            [ ! -f "$mcp_src" ] && echo "  (skip) source not found: $mcp_src"
        fi
    fi

    # --- AI tool configs ---
    echo ""
    echo "Copying AI tool configs..."

    [ -L "$HOME/.groq" ] && rm "$HOME/.groq"
    mkdir -p "$HOME/.groq"
    _install_file "groq/local-settings.json" "$HOME/.groq/local-settings.json"

    [ -L "$HOME/.gemini" ] && rm "$HOME/.gemini"
    mkdir -p "$HOME/.gemini"
    _install_file "gemini/settings.json"  "$HOME/.gemini/settings.json"
    _install_file "gemini/GEMINI.md"      "$HOME/.gemini/GEMINI.md"
    _install_file "gemini/projects.json"  "$HOME/.gemini/projects.json"

    [ -L "$HOME/.continue" ] && rm "$HOME/.continue"
    mkdir -p "$HOME/.continue"
    local cont_src
    cont_src=$(find_source "continue/config.yaml")
    [ -z "$cont_src" ] && cont_src="$SETTINGS_BASE/2-ai/continue/config.yaml"
    _copy_file "$cont_src" "$HOME/.continue/config.yaml"

    # --- IDE selection ---
    echo ""
    echo "IDE Selection"
    echo "-------------"
    echo "  1) VS Code   (recommended — broader extension ecosystem)"
    echo "  2) Windsurf  (VS Code fork with built-in Codeium AI)"
    echo "  3) Both      (deploy configs for both, install neither)"
    echo ""
    read -p "Which IDE? [1/2/3] (Enter = 1): " IDE_CHOICE
    IDE_CHOICE="${IDE_CHOICE:-1}"

    if [[ "$IDE_CHOICE" == "2" || "$IDE_CHOICE" == "3" ]]; then
        [ -L "$HOME/.codeium" ] && rm "$HOME/.codeium"
        mkdir -p "$HOME/.codeium"
        _install_file "windsurf/codeium-config.json" "$HOME/.codeium/config.json"

        [ -L "$HOME/.windsurf" ] && rm "$HOME/.windsurf"
        mkdir -p "$HOME/.windsurf"
        _install_file "windsurf/argv.json" "$HOME/.windsurf/argv.json"
        print_status "Windsurf config deployed."
    fi

    if [[ "$IDE_CHOICE" == "1" || "$IDE_CHOICE" == "3" ]]; then
        print_info "VS Code config: extensions are installed via 'setup vscode' in the menu."
        print_info "Continue config is shared with both IDEs at ~/.continue/config.yaml."
    fi

    [ -L "$HOME/.config/opencode" ] && rm "$HOME/.config/opencode"
    mkdir -p "$HOME/.config/opencode"
    _install_file "opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

    [ -L "$HOME/.ollama" ] && rm "$HOME/.ollama"
    mkdir -p "$HOME/.ollama"
    _install_file "ollama/config.json" "$HOME/.ollama/config.json"

    mkdir -p "$HOME/.config/crush"
    _install_file "crush/crush.json" "$HOME/.config/crush/crush.json"

    mkdir -p "$HOME/.config/grok"
    _install_file "grok/grok.json" "$HOME/.config/grok/grok.json"

    mkdir -p "$HOME/.config/litellm"
    _install_file "litellm/.env"         "$HOME/.config/litellm/.env"
    _install_file "litellm/litellm.yaml" "$HOME/.config/litellm/config.yaml"

    # --- Shell profile.d ---
    echo ""
    echo "Copying profile.d files..."
    local profiled_src="$SETTINGS_BASE/2-ai/$MAC_MODEL/profile.d"
    [ ! -d "$profiled_src" ] && profiled_src="$SETTINGS_BASE/config/profile.d"
    if [ -d "$profiled_src" ]; then
        mkdir -p "$HOME/.profile.d"
        cp -R "$profiled_src/." "$HOME/.profile.d/"
        echo "  copied profile.d/ -> $HOME/.profile.d/"
    fi

    print_status "AI tool configs deployed."
}

# Function to backup existing configurations
backup_existing_configs() {
    print_status "Backing up existing AI tool configurations..."
    backup_continue
    backup_opencode
    backup_crush
    backup_claude
    backup_grok
    backup_olol
    backup_litellm
    print_status "All existing configurations backed up successfully"
}

# Function to restore configurations from backup
restore_configs() {
    print_status "Restoring AI tool configurations from backup..."
    restore_continue
    restore_opencode
    restore_crush
    restore_claude
    restore_grok
    restore_olol
    restore_litellm
    print_status "All configurations restored successfully"
}

verify_installations() {
    print_info "Verifying tool installations..."
    local verification_results=""
    local all_passed=true
    for check in verify_claude_code verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_litellm verify_github_copilot; do
        local label="${check#verify_}"
        if $check; then
            verification_results="$verification_results ✓ $label - OK\n"
        else
            verification_results="$verification_results ✗ $label - FAILED\n"
            all_passed=false
        fi
    done
    echo -e "$verification_results"
    if [ "$all_passed" = true ]; then
        print_status "All AI development tools are properly installed and functional"
    else
        print_warning "Some tools may require manual configuration or additional setup"
        return 1
    fi
}

install_tools() {
    check_system_requirements
    verify_claude_code  || setup_claude    || print_error "Failed to install Claude Code"
    verify_opencode     || setup_opencode  || print_error "Failed to install OpenCode"
    verify_crush        || setup_crush     || print_error "Failed to install Crush"
    verify_codex        || setup_codex     || print_error "Failed to install Codex"
    verify_gemini       || setup_gemini    || print_error "Failed to install Gemini"
    verify_grok         || setup_grok      || print_error "Failed to install Grok"
    verify_groq         || setup_groq      || print_error "Failed to install Groq"
    verify_litellm      || setup_litellm      || print_error "Failed to install LiteLLM"
    verify_anythingllm  || setup_anythingllm  || print_error "Failed to install AnythingLLM"
    verify_github_copilot || setup_github_copilot || print_error "Failed to install GitHub Copilot"
    verify_installations
}

# Dispatch a single action+tool pair
_run_one() {
    local action="$1" tool="$2"
    case "$action:$tool" in
        setup:claude)     setup_claude ;;
        setup:codex)      setup_codex ;;
        setup:continue)   setup_continue ;;
        setup:crush)      setup_crush ;;
        setup:exo)        setup_exo ;;
        teardown:exo)     teardown_exo ;;
        setup:gemini)     setup_gemini ;;
        setup:grok)       setup_grok ;;
        setup:groq)       setup_groq ;;
        setup:models)     install_coding_assistants ;;
        setup:ollama)     setup_ollama ;;
        setup:olol)       setup_olol ;;
        setup:anythingllm) setup_anythingllm ;;
        setup:litellm)    setup_litellm ;;
        setup:opencode)   setup_opencode ;;
        setup:copilot)    setup_github_copilot ;;
        setup:vscode)     setup_vscode ;;
        setup:windsurf)   setup_windsurf ;;
        restore:claude)   restore_claude ;;
        restore:continue) restore_continue ;;
        restore:crush)    restore_crush ;;
        restore:grok)     restore_grok ;;
        restore:groq)     restore_groq ;;
        restore:litellm)  restore_litellm ;;
        restore:olol)     restore_olol ;;
        restore:opencode) restore_opencode ;;
        restore:*)        print_info "No restore available for $tool — skipping" ;;
        backup:claude)    backup_claude ;;
        backup:continue)  backup_continue ;;
        backup:crush)     backup_crush ;;
        backup:grok)      backup_grok ;;
        backup:groq)      backup_groq ;;
        backup:litellm)   backup_litellm ;;
        backup:olol)      backup_olol ;;
        backup:opencode)  backup_opencode ;;
        backup:*)         print_info "No backup available for $tool — skipping" ;;
    esac
}

_run_for_tools() {
    local action="$1"; shift
    for tool in "$@"; do
        _run_one "$action" "$tool"
    done
}

# Interactive tool picker and action selector
interactive_menu() {
    # All available tools and their descriptions
    local tools=(
        ollama
        models
        vscode
        windsurf
        claude
        codex
        crush
        gemini
        grok
        groq
        opencode
        continue
        litellm
        anythingllm
        copilot
        exo
        olol
    )
    local descs=(
        "ollama      - install server + start via brew services"
        "models      - install / prune Ollama models (auto-detects hardware)"
        "vscode      - install VS Code + Continue + Cline extensions"
        "windsurf    - install Windsurf IDE + deploy argv.json"
        "claude      - install CLI + deploy config"
        "codex       - install Codex CLI"
        "crush       - install + deploy config"
        "gemini      - install Gemini CLI"
        "grok        - install + deploy config"
        "groq        - deploy Groq config + API key instructions"
        "opencode    - install + deploy config"
        "continue    - deploy Continue.dev config"
        "litellm     - install proxy + deploy config"
        "anythingllm - install + configure Ollama provider"
        "copilot     - install gh-copilot extension + VS Code extensions"
        "exo         - install exo distributed inference"
        "olol        - install Ollama load balancer"
    )
    # Default selections
    local sel=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

    while true; do
        echo ""
        echo "=== Select tools  (number to toggle, a=all, n=none, q=confirm) ==="
        for i in "${!tools[@]}"; do
            local mark; [ "${sel[$i]}" = "1" ] && mark="[x]" || mark="[ ]"
            printf "  %s %2d. %s\n" "$mark" "$((i+1))" "${descs[$i]}"
        done
        echo ""
        printf "Choice: "
        read -r input
        case "$input" in
            q|"") break ;;
            a) for i in "${!tools[@]}"; do sel[$i]=1; done ;;
            n) for i in "${!tools[@]}"; do sel[$i]=0; done ;;
            *)
                for num in $(echo "$input" | tr ',;' '  '); do
                    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#tools[@]} )); then
                        local idx=$((num-1))
                        sel[$idx]=$(( 1 - sel[$idx] ))
                    fi
                done
            ;;
        esac
    done

    local chosen=()
    for i in "${!tools[@]}"; do
        [ "${sel[$i]}" = "1" ] && chosen+=("${tools[$i]}")
    done

    if [ ${#chosen[@]} -eq 0 ]; then
        print_warning "No tools selected."
        return
    fi

    echo ""
    echo "=== Select action ==="
    echo "  1. setup   - backup existing + apply new config / install"
    echo "  2. restore - restore from latest backup"
    echo "  3. backup  - backup only"
    echo ""
    printf "Action [1]: "
    read -r act
    act="${act:-1}"

    case "$act" in
        1|setup)   _run_for_tools setup   "${chosen[@]}" ;;
        2|restore) _run_for_tools restore "${chosen[@]}" ;;
        3|backup)  _run_for_tools backup  "${chosen[@]}" ;;
        *) print_error "Invalid action"; return 1 ;;
    esac
}

# Main execution function
main() {
    case "$1" in
        backup)
            backup_existing_configs
        ;;
        restore)
            restore_configs
        ;;
        continue)
            setup_continue
        ;;
        opencode)
            setup_opencode
        ;;
        crush)
            setup_crush
        ;;
        claude)
            setup_claude
        ;;
        setup)
            setup_continue
            setup_opencode
            setup_crush
            setup_claude
            setup_github_copilot
            print_status "All tool configurations applied"
        ;;
        vscode)
            setup_vscode
        ;;
        windsurf)
            setup_windsurf
        ;;
        ollama)
            setup_ollama
        ;;
        grok)
            setup_grok
        ;;
        groq)
            setup_groq
        ;;
        olol)
            setup_olol
        ;;
        exo)
            setup_exo
        ;;
        teardown-exo)
            teardown_exo
        ;;
        codex)
            setup_codex
        ;;
        gemini)
            setup_gemini
        ;;
        litellm)
            setup_litellm
        ;;
        anythingllm)
            setup_anythingllm
        ;;
        copilot)
            setup_github_copilot
        ;;
        check)
            check_system_requirements
        ;;
        verify)
            verify_installations
        ;;
        install)
            install_tools
        ;;
        models)
            install_coding_assistants
        ;;
        deploy)
            deploy_configs
        ;;
        "")
            interactive_menu
        ;;
        *)
            echo "Usage: $0 {backup|restore|deploy|vscode|windsurf|continue|opencode|crush|claude|setup|ollama|grok|olol|exo|codex|gemini|litellm|anythingllm|copilot|check|verify|install|models}"
            echo "  (no args)   - Interactive tool picker"
            echo "  deploy      - Copy all AI tool configs to their home-directory locations"
            echo "  backup      - Backup all existing configurations"
            echo "  restore     - Restore all configurations from backup"
            echo "  vscode      - Install VS Code + Continue + Cline extensions"
            echo "  windsurf    - Install Windsurf IDE + deploy configs"
            echo "  continue    - Setup Continue.dev (backup + copy config)"
            echo "  opencode    - Setup OpenCode (backup + copy config)"
            echo "  crush       - Setup Crush (backup + copy config)"
            echo "  claude      - Setup Claude Code (install CLI + copy config)"
            echo "  setup       - Setup all tool configs at once"
            echo "  ollama      - Install + start Ollama server"
            echo "  models      - Install / prune Ollama models (auto-detects hardware)"
            echo "  grok        - Setup Grok CLI (offline AI via Ollama)"
            echo "  olol        - Setup olol: Ollama load balancer across multiple machines"
            echo "  exo         - Setup exo: split inference across Apple Silicon devices"
            echo "  codex       - Install Codex CLI"
            echo "  gemini      - Install Gemini CLI"
            echo "  litellm     - Setup LiteLLM proxy (install + deploy config)"
            echo "  anythingllm - Install AnythingLLM + print Ollama provider config"
            echo "  copilot     - Install gh-copilot extension + VS Code Copilot extensions"
            echo "  check       - Check system requirements"
            echo "  verify      - Verify all tool installations"
            echo "  install     - Install all tools (check + install-if-missing + verify)"
            exit 1
        ;;
    esac

    echo ""
    echo "=== AI TOOL CONFIGURATION PROCESS COMPLETED ==="
    echo "Backup directory: $BACKUP_DIR"
}

# Run the script with provided argument
main "$1"
