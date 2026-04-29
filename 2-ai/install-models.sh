#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"
. "${SETTINGS_BASE}/2-ai/exo/setup_exo.sh"

# Ollama Model Management Library
# This library provides functions to manage Ollama models by purpose
# Model configurations are loaded dynamically from profile folders

# ==============================================
# PROFILE CONFIGURATION
# ==============================================

# Load model configuration for a specific profile folder
# $1 = profile folder name (e.g., macbook-m5-64gb)
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
# INSTALL FUNCTIONS
# ==============================================

# Pulls Ollama models and creates custom aliases for a profile.
#
# Entry formats:
#   "model"                       -> Direct pull
#   "source|alias"                -> Pull source, create alias
#   "source|alias|num_ctx"         -> Pull source, create alias with context override
#
# $1 = profile label  $2 = array name (passed by name, bash 3.2 compat)
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
    local -a pulled_sources=()
    local -a created_aliases=()
    local entry

    for entry in "${_models[@]}"; do
        # Skip cloud models
        if [[ "$entry" == *":cloud" ]]; then
            echo "☁ Skipping cloud model: $entry"
            continue
        fi

        if [[ "$entry" == *"|"* ]]; then
            # --- Custom Model / Alias Logic ---
            IFS='|' read -r source alias_name num_ctx <<< "$entry"

            # Determine if source is a local alias we already created this run
            local is_local=0
            local a
            for a in "${created_aliases[@]}"; do
                [[ "$a" == "$source" ]] && is_local=1 && break
            done

            # Pull remote source once (skip if local alias or already pulled)
            local pull_success=1
            if (( !is_local )); then
                local already_pulled=0
                local s
                for s in "${pulled_sources[@]}"; do
                    [[ "$s" == "$source" ]] && already_pulled=1 && break
                done
                if (( !already_pulled )); then
                    echo "▶ Pulling source: $source"
                    if ollama pull "$source"; then
                        pulled_sources+=("$source")
                        pull_success=0
                    else
                        pull_success=1
                    fi
                    echo ""
                else
                    pull_success=0
                fi
            else
                pull_success=0
            fi

            # Write temp Modelfile, create alias, clean up
            local create_success=1
            if (( pull_success == 0 )); then
                local tmp_mf
                tmp_mf=$(mktemp /tmp/ollama_modelfile_XXXXXX)
                printf 'FROM %s\n' "$source" > "$tmp_mf"
                [[ -n "$num_ctx" ]] && printf 'PARAMETER num_ctx %s\n' "$num_ctx" >> "$tmp_mf"

                echo "▶ Creating alias: $alias_name"
                if ollama create "$alias_name" -f "$tmp_mf"; then
                    create_success=0
                fi
                rm -f "$tmp_mf"
            else
                echo "⚠ Skipping alias creation for $alias_name due to pull failure of $source"
            fi

            if (( create_success == 0 )); then
                passed+=("$alias_name")
                created_aliases+=("$alias_name")
            else
                failed+=("$alias_name")
            fi
            echo ""
        else
            # --- Direct Model Logic ---
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
        fi
    done

    echo "===================================================="
    echo "Installation Summary for $profile_name:"
    echo "✅ Passed:"
    [[ ${#passed[@]} -eq 0 ]] && echo "  none" || printf '  - %s\n' "${passed[@]}"
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo "❌ Failed:"
        printf '  - %s\n' "${failed[@]}"
    fi
    echo "===================================================="
    echo "✅ Installation process complete for $profile_name"
}

# ==============================================
# PRUNE FUNCTION
# ==============================================

# Remove Ollama models that are installed but not part of the given profile.
#
# Usage: prune_models "M5 Max 64GB" OLLAMA_MODELS
# $1 = profile label  $2 = model array name (bash 3.2 compat)
prune_models() {
    local profile_name="$1"
    local arr_name="$2"
    local -a _models
    eval "_models=(\"\${${arr_name}[@]}\")"

    # Build the full set of expected model names for this profile
    local -a expected=()
    local entry _src alias_name _ctx
    for entry in "${_models[@]}"; do
        # Skip cloud models from expected list
        [[ "$entry" == *":cloud" ]] && continue

        if [[ "$entry" == *"|"* ]]; then
            IFS='|' read -r _src alias_name _ctx <<< "$entry"
            # Keep both the source (HF pull / community model) and the created alias
            expected+=("$_src")
            expected+=("${_src}:latest")
            expected+=("$alias_name")
            expected+=("${alias_name}:latest")
        else
            expected+=("$entry")
            expected+=("${entry}:latest")  # Ollama appends :latest to untagged names
        fi
    done

    # Get currently installed models (name column only, skip header)
    if ! command -v ollama &>/dev/null; then
        echo "⚠ ollama not found — skipping prune"
        return
    fi

    local installed_raw
    installed_raw=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')

    if [[ -z "$installed_raw" ]]; then
        echo "No models currently installed."
        return
    fi

    # Find orphans: installed but not in expected set
    local -a orphans=()
    while IFS= read -r model; do
        [[ -z "$model" ]] && continue
        local found=0
        for e in "${expected[@]}"; do
            [[ "$model" == "$e" ]] && found=1 && break
        done
        (( !found )) && orphans+=("$model")
    done <<< "$installed_raw"

    if [[ ${#orphans[@]} -eq 0 ]]; then
        echo "✅ No orphan models — everything installed matches the $profile_name profile."
        return
    fi

    echo ""
    echo "The following models are installed but not in the $profile_name stack:"
    for m in "${orphans[@]}"; do
        echo "  - $m"
    done
    echo ""
    read -p "Remove all orphans? (y/N) " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for m in "${orphans[@]}"; do
            echo "▶ Removing: $m"
            ollama rm "$m"
        done
        echo "✅ Orphan models removed."
    else
        echo "ℹ Skipped. Run 'ollama rm <model>' manually to remove individual models."
    fi
}

# ==============================================
# MAIN INSTALLER MENU
# ==============================================

install_coding_assistants() {
    print_step "Detecting hardware profile"
    local detected
    detected=$(_detect_profile)

    echo ""
    echo "Ollama Model Installer"
    echo "======================"
    echo ""
    print_profile_menu "$detected"
    echo ""

    # Calculate total options for the prompt: profiles + exo + cancel
    local num_profiles
    num_profiles=$(ls -d "${SETTINGS_BASE}/2-ai/profiles"/*/ 2>/dev/null | wc -l | tr -d ' ')
    local total_options=$((num_profiles + 2))

    read -p "Enter selection [1-$total_options] (Enter = $detected): " choice
    choice="${choice:-$detected}"

    print_step "Resolving profile for choice: $choice"

    # Handle exo option
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

    # Get profile folder from choice
    local profile
    profile=$(get_profile_for_choice "$choice") || {
        echo "Invalid selection: '$choice'"
        return 1
    }
    print_step "Profile resolved: $profile"

    # Load the profile's models
    print_step "Loading model list for profile: $profile"
    load_profile_models "$profile" || {
        echo "Error: Could not load models for profile $profile"
        return 1
    }

    local profile_name="$(_profile_name "$profile")"

    echo ""
    echo "What would you like to do?"
    echo "  1) Install / update models   — pull missing, re-create aliases"
    echo "  2) Prune orphan models       — remove models not in the $profile_name stack"
    echo "  3) Both                      — install then prune"
    echo ""
    read -p "Enter action [1-3] (Enter = 1): " action
    action="${action:-1}"

    case $action in
        1)
            print_step "Installing models for $profile_name"
            install_ollama_models "$profile_name" OLLAMA_MODELS
            ;;
        2)
            print_step "Pruning orphan models for $profile_name"
            prune_models "$profile_name" OLLAMA_MODELS
            ;;
        3)
            print_step "Installing models for $profile_name"
            install_ollama_models "$profile_name" OLLAMA_MODELS
            echo ""
            print_step "Pruning orphan models for $profile_name"
            prune_models "$profile_name" OLLAMA_MODELS
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
