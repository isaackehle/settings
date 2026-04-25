. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_ollama() {
    if ! command_exists "brew"; then
        print_error "Homebrew is required to install Ollama. Install Homebrew first."
        return 1
    fi
    print_info "Installing Ollama..."
    brew install ollama
}

verify_ollama() {
    check_tool_with_version "Ollama" "ollama"
}

# Install Ollama and start the server. Model installation is handled
# separately by install_coding_assistants in install-models.sh.
setup_ollama() {
    print_info "Setting up Ollama..."

    verify_ollama || _install_ollama || { print_error "Failed to install Ollama"; return 1; }

    print_info "Starting Ollama server..."
    brew services start ollama

    print_info "Verifying Ollama installation..."
    ollama --version

    print_status "Ollama setup complete. Run 'bash scripts/install-models.sh' to install models."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ollama
fi
