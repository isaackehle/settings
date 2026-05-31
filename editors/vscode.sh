#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
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

setup_vscode_extensions() {
    if ! command_exists "code"; then
        log_warning "VS Code 'code' CLI not in PATH — skipping extensions"
        log_info "Enable: Cmd+Shift+P → 'Shell Command: Install code in PATH'"
        return 1
    fi

    local extensions=(
        "Continue.continue"
        "saoudrizwan.claude-dev"
        "eamodio.gitlens"
        "esbenp.prettier-vscode"
        "dbaeumer.vscode-eslint"
        "ms-python.python"
    )

    log_info "Installing VS Code extensions..."
    for ext in "${extensions[@]}"; do
        log_info "  Installing extension: $ext"
        code --install-extension "$ext" --force
    done
    log_success "VS Code extensions installed."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vscode
fi
