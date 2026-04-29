#!/opt/homebrew/bin/bash
# swap-model.sh — interactively replace a model for a given role and machine
# Cascades the change to all affected config files.
# Usage: swap-model.sh [--help]

set -euo pipefail

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SETTINGS_BASE/.." && pwd)"

. "${SETTINGS_BASE}/utils.sh"

# Shared backup globals (used by all setup scripts)
DATE="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/settings-backups"
mkdir -p "$BACKUP_DIR"


# Machine folder → folder name (Used for resolution in update functions)
declare -A MACHINE_DIRS=(
    ["macbook-m1-16gb"]="2-ai/profiles/macbook-m1-16gb"
    ["macbook-m2-32gb"]="2-ai/profiles/macbook-m2-32gb"
    ["macbook-m5-48gb"]="2-ai/profiles/macbook-m5-48gb"
    ["macbook-m5-64gb"]="2-ai/profiles/macbook-m5-64gb"
    ["macmini-m2-16gb"]="2-ai/profiles/macmini-m2-16gb"
)


# Find the best source file: model-specific takes precedence over default.
# Usage: find_source <relative-path-within-settings-repo>
# Prints the resolved path, or empty string if not found.
find_source() {
    local rel="$1"

    local model=$(_detect_profile)

    local model_path="$SETTINGS_BASE/profiles/$model/$rel"
    local default_path="$SETTINGS_BASE/scripts/$rel"
    if [ -f "$model_path" ]; then
        echo "$model_path"
        elif [ -f "$default_path" ]; then
        echo "$default_path"
    else
        echo ""
    fi
}

# Copy src to dest, backing up any existing non-symlink file first.
copy_file() {
    local src="$1"
    local dest="$2"

    if [ -z "$src" ] || [ ! -f "$src" ]; then
        echo "  (skip) source not found for $dest"
        return
    fi

    # Skip if destination is already a file and identical to source
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        echo "  (skip) $dest is already up to date"
        return
    fi

    # Remove stale symlink
    if [ -L "$dest" ]; then
        rm "$dest"
        # Back up a real file that is different from what we'd copy
        elif [ -f "$dest" ]; then
        mv "$dest" "${dest}.backup-$(date +%s)"
        echo "  backed up existing $(basename "$dest")"
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  copied $src -> $dest"
}

# Same as copy_file but looks up the source via find_source.
# Usage: install_file <rel-path-in-settings> <dest>
install_file() {
    local rel="$1"
    local dest="$2"
    local src
    src=$(find_source "$rel")
    copy_file "$src" "$dest"
}



# ============================================================================
# PROFILE DETECTION & MANAGEMENT
# ============================================================================

PROFILES_DIR="$SETTINGS_BASE/2-ai/profiles"
declare -A _PROFILE_CACHE

_get_profile_numbers() {
    # List directories in profiles dir, sorted
    ls -d "$PROFILES_DIR"/*/ 2>/dev/null | while read -r d; do
        basename "$d"
    done | sort
}

_load_profile() {
    local folder="$1"
    local profile_file="$PROFILES_DIR/$folder/PROFILE"
    if [[ ! -f "$profile_file" ]]; then return 1; fi

    # Load key=value pairs into cache
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" == \#* ]] && continue
        _PROFILE_CACHE["p${folder}_${key}"]="$value"
    done < "$profile_file"
}

_profile_name() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_NAME]:-Unknown}"
}

_profile_memory() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_MEMORY]:-0}"
}

_profile_computer_types() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_COMPUTER_TYPES]:-}"
}

_profile_description() {
    local folder="$1"
    _load_profile "$folder"
    echo "${_PROFILE_CACHE[p${folder}_DESCRIPTION]:-No description}"
}

_does_profile_match_computer() {
    local folder="$1"
    local hw_mem=$2
    local hw_model=$3

    _load_profile "$folder" || return 1

    local min=${_PROFILE_CACHE[p${folder}_MEMORY_RANGE_MIN]:-0}
    local max=${_PROFILE_CACHE[p${folder}_MEMORY_RANGE_MAX]:-9999}

    if [[ "$hw_mem" -lt "$min" || "$hw_mem" -gt "$max" ]]; then
        return 1
    fi

    local types=${_PROFILE_CACHE[p${folder}_COMPUTER_TYPES]:-""}
    IFS=',' read -ra patterns <<< "$types"
    for pattern in "${patterns[@]}"; do
        if [[ "$hw_model" == $pattern ]]; then
            return 0
        fi
    done

    return 1
}

_detect_hw() {
    HW_MODEL=$(sysctl -n hw.model 2>/dev/null || echo "Unknown")
    HW_MEM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
}

_detect_profile() {
    _detect_hw
    local best_match=""
    local best_mem=0

    while IFS= read -r folder; do
        if _does_profile_match_computer "$folder" "$HW_MEM_GB" "$HW_MODEL"; then
            local mem
            mem=$(_profile_memory "$folder")
            if [[ "$mem" -gt "$best_mem" ]]; then
                best_match="$folder"
                best_mem="$mem"
            fi
        fi
    done < <(_get_profile_numbers)

    echo "${best_match:-}"
}

get_profile_for_choice() {
    local choice="$1"

    # If it's a number, resolve index
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
        local idx=$choice
        local profile
        profile=$( _get_profile_numbers | sed -n "${idx}p")
        echo "$profile"
    # If it's already a valid folder name
    elif [[ -d "$PROFILES_DIR/$choice" ]]; then
        echo "$choice"
    else
        return 1
    fi
}

# ============================================================================
# MENU / PROMPT FUNCTIONS
# ============================================================================

show_model_suggestions() {
    local mode="$1"
    echo "" >&2
    echo "  💡 Suggestions:" >&2
    if [[ "$mode" == "openrouter" ]]; then
        echo "    - anthropic/claude-3.5-sonnet" >&2
        echo "    - google/gemini-flash-1.5" >&2
        echo "    - meta-llama/llama-3.1-405b" >&2
        echo "    - deepseek/deepseek-chat" >&2
    else
        echo "    - llama3.2:latest" >&2
        echo "    - qwen2.5-coder:7b" >&2
        echo "    - mistral-nemo" >&2
        echo "    - phi4:latest" >&2
    fi
    echo "" >&2
}

show_role_menu() {
    local mem_class="$1"

    # Read current models from the sourced associative array
    local -n _agents="OPENCODE_AGENTS"

    echo "" >&2
    echo "── CONFIGURE AGENT MODELS ─────────────────────────────────────" >&2
    echo "Set the model identifier for each agent role." >&2
    echo "" >&2
    echo "Current configuration ($mem_class):" >&2
    local roles=("coding" "reasoning" "research" "writing" "planning")
    local keys=("code"    "think"     "research" "write"   "plan")
    for i in "${!roles[@]}"; do
        printf "  %d) %-12s  %s\n" "$((i+1))" "${roles[$i]}" "${_agents[${keys[$i]}]:-<unset>}" >&2
    done
    echo "  6) ALL ROLES (Apply same model to all)" >&2
    echo "" >&2
}

prompt_role_menu() {
    local mem_class="$1"
    show_role_menu "$mem_class"

    local num_roles=6
    while true; do
        read -r -p "Which role are you configuring? [1-6]: " role_idx
        if [[ "$role_idx" =~ ^[1-6]$ ]]; then break; fi
        log_error "Invalid selection. Please enter 1-$num_roles."
    done

    case "$role_idx" in
        1) echo "coding" ;;
        2) echo "reasoning" ;;
        3) echo "research" ;;
        4) echo "writing" ;;
        5) echo "planning" ;;
        6) echo "all" ;;
    esac
}

print_profile_menu() {
    local detected="$1"
    local i=1
    local profile_num

    echo "  Detected hardware: $(_profile_name "$detected") (auto-selected as [$detected])" >&2
    echo "" >&2

    while IFS= read -r profile_num; do
        echo "  $i) $(_profile_name "$profile_num") — $(_profile_description "$profile_num")" >&2
        i=$((i + 1))
    done < <(_get_profile_numbers)

    echo "  $i) exo — distributed inference across Apple Silicon Macs" >&2
    i=$((i + 1))
    echo "  $i) Cancel" >&2
}

prompt_machine_class() {
    local detected
    detected=$(_detect_profile)

    echo "" >&2
    echo "── SELECT MACHINE ──────────────────────────────────────────────────" >&2
    print_profile_menu "$detected"
    echo "" >&2

    local choice
    read -p "Select machine (Enter = $detected): " choice
    choice="${choice:-$detected}"

    # Get profile folder from choice
    local profile
    profile=$(get_profile_for_choice "$choice") || {
        log_error "Invalid selection."
        return 1
    }
    echo "$profile"
}

prompt_deployment_mode() {
    echo "" >&2
    echo "── SELECT DEPLOYMENT MODE ──────────────────────────────────────────" >&2
    echo "  1) Ollama Only (Direct)" >&2
    echo "  2) Ollama + LiteLLM (Proxy)" >&2
    echo "  3) Ollama + OpenRouter (External)" >&2
    echo "" >&2

    local choice
    read -p "Select mode [1-3] (Default: 2): " choice
    choice="${choice:-2}"

    case "$choice" in
        1) echo "ollama" ;;
        2) echo "litellm" ;;
        3) echo "openrouter" ;;
        *)
            log_error "Invalid selection. Defaulting to LiteLLM."
            echo "litellm"
            ;;
    esac
}

# ============================================================================
# FILE UPDATE FUNCTIONS
# ============================================================================

# Update models.sh: agent map entry + CLAUDE_CODE_* var + CONTINUE_ROLES entry
update_models_sh() {
    local role="$1"
    local mem_class="$2"
    local old_val="$3"
    local new_val="$4"
    local mode="$5"

    local suffix="${mem_class^^}"

    # Map role name → array key
    local agent_key=""
    case "$role" in
        coding)   agent_key="code" ;;
        reasoning) agent_key="think" ;;
        research) agent_key="research" ;;
        writing)  agent_key="write" ;;
        planning) agent_key="plan" ;;
        *)        agent_key="" ;;
    esac

    log_info "Updating models.sh..."

    local machine_dir="$SETTINGS_BASE/${MACHINE_DIRS[$mem_class]:-}"

    # For models.sh, we generally store the identifier used by the app
    # (Colon for Ollama, ID for OpenRouter)
    sed -i '' "/declare -A OPENCODE_AGENTS=/,/^)/s|\[${agent_key}\]=\"${old_val}\"|[${agent_key}]=\"${new_val}\"|" \
    "$machine_dir/models.sh"
    log_success "  models.sh: OPENCODE_AGENTS[$agent_key]"

    local continue_key=""
    case "$role" in
        coding)   continue_key="chat" ;;
    esac
    if [[ -n "$continue_key" && ( "$mem_class" == "64gb" || "$mem_class" == "48gb" ) ]]; then
        local continue_arr="CONTINUE_ROLES_${suffix}"
        sed -i '' "/declare -A ${continue_arr}=/,/^)/s|\[${continue_key}\]=\"${old_val}\"|[${continue_key}]=\"${new_val}\"|" \
        "$machine_dir/models.sh"
        log_success "  models.sh: ${continue_arr}[$continue_key]"
    fi

    case "$role" in
        coding)
            local sonnet_var="CLAUDE_CODE_SONNET_${suffix}"
            sed -i '' "s|${sonnet_var}=\"${old_val}\"|${sonnet_var}=\"${new_val}\"|" \
            "$machine_dir/models.sh"
            log_success "  models.sh: ${sonnet_var}"
        ;;
        planning)
            local haiku_var="CLAUDE_CODE_HAIKU_${suffix}"
            sed -i '' "s|${haiku_var}=\"${old_val}\"|${haiku_var}=\"${new_val}\"|" \
            "$machine_dir/models.sh"
            log_success "  models.sh: ${haiku_var}"
        ;;
    esac

    if [[ "$role" == "coding" ]]; then
        log_warn "  models.sh: CUSTOM_MODELS_${suffix} aliases need manual update"
    fi
}

update_litellm_yaml() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local litellm_file="$machine_dir/litellm/litellm.yaml"
    if [[ ! -f "$litellm_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/litellm/litellm.yaml..."

    if [[ "$mode" == "litellm" ]]; then
        local old_dash=$(colon_to_dash "$old_val")
        local new_dash=$(colon_to_dash "$new_val")
        sed -i '' "s|model_name: ${old_dash}|model_name: ${new_dash}|g" "$litellm_file"
        sed -i '' "s|ollama_chat/${old_val}|ollama_chat/${new_val}|g" "$litellm_file"
        sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$litellm_file"
    elif [[ "$mode" == "openrouter" ]]; then
        # OpenRouter usually doesn't use ollama_chat/ prefix in litellm.yaml
        sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$litellm_file"
    fi

    log_success "  $(basename "$machine_dir")/litellm/litellm.yaml"
}

update_continue_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local continue_file="$machine_dir/continue/config.yaml"
    if [[ ! -f "$continue_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/continue/config.yaml..."

    if [[ "$mode" == "litellm" ]]; then
        local old_dash=$(colon_to_dash "$old_val")
        local new_dash=$(colon_to_dash "$new_val")
        sed -i '' "s|model: \"${old_dash}\"|model: \"${new_dash}\"|g" "$continue_file"
    else
        # Ollama direct or OpenRouter usually use the raw ID/colon form in quotes
        sed -i '' "s|model: \"${old_val}\"|model: \"${new_val}\"|g" "$continue_file"
    fi

    log_success "  $(basename "$machine_dir")/continue/config.yaml"
}

update_claude_settings() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local claude_file="$machine_dir/claude/settings.json"
    if [[ ! -f "$claude_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/claude/settings.json..."

    if [[ "$mode" == "litellm" ]]; then
        local old_dash=$(colon_to_dash "$old_val")
        local new_dash=$(colon_to_dash "$new_val")
        sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$claude_file"
    else
        sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$claude_file"
    fi

    log_success "  $(basename "$machine_dir")/claude/settings.json"
}

update_opencode_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local opencode_file="$machine_dir/opencode/opencode.jsonc"
    if [[ ! -f "$opencode_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/opencode/opencode.jsonc..."

    # Model list keys + agent values
    sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$opencode_file"

    if [[ "$mode" == "ollama" || "$mode" == "litellm" ]]; then
        sed -i '' "s|ollama/${old_val}|ollama/${new_val}|g" "$opencode_file"
    fi

    log_success "  $(basename "$machine_dir")/opencode/opencode.jsonc"
}

update_grok_config() {
    local machine_dir="$1"
    local old_val="$2"
    local new_val="$3"
    local mode="$4"

    local grok_file="$machine_dir/grok/grok.json"
    if [[ ! -f "$grok_file" ]]; then return; fi

    log_info "Updating $(basename "$machine_dir")/grok/grok.json..."

    if [[ "$mode" == "litellm" ]]; then
        local old_dash=$(colon_to_dash "$old_val")
        local new_dash=$(colon_to_dash "$new_val")
        sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$grok_file"
    else
        sed -i '' "s|\"${old_val}\"|\"${new_val}\"|g" "$grok_file"
    fi

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
    echo "║           helpers.sh — Interactive Configuration                 ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"

    # 1. Select machine
    local mem_class
    mem_class=$(prompt_machine_class) || die "Failed to select a valid machine class."

    if [[ -z "${MACHINE_DIRS[$mem_class]:-}" ]]; then
        die "Selected machine class '$mem_class' is not defined in MACHINE_DIRS."
    fi

    # 2. Select deployment mode
    local deploy_mode
    deploy_mode=$(prompt_deployment_mode)

    # Source the models file
    local models_file="$SETTINGS_BASE/${MACHINE_DIRS[$mem_class]}/models.sh"
    if [[ -f "$models_file" ]]; then
        source "$models_file"
    else
        die "Models file not found: $models_file"
    fi

    echo ""
    log_info "Machine: $mem_class (${MACHINE_DIRS[$mem_class]})"
    log_info "Mode:    $deploy_mode"

    # 3. Select role
    local role
    role=$(prompt_role_menu "$mem_class")
    echo ""
    log_info "Role: $role"

    local -n _cur_agents="OPENCODE_AGENTS"
    local current_model=""

    if [[ "$role" != "all" ]]; then
        local agent_key
        case "$role" in
            coding)   agent_key="code" ;;
            reasoning) agent_key="think" ;;
            research) agent_key="research" ;;
            writing)  agent_key="write" ;;
            planning) agent_key="plan" ;;
        esac
        current_model="${_cur_agents[$agent_key]:-}"
        if [[ -z "$current_model" ]]; then
            die "Could not determine current model for $role on $mem_class"
        fi
    else
        current_model="MULTIPLE"
    fi

    # 4. Prompt for configuration
    echo ""
    if [[ "$role" != "all" ]]; then
        echo "  Current: $current_model"
    else
        echo "  Current: Mixed (Setting all roles to same model)"
    fi
    echo ""

    show_model_suggestions "$deploy_mode"

    local prompt_text="New model alias (Ollama colon form, e.g. qwen3-32b:q6): "
    [[ "$deploy_mode" == "openrouter" ]] && prompt_text="New OpenRouter Model ID (e.g. anthropic/claude-3.5-sonnet): "

    read -r -p "$prompt_text" new_alias
    new_alias="${new_alias// /}"

    if [[ -z "$new_alias" ]]; then
        die "Model alias cannot be empty."
    fi

    local display_new="$new_alias"
    [[ "$deploy_mode" == "litellm" ]] && display_new="$(colon_to_dash "$new_alias")"

    # Confirm
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                       CHANGE SUMMARY                            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    printf "  %-12s %s\n" "Machine:"  "$mem_class (${MACHINE_DIRS[$mem_class]})"
    printf "  %-12s %s\n" "Mode:"     "$deploy_mode"
    printf "  %-12s %s\n" "Role:"     "$role"
    printf "  %-12s %s\n" "Current:" "$current_model"
    printf "  %-12s %s  →  %s\n" "Target:" "$new_alias" "$display_new"
    echo ""
    echo "  Files that will be updated:"
    echo "    scripts/models.sh"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/litellm/litellm.yaml"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/continue/config.yaml"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/claude/settings.json"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/opencode/opencode.jsonc"
    echo "    scripts/${MACHINE_DIRS[$mem_class]}/grok/grok.json"
    if [[ "$role" == "all" || "$role" == "research" ]]; then
        echo "    config/profile.d/_obsidian"
    fi
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
    if [[ "$role" == "all" ]]; then
        local roles=("coding" "reasoning" "research" "writing" "planning")
        local keys=("code"    "think"     "research" "write"   "plan")

        for i in "${!roles[@]}"; do
            local r="${roles[$i]}"
            local k="${keys[$i]}"
            local old="${_cur_agents[$k]:-}"

            log_info "Applying update to role: $r (Old: $old)"
            update_models_sh    "$r" "$mem_class" "$old" "$new_alias" "$deploy_mode"
            update_litellm_yaml "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_continue_config "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_claude_settings "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_opencode_config "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            update_grok_config  "$machine_dir" "$old" "$new_alias" "$deploy_mode"
            if [[ "$r" == "research" ]]; then
                update_obsidian_profile "$mem_class" "$old" "$new_alias"
            fi
        done
    else
        update_models_sh    "$role" "$mem_class" "$current_model" "$new_alias" "$deploy_mode"
        update_litellm_yaml "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_continue_config "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_claude_settings "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_opencode_config "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"
        update_grok_config  "$machine_dir" "$current_model" "$new_alias" "$deploy_mode"

        if [[ "$role" == "research" ]]; then
            update_obsidian_profile "$mem_class" "$current_model" "$new_alias"
        fi
    fi

    echo ""
    log_success "Done. Changes applied to repo — commit when ready."
    echo ""

    # Only offer to pull if using Ollama
    if [[ "$deploy_mode" == "ollama" || "$deploy_mode" == "litellm" ]]; then
        echo ""
        read -r -p "Pull new model via install_coding_assistants? (y/n): " install_choice
        if [[ "$install_choice" == "y" || "$install_choice" == "Y" ]]; then
            source "$SETTINGS_BASE/install-models.sh"
            install_coding_assistants
        fi
    fi

    echo ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
