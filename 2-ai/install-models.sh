#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"
. "${SETTINGS_BASE}/2-ai/exo.sh"

# ==============================================
# PROFILE CONFIGURATION
# ==============================================

load_profile_models() {
    local profile="$1"
    local profile_file="${SETTINGS_BASE}/2-ai/profiles/${profile}/models.sh"
    if [[ -f "$profile_file" ]]; then
        . "$profile_file"
        return 0
    fi
    return 1
}

# ==============================================
# CONTEXT WINDOW VARIANTS
# Reads MODEL_CONTEXTS from the sourced models.sh and creates
# aliases via ollama create with PARAMETER num_ctx.
# Share underlying weights — zero additional disk space.
# ==============================================

create_context_variants() {
    if ! declare -p MODEL_CONTEXTS &>/dev/null; then
        echo "No MODEL_CONTEXTS defined — skipping context variants."
        return 0
    fi

    echo "Creating context window variants..."
    echo "===================================="
    echo ""

    local created=0 skipped=0
    for base_model in "${!MODEL_CONTEXTS[@]}"; do
        # Check that the base model is actually installed
        if ! ollama list 2>/dev/null | grep -q "^${base_model%%:*}"; then
            echo "⚠ Base model not installed yet: $base_model — skipping context variants"
            continue
        fi

        local contexts="${MODEL_CONTEXTS[$base_model]}"
        for ctx in $contexts; do
            local alias="${base_model}-${ctx}"
            if ollama list 2>/dev/null | grep -q "^${alias}"; then
                echo "✅ Already exists: $alias"
                ((skipped++))
                continue
            fi

            # Parse num_ctx from suffix (e.g., "128k" → 131072, "32k" → 32768, "40k" → 40960)
            local num_ctx
            if [[ "$ctx" == *"k" ]]; then
                num_ctx=$((${ctx%k} * 1024))
            else
                num_ctx=$ctx
            fi

            echo "▶ Creating $alias (context=$num_ctx)"
            local tmp_mf
            tmp_mf=$(mktemp /tmp/ollama_ctx_XXXXXX)
            printf 'FROM %s\nPARAMETER num_ctx %s\n' "$base_model" "$num_ctx" > "$tmp_mf"
            if ollama create "$alias" -f "$tmp_mf" 2>/dev/null; then
                ((created++))
            else
                echo "⚠ Failed to create $alias"
            fi
            rm -f "$tmp_mf"
        done
    done

    echo ""
    echo "Context variants: $created created, $skipped already present"
    echo ""
}

# ==============================================
# MODEL INSTALLATION
# Pulls Ollama models. Entry format: plain Ollama name (e.g., "qwen3:14b").
# Skips :cloud entries (documentation only).
# ==============================================

install_ollama_models() {
    local profile_name="$1"
    local arr_name="$2"
    local -a _models
    eval "_models=(\"\${${arr_name}[@]}\")"

    echo "Installing Ollama models for $profile_name configuration..."
    echo "===================================================="
    echo ""

    local -a passed=()
    local -a failed=()
    local -a skipped_cloud=()
    local entry

    for entry in "${_models[@]}"; do
        # Skip cloud entries (documentation only)
        if [[ "$entry" == *":cloud" ]]; then
            skipped_cloud+=("${entry%:cloud}")
            continue
        fi

        # Skip if already installed
        if ollama list "$entry" 2>/dev/null | grep -q "$entry"; then
            echo "✅ Already installed: $entry"
            passed+=("$entry")
            echo ""
            continue
        fi

        echo "▶ Installing: $entry"
        if ollama pull "$entry"; then
            passed+=("$entry")
        else
            failed+=("$entry")
        fi
        echo ""
    done

    # Summary
    echo "===================================================="
    echo "Installation Summary for $profile_name:"
    echo "✅ Installed:"
    [[ ${#passed[@]} -eq 0 ]] && echo "  none" || printf '  - %s\n' "${passed[@]}"
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "❌ Failed:"
        printf '  - %s\n' "${failed[@]}"
    fi
    if [[ ${#skipped_cloud[@]} -gt 0 ]]; then
        echo "☁ Skipped cloud models:"
        printf '  - %s\n' "${skipped_cloud[@]}"
    fi
    echo "===================================================="
    echo ""

    # Offer to pull alternative quants
    if declare -p MODEL_QUANTS &>/dev/null && [[ ${#MODEL_QUANTS[@]} -gt 0 ]]; then
        echo "Alternative (higher-quality) quants available:"
        local q_index=1
        local -a q_names=()
        for model_name in "${!MODEL_QUANTS[@]}"; do
            local info="${MODEL_QUANTS[$model_name]}"
            local quant="${info%%:*}"
            local desc="${info#*:}"
            q_names+=("$model_name:$quant")
            echo "  $q_index) $model_name:$quant — $desc"
            ((q_index++))
        done
        if [[ ${#q_names[@]} -gt 0 ]]; then
            read -p "Pull any? Enter numbers (space-separated) or Enter to skip: " quant_choices
            if [[ -n "$quant_choices" ]]; then
                echo ""
                for choice in $quant_choices; do
                    local q_model="${q_names[$((choice-1))]}"
                    if [[ -n "$q_model" ]]; then
                        echo "▶ Pulling alternative quant: $q_model"
                        ollama pull "$q_model" && echo "✅ $q_model pulled" || echo "⚠ Failed to pull $q_model"
                        echo ""
                    fi
                done
            fi
        fi
    fi

    echo "✅ Installation process complete for $profile_name"
}

# ==============================================
# MAIN INSTALLER MENU
# ==============================================

install_coding_assistants() {
    print_step "Detecting hardware profile"
    local detected="${MACHINE_PROFILE}"

    echo ""
    echo "Ollama Model Installer"
    echo "======================"
    echo ""
    print_profile_menu "$detected"
    echo ""

    local num_profiles
    num_profiles=$(ls -d "${SETTINGS_BASE}/2-ai/profiles"/*/ 2>/dev/null | wc -l | tr -d ' ')
    local total_options=$((num_profiles + 2))

    read -p "Enter selection [1-$total_options] (Enter = $detected): " choice
    choice="${choice:-$detected}"

    print_step "Resolving profile for choice: $choice"

    local exo_choice=$((num_profiles + 1))
    local cancel_choice=$((num_profiles + 2))

    if [[ "$choice" == "$exo_choice" ]]; then
        print_step "Launching exo setup"
        setup_exo
        return
    fi

    if [[ "$choice" == "$cancel_choice" || "$choice" == "cancel" ]]; then
        echo "Installation cancelled."
        return
    fi

    local profile
    profile=$(get_profile_for_choice "$choice") || {
        echo "Invalid selection: '$choice'"
        return 1
    }
    print_step "Profile resolved: $profile"

    print_step "Loading model list for profile: $profile"
    load_profile_models "$profile" || {
        echo "Error: Could not load models for profile $profile"
        return 1
    }

    local profile_name="$(_profile_name "$profile")"

    echo ""
    echo "What would you like to do?"
    echo "  1) Install / update models   — pull missing, create context variants"
    echo "  2) Prune orphan models       — remove models not in the $profile_name stack"
    echo "  3) Both                      — install then prune"
    echo ""
    read -p "Enter action [1-3] (Enter = 1): " action
    action="${action:-1}"

    case $action in
        1)
            print_step "Installing models for $profile_name"
            install_ollama_models "$profile_name" OLLAMA_MODELS
            create_context_variants
            ;;
        2)
            print_step "Pruning orphan models for $profile_name"
            bash "${SETTINGS_BASE}/2-ai/profiles/prune_models.sh" "$profile"
            ;;
        3)
            print_step "Installing models for $profile_name"
            install_ollama_models "$profile_name" OLLAMA_MODELS
            create_context_variants
            echo ""
            print_step "Pruning orphan models for $profile_name"
            bash "${SETTINGS_BASE}/2-ai/profiles/prune_models.sh" "$profile"
            ;;
        *)
            echo "Invalid action."
            return 1
            ;;
    esac
}

# ==============================================
# INFO
# ==============================================

list_model_profiles() {
    echo "Available hardware profiles:"
    echo ""

    local i=1
    local folder
    while IFS= read -r folder; do
        echo "📋 $(_profile_label "$folder") — $(_profile_description "$folder")"
        i=$((i + 1))
    done < <(_get_profile_folders)

    echo "📋 exo — distributed inference across multiple Apple Silicon Macs"
    echo ""
    echo "Run install_coding_assistants to select and install"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_model_profiles
    install_coding_assistants
fi
