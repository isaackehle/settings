#!/usr/bin/env bash

. "$(dirname "${BASH_SOURCE[0]}")/models.sh"

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

# Install custom models that require pull + ollama create via Modelfile
# Entries in the array: "base_hf_url|alias_name|modelfile_filename"
# Each unique base_hf_url is pulled once; alias_name is created from the modelfile.
install_custom_models() {
    local profile_name="$1"
    local -n custom_models="$2"
    local MODELFILES_DIR
    MODELFILES_DIR="$(dirname "${BASH_SOURCE[0]}")/../modelfiles"
    local -a pulled_urls=()

    echo "Creating custom model aliases for $profile_name..."
    echo "===================================================="
    echo ""

    for entry in "${custom_models[@]}"; do
        IFS='|' read -r base_url alias_name modelfile <<< "$entry"

        # Pull base weight only once per unique URL
        local already_pulled=0
        for u in "${pulled_urls[@]}"; do
            [[ "$u" == "$base_url" ]] && already_pulled=1 && break
        done

        if (( already_pulled == 0 )); then
            echo "▶ Pulling base: $base_url"
            ollama pull "$base_url"
            pulled_urls+=("$base_url")
            echo ""
        fi

        echo "▶ Creating alias: $alias_name"
        ollama create "$alias_name" -f "$MODELFILES_DIR/$modelfile"
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
    echo "  4) Cancel"
    echo ""
    
    read -p "Enter selection [1-4]: " choice
    
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
            ;;
        4)
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
    echo "📋 16GB MacBook (${#MODELS_16GB[@]} pull)"
    echo ""
    echo "Run install_coding_assistants to select and install"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    list_model_profiles
    install_coding_assistants
fi
