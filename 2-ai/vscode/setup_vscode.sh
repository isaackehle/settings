#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_vscode() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install VS Code. Install Homebrew first."
        return 1
    fi
    log_info "Installing Visual Studio Code..."
    brew install --cask visual-studio-code
}

verify_vscode() {
    if command -v code > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

setup_vscode() {
    log_info "Setting up Visual Studio Code..."

    verify_vscode || _install_vscode || { log_error "Failed to install VS Code"; return 1; }

    log_info "Verifying VS Code installation..."
    code --version

    log_success "Visual Studio Code setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vscode
fi