. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install AnythingLLM and print Ollama configuration instructions.
# Models are served by Ollama — no separate downloads needed.

_install_anythingllm() {
    if command_exists brew; then
        print_info "Installing AnythingLLM via Homebrew Cask..."
        brew install --cask anythingllm && return 0
    fi
    print_warning "Homebrew not found. Download AnythingLLM manually from https://anythingllm.com/download"
    return 1
}

verify_anythingllm() {
    if [ -d "/Applications/AnythingLLM.app" ]; then
        print_status "AnythingLLM is installed"
        return 0
    fi
    print_warning "AnythingLLM not found"
    return 1
}

setup_anythingllm() {
    print_info "Setting up AnythingLLM..."
    verify_anythingllm || _install_anythingllm || { print_error "Failed to install AnythingLLM"; return 1; }

    print_info ""
    print_info "=== AnythingLLM — Ollama configuration ==="
    print_info "AnythingLLM uses Ollama as the model provider (no separate model downloads)."
    print_info ""
    print_info "1. Open AnythingLLM → Settings → LLM Preference"
    print_info "   Provider:  Ollama"
    print_info "   Base URL:  http://127.0.0.1:11434"
    print_info "   Model:     pick from the dropdown (mirrors 'ollama list')"
    print_info ""
    print_info "2. Settings → Embedding Preference"
    print_info "   Provider:  Ollama"
    print_info "   Base URL:  http://127.0.0.1:11434"
    print_info "   Model:     nomic-embed-text  (pull if missing: ollama pull nomic-embed-text)"
    print_info ""
    print_info "Ensure Ollama is running before launching AnythingLLM:"
    print_info "  brew services start ollama"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_anythingllm
fi
