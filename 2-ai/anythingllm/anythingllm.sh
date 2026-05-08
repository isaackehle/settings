if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_anythingllm() {
    if [ -d "/Applications/AnythingLLM.app" ]; then
        log_status "AnythingLLM.app found"
        return 0
    fi
    log_warning "AnythingLLM not found in /Applications"
    return 1
}

_install_anythingllm() {
    if command_exists "brew"; then
        log_info "Installing AnythingLLM via Homebrew Cask..."
        brew install --cask anythingllm && return 0
    fi
    log_warning "Homebrew not available — download from https://anythingllm.com/download"
    return 1
}

setup_anythingllm() {
    log_info "Setting up AnythingLLM..."
    verify_anythingllm || _install_anythingllm || log_warning "AnythingLLM not installed — skipping"

    log_info ""
    log_info "=== AnythingLLM ==="
    log_info "Start:        Open AnythingLLM from Applications"
    log_info "LLM backend:  Settings → LLM Provider → Ollama → http://localhost:11434"
    log_info "Embedder:     Settings → Embedding Provider → Ollama"
    log_info "Vector DB:    Settings → Vector Database → LanceDB (built-in, no setup)"
    log_info "Docs:         https://docs.anythingllm.com/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_anythingllm
fi
