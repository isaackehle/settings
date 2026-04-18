. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_ollama() {

    if ! command_exists "brew"; then
        print_error "Homebrew is required to install ollama. Install Homebrew first"
        return 1
    fi

    print_info "Installing ollama..."
    brew install ollama
}

verify_ollama() {
    check_tool_with_version "Ollama" "ollama --version"
}

# Runtime setup: start Ollama server and pull base model
setup_ollama() {
    print_info "Setting up Ollama..."

    verify_ollama || _install_ollama || { print_error "Failed to install ollama"; return 1; }

    print_info "Starting Ollama server..."
    brew services start ollama

    print_info "Pulling llama3 model..."
    ollama pull llama3

    print_info "Verifying Ollama installation..."
    ollama --version

    print_status "Ollama setup completed successfully"
}

setup_ollama_models() {
    # name|content (newlines in content encoded as \n)
    local -a models=(
        "qwen3-4b-UD-Q4_K_M|FROM hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M"
        "qwen3-4b-UD-Q8_K_XL|FROM hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL"
        "qwen3-coder-30b-220k-UD-Q5_K_XL|FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL\nPARAMETER num_ctx 220000"
        "qwen3-coder-30b-220k-UD-Q6_K_XL|FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL\nPARAMETER num_ctx 220000"
        "qwen3-coder-30b-32k-UD-Q5_K_XL|FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL\nPARAMETER num_ctx 32768"
        "qwen3-coder-30b-32k-UD-Q6_K_XL|FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL\nPARAMETER num_ctx 32768"
    )

    local tmp_modelfile
    tmp_modelfile="$(mktemp /tmp/Modelfile.XXXXXX)"

    for entry in "${models[@]}"; do
        local name content
        name="${entry%%|*}"
        content="${entry#*|}"

        printf '%b\n' "$content" > "$tmp_modelfile"
        print_info "Creating Ollama model: $name"
        if ollama create "$name" -f "$tmp_modelfile"; then
            print_status "Created model: $name"
        else
            print_warning "Failed to create model: $name"
        fi
    done

    rm -f "$tmp_modelfile"
    print_status "Ollama model setup complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ollama
fi




