. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install LM Studio — desktop app for running local models with a GUI.

_install_lmstudio() {
    if command_exists "brew"; then
        print_info "Installing LM Studio via Homebrew..."
        brew install --cask lm-studio && return 0
    fi
    print_warning "Homebrew not available — download from https://lmstudio.ai"
    return 1
}

verify_lmstudio() {
    if [ -d "/Applications/LM Studio.app" ]; then
        print_status "LM Studio.app found"
        return 0
    fi
    print_warning "LM Studio not found in /Applications"
    return 1
}

setup_lmstudio() {
    print_info "Setting up LM Studio..."
    verify_lmstudio || _install_lmstudio || print_warning "LM Studio not installed — skipping"

    print_info ""
    print_info "=== LM Studio ==="
    print_info "Launch:      open '/Applications/LM Studio.app'"
    print_info "CLI:         lms (install via LM Studio → Settings → Install CLI tool)"
    print_info "API server:  lms server start  →  http://localhost:1234/v1"
    print_info "Models:      ~/Library/Application Support/LM Studio/models/"
    print_info "Docs:        https://lmstudio.ai/docs"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_lmstudio
fi
