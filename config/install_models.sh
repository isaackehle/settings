#!/usr/bin/env bash

. "$(dirname "${BASH_SOURCE[0]}")/models.sh"
. "$(dirname "${BASH_SOURCE[0]}")/exo/setup_exo.sh"

# Ollama Model Management Library
# This library provides functions to manage Ollama models by purpose

# ==============================================
# INSTALL FUNCTIONS
# ==============================================

# Function to install models for a specific hardware profile
install_models() {
    local profile_name="$1"
    local -n models="$2"
    
    echo "Installing Ollama models for $profile_name configuration..."
    echo "===================================================="
    echo ""
    
    for model in "${models[@]}"; do
        echo "▶ Installing: $model"
        ollama pull "$model"
        echo ""
    done
    
    echo "✅ Installation complete for $profile_name"
}

# Install custom models that require pull + ollama create via Modelfile.
#
# Entry format: "source|alias_name|num_ctx"
#   source    — HF URL (hf.co/...), Ollama Hub model, or a previously-created
#               local alias (no pull needed for local aliases)
#   alias_name — the short name to register with Ollama
#   num_ctx    — optional context size override; empty = Ollama model default
#
# Modelfiles are written to a temp file and deleted after each alias is created.
# Entries that derive from a local alias (created earlier in the same array) are
# recognised automatically — no network pull is attempted for them.
install_custom_models() {
    local profile_name="$1"
    local -n custom_models="$2"
    local -a pulled_sources=()
    local -a created_aliases=()

    echo "Creating custom model aliases for $profile_name..."
    echo "===================================================="
    echo ""

    for entry in "${custom_models[@]}"; do
        IFS='|' read -r source alias_name num_ctx <<< "$entry"

        # Determine if source is a local alias we already created this run
        local is_local=0
        for a in "${created_aliases[@]}"; do
            [[ "$a" == "$source" ]] && is_local=1 && break
        done

        # Pull remote source once (skip if local alias or already pulled)
        if (( !is_local )); then
            local already_pulled=0
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

        echo "▶ Creating alias: $alias_name"
        ollama create "$alias_name" -f "$tmp_mf"
        rm -f "$tmp_mf"
        created_aliases+=("$alias_name")
        echo ""
    done

    echo "✅ Custom aliases complete for $profile_name"
    echo ""
}

# Main install function with hardware selection
install_coding_assistants() {
    echo ""
    echo "Ollama Model Installer"
    echo "======================"
    echo ""
    echo "Select your hardware configuration:"
    echo ""
    echo "  1) M5 Max 48GB (Standard stack)"
    echo "  2) M5 Max 64GB (Extended stack with extra models)"
    echo "  3) M1/M2/M3 16GB (Optimized for smaller memory)"
    echo "  4) exo (Distributed inference across multiple Apple Silicon Macs)"
    echo "  5) Cancel"
    echo ""

    read -p "Enter selection [1-5]: " choice

    case $choice in
        1)
            install_models "M5 Max 48GB" MODELS_M5_48GB
            install_custom_models "M5 Max 48GB" CUSTOM_MODELS_48GB
            ;;
        2)
            install_models "M5 Max 64GB" MODELS_M5_64GB
            install_custom_models "M5 Max 64GB" CUSTOM_MODELS_64GB
            ;;
        3)
            install_models "16GB MacBook" MODELS_16GB
            install_custom_models "16GB MacBook" CUSTOM_MODELS_16GB
            ;;
        4)
            setup_exo
            ;;
        5)
            echo "Installation cancelled."
            exit 0
            ;;
        *)
            echo "Invalid selection. Please run again."
            exit 1
            ;;
    esac
}

# Function to list all model profiles
list_model_profiles() {
    echo "Available hardware profiles:"
    echo ""
    echo "📋 M5 Max 48GB (${#MODELS_M5_48GB[@]} pull + ${#CUSTOM_MODELS_48GB[@]} custom aliases)"
    echo "📋 M5 Max 64GB (${#MODELS_M5_64GB[@]} pull + ${#CUSTOM_MODELS_64GB[@]} custom aliases)"
    echo "📋 16GB MacBook (${#MODELS_16GB[@]} pull + ${#CUSTOM_MODELS_16GB[@]} custom aliases)"
    echo "📋 exo — distributed inference across multiple Apple Silicon Macs"
    echo ""
    echo "Run install_coding_assistants to select and install"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_model_profiles
    install_coding_assistants
fi
