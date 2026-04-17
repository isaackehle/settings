. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ollama
fi




