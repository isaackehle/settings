if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_editors() {
    print_info "Installing editors..."
    brew install helix
    brew install --cask cursor
    brew install --cask visual-studio-code
    brew install --cask windsurf
    brew install --cask zed
}

_install_vscode_extensions() {
    if ! command_exists "code"; then
        print_warning "VS Code 'code' CLI not in PATH — skipping extensions"
        print_info "Enable: Cmd+Shift+P → 'Shell Command: Install code in PATH'"
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

    for ext in "${extensions[@]}"; do
        print_info "  Installing extension: $ext"
        code --install-extension "$ext" --force
    done
}

verify_editors() {
    local found=0
    command_exists "hx"   && print_status "Helix found"   && found=1
    command_exists "code" && print_status "VS Code found" && found=1
    [[ $found -eq 1 ]]
}

setup_editors() {
    print_info "Setting up editors..."

    verify_editors || _install_editors

    _install_vscode_extensions

    print_info ""
    print_info "=== Editors ==="
    print_info "Helix:         hx ."
    print_info "VS Code:       code ."
    print_info "Cursor:        cursor ."
    print_info "Windsurf:      windsurf ."
    print_info "Helix docs:    https://docs.helix-editor.com/"
    print_info "VS Code docs:  https://code.visualstudio.com/docs"
    print_info ""
    print_warning "Do not run VS Code and Windsurf simultaneously for the same project."
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_editors
fi
