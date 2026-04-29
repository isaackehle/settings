if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_ollama() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Ollama. Install Homebrew first."
        return 1
    fi
    log_info "Installing Ollama..."
    brew install ollama
}

verify_ollama() {
    check_tool_with_version "Ollama" "ollama"
}

# Install Ollama and start the server. Model installation is handled
# separately by install_coding_assistants in install-models.sh.
setup_ollama() {
    log_info "Setting up Ollama..."

    verify_ollama || _install_ollama || { log_error "Failed to install Ollama"; return 1; }

    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        log_info "Ollama server is already running."
    else
        log_info "Starting Ollama server..."
        # Try start, if it fails (e.g. Error 5), try restart
        if ! brew services start ollama; then
            log_warning "brew services start failed, attempting restart..."
            brew services restart ollama
        fi
    fi

    log_info "Verifying Ollama installation..."
    ollama --version

    log_success "Ollama setup complete. Run 'bash docs/02 - AI/install-models.sh' to install models."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ollama
fi