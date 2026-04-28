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

# Pull direct Ollama models for a profile.
# $1 = profile label  $2 = array name (passed by name, bash 3.2 compat)
install-models() {
    local profile_name="$1"
    local arr_name="$2"
    local -a _models
    eval "_models=(\"\${${arr_name}[@]}\")"

    echo "Installing Ollama models for $profile_name configuration..."
    echo "===================================================="
    echo ""

    local -a passed=()
    local -a failed=()
    local model

    for model in "${_models[@]}"; do
        echo "▶ Installing: $model"
        if ollama pull "$model"; then
            passed+=("$model")
        else
            failed+=("$model")
        fi
        echo ""
    done

    echo "===================================================="
    echo "Installation Summary for $profile_name:"
    echo "✅ Passed: ${passed[*]:-none}"
    echo "❌ Failed: ${failed[*]:-none}"
    echo "===================================================="
    echo "✅ Installation process complete for $profile_name"
}

# Install custom models that require pull + ollama create via Modelfile.
#
# Entry format: "source|alias_name|num_ctx"
#   source     — HF URL (hf.co/...), Ollama Hub model, or a previously-created
#                local alias (no pull needed for local aliases)
#   alias_name — the short name to register with Ollama
#   num_ctx    — optional context size override; empty = Ollama model default
#
# Modelfiles are written to a temp file and deleted after each alias is created.
# Entries that derive from a local alias (created earlier in the same array) are
# recognised automatically — no network pull is attempted for them.
# $1 = profile label  $2 = array name (passed by name, bash 3.2 compat)
install_custom_models() {
    local profile_name="$1"
    local arr_name="$2"
    local -a _custom
    eval "_custom=(\"\${${arr_name}[@]}\")"
    local -a pulled_sources=()
    local -a created_aliases=()
    local -a passed=()
    local -a failed=()

    echo "Creating custom model aliases for $profile_name..."
    echo "===================================================="
    echo ""

    local entry source alias_name num_ctx thinking_mode
    for entry in "${_custom[@]}"; do
        IFS='|' read -r source alias_name num_ctx thinking_mode <<< "$entry"

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
                echo "▶ Pulling: $source"
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
    done

    echo "===================================================="
    echo "Custom Alias Summary for $profile_name:"
    echo "✅ Passed: ${passed[*]:-none}"
    echo "❌ Failed: ${failed[*]:-none}"
    echo "===================================================="
    echo "✅ Custom aliases complete for $profile_name"
    echo ""
}

# ==============================================
# PRUNE FUNCTION
# ==============================================

# Remove Ollama models that are installed but not part of the given profile.
# Takes the same direct-models array and custom-models array that install uses,
# so it knows exactly what "should" be present.
#
# Usage: prune_models "M5 Max 64GB" MODELS_M5_64GB CUSTOM_MODELS_64GB
# $1 = profile label  $2 = direct array name  $3 = custom array name (bash 3.2 compat)
prune_models() {
    local profile_name="$1"
    local direct_name="$2"
    local custom_name="$3"
    local -a _direct _custom
    eval "_direct=(\"\${${direct_name}[@]}\")"
    eval "_custom=(\"\${${custom_name}[@]}\")"

    # Build the full set of expected model names for this profile
    local -a expected=()
    local m entry _src alias_name _ctx
    for m in "${_direct[@]}"; do
        expected+=("$m")
        expected+=("${m}:latest")  # Ollama appends :latest to untagged names
    done
    for entry in "${_custom[@]}"; do
        IFS='|' read -r _src alias_name _ctx <<< "$entry"
        # Keep both the source (HF pull / community model) and the created alias
        expected+=("$_src")
        expected+=("${_src}:latest")
        expected+=("$alias_name")
        expected+=("${alias_name}:latest")
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
            install-models "$profile_name" MODELS
            install_custom_models "$profile_name" CUSTOM_MODELS
            ;;
        2)
            print_step "Pruning orphan models for $profile_name"
            prune_models "$profile_name" MODELS CUSTOM_MODELS
            ;;
        3)
            print_step "Installing models for $profile_name"
            install-models "$profile_name" MODELS
            install_custom_models "$profile_name" CUSTOM_MODELS
            echo ""
            print_step "Pruning orphan models for $profile_name"
            prune_models "$profile_name" MODELS CUSTOM_MODELS
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
