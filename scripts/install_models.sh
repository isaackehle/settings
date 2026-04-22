#!/opt/homebrew/bin/bash

. "$(dirname "${BASH_SOURCE[0]}")/models.sh"
. "$(dirname "${BASH_SOURCE[0]}")/exo/setup_exo.sh"

# Ollama Model Management Library
# This library provides functions to manage Ollama models by purpose

# ==============================================
# HARDWARE DETECTION
# ==============================================

# Returns 1 (48GB), 2 (64GB), 3 (32GB), or 4 (16GB) based on unified memory.
_detect_profile() {
    local hw_mem_gb
    hw_mem_gb=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1024 / 1024 / 1024 ))
    if   [[ "$hw_mem_gb" -ge 56 ]]; then echo "2"   # M5 Max 64GB
    elif [[ "$hw_mem_gb" -ge 40 ]]; then echo "1"   # M5 Max 48GB
    elif [[ "$hw_mem_gb" -ge 24 ]]; then echo "3"   # M2/M3/M4 32GB
    else                                 echo "4"   # 16GB
    fi
}

_profile_label() {
    case "$1" in
        1) echo "M5 Max 48GB" ;;
        2) echo "M5 Max 64GB" ;;
        3) echo "M2/M3/M4 32GB" ;;
        4) echo "16GB MacBook/Mini" ;;
        *) echo "Unknown" ;;
    esac
}

# ==============================================
# INSTALL FUNCTIONS
# ==============================================

# Pull direct Ollama models for a profile.
# $1 = profile label  $2 = array name (passed by name, bash 3.2 compat)
install_models() {
    local profile_name="$1"
    local arr_name="$2"
    local -a _models
    eval "_models=(\"\${${arr_name}[@]}\")"

    echo "Installing Ollama models for $profile_name configuration..."
    echo "===================================================="
    echo ""

    local model
    for model in "${_models[@]}"; do
        echo "▶ Installing: $model"
        ollama pull "$model"
        echo ""
    done

    echo "✅ Installation complete for $profile_name"
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
        if (( !is_local )); then
            local already_pulled=0
            local s
            for s in "${pulled_sources[@]}"; do
                [[ "$s" == "$source" ]] && already_pulled=1 && break
            done
            if (( !already_pulled )); then
                echo "▶ Pulling: $source"
                ollama pull "$source"
                pulled_sources+=("$source")
                echo ""
            fi
        fi

        # Write temp Modelfile, create alias, clean up
        local tmp_mf
        tmp_mf=$(mktemp /tmp/ollama_modelfile_XXXXXX)
        printf 'FROM %s\n' "$source" > "$tmp_mf"
        [[ -n "$num_ctx" ]] && printf 'PARAMETER num_ctx %s\n' "$num_ctx" >> "$tmp_mf"
        # [[ -n "$thinking_mode" ]] && printf 'PARAMETER thinking %s\n' "$thinking_mode" >> "$tmp_mf"

        echo "▶ Creating alias: $alias_name"
        ollama create "$alias_name" -f "$tmp_mf"
        rm -f "$tmp_mf"
        created_aliases+=("$alias_name")
        echo ""
    done

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
    local detected
    detected=$(_detect_profile)
    local detected_label
    detected_label=$(_profile_label "$detected")

    echo ""
    echo "Ollama Model Installer"
    echo "======================"
    echo ""
    echo "  Detected hardware: $detected_label (auto-selected as [$detected])"
    echo ""
    echo "  1) M5 Max 48GB   — Q5 stack + 30B coder + 8B reasoning"
    echo "  2) M5 Max 64GB   — Q6 stack + 30B coder + 32B reasoning + 70B solo"
    echo "  3) M2/M3/M4 32GB — Q5 stack + 30B coder + 32B reasoning"
    echo "  4) M1/M2/M3 16GB — Q4 lightweight stack"
    echo "  5) exo            — distributed inference across Apple Silicon Macs"
    echo "  6) Cancel"
    echo ""
    read -p "Enter selection [1-6] (Enter = $detected): " choice
    choice="${choice:-$detected}"

    local profile_name direct_arr custom_arr
    case $choice in
        1) profile_name="M5 Max 48GB";    direct_arr=MODELS_M5_48GB; custom_arr=CUSTOM_MODELS_48GB ;;
        2) profile_name="M5 Max 64GB";    direct_arr=MODELS_M5_64GB; custom_arr=CUSTOM_MODELS_64GB ;;
        3) profile_name="M2/M3/M4 32GB";  direct_arr=MODELS_32GB;    custom_arr=CUSTOM_MODELS_32GB ;;
        4) profile_name="M1/M2/M3 16GB";  direct_arr=MODELS_16GB;    custom_arr=CUSTOM_MODELS_16GB ;;
        5) setup_exo; return ;;
        6) echo "Installation cancelled."; return ;;
        *) echo "Invalid selection."; return 1 ;;
    esac

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
            install_models "$profile_name" "$direct_arr"
            install_custom_models "$profile_name" "$custom_arr"
            ;;
        2)
            prune_models "$profile_name" "$direct_arr" "$custom_arr"
            ;;
        3)
            install_models "$profile_name" "$direct_arr"
            install_custom_models "$profile_name" "$custom_arr"
            echo ""
            prune_models "$profile_name" "$direct_arr" "$custom_arr"
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
    echo "📋 M5 Max 48GB (${#MODELS_M5_48GB[@]} pull + ${#CUSTOM_MODELS_48GB[@]} custom aliases)"
    echo "📋 M5 Max 64GB (${#MODELS_M5_64GB[@]} pull + ${#CUSTOM_MODELS_64GB[@]} custom aliases)"
    echo "📋 M2/M3/M4 32GB (${#MODELS_32GB[@]} pull + ${#CUSTOM_MODELS_32GB[@]} custom aliases)"
    echo "📋 M1/M2/M3 16GB (${#MODELS_16GB[@]} pull + ${#CUSTOM_MODELS_16GB[@]} custom aliases)"
    echo "📋 exo — distributed inference across multiple Apple Silicon Macs"
    echo ""
    echo "Run install_coding_assistants to select and install"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_model_profiles
    install_coding_assistants
fi
