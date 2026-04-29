if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Install LM Studio — desktop app for running local models with a GUI.

_install_lmstudio() {
    if command_exists "brew"; then
        log_info "Installing LM Studio via Homebrew..."
        brew install --cask lm-studio && return 0
    fi
    log_warning "Homebrew not available — download from https://lmstudio.ai"
    return 1
}

verify_lmstudio() {
    if [ -d "/Applications/LM Studio.app" ]; then
        log_status "LM Studio.app found"
        return 0
    fi
    log_warning "LM Studio not found in /Applications"
    return 1
}

setup_lmstudio() {
    log_info "Setting up LM Studio..."
    verify_lmstudio || _install_lmstudio || log_warning "LM Studio not installed — skipping"

    log_info ""
    log_info "=== LM Studio ==="
    log_info "Launch:      open '/Applications/LM Studio.app'"
    log_info "CLI:         lms (install via LM Studio → Settings → Install CLI tool)"
    log_info "API server:  lms server start  →  http://localhost:1234/v1"
    log_info "Models:      ~/Library/Application Support/LM Studio/models/"
    log_info "Docs:        https://lmstudio.ai/docs"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_lmstudio
fi
