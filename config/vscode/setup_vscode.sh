. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_vscode() {
    if ! command_exists "brew"; then
        print_error "Homebrew is required. Install Homebrew first."
        return 1
    fi
    print_info "Installing Visual Studio Code..."
    brew install --cask visual-studio-code
}

verify_vscode() {
    check_tool_with_version "VS Code" "code"
}

setup_vscode_extensions() {
    if ! command_exists "code"; then
        print_warning "VS Code 'code' CLI not found — skipping extension install."
        print_info "Enable it from VS Code: Cmd+Shift+P → 'Shell Command: Install code in PATH'"
        return 1
    fi

    print_info "Installing VS Code extensions..."

    local extensions=(
        "Continue.continue"           # AI code assistant (Continue.dev)
        "saoudrizwan.claude-dev"      # Cline — autonomous AI coding agent
        "eamodio.gitlens"             # GitLens
        "esbenp.prettier-vscode"      # Prettier
        "dbaeumer.vscode-eslint"      # ESLint
        "ms-python.python"            # Python
    )

    for ext in "${extensions[@]}"; do
        print_info "  Installing: $ext"
        code --install-extension "$ext" --force
    done

    print_status "VS Code extensions installed."
}

backup_vscode() {
    local settings_src="$HOME/Library/Application Support/Code/User/settings.json"
    if [ -f "$settings_src" ]; then
        cp "$settings_src" "$BACKUP_DIR/vscode_settings_backup_$DATE.json"
        print_status "Backed up VS Code settings.json"
    fi
}

restore_vscode() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/vscode_settings_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        local dest="$HOME/Library/Application Support/Code/User/settings.json"
        mkdir -p "$(dirname "$dest")"
        cp "$latest_file" "$dest"
        print_status "Restored VS Code settings from $(basename "$latest_file")"
    else
        print_warning "No VS Code settings backup found in $BACKUP_DIR"
    fi
}

setup_vscode() {
    print_info "Setting up Visual Studio Code..."

    verify_vscode || _install_vscode || { print_error "Failed to install VS Code"; return 1; }

    setup_vscode_extensions

    print_info ""
    print_info "=== VS Code ==="
    print_info "Launch from terminal:  code ."
    print_info "  (Required so VS Code inherits ANTHROPIC_BASE_URL and ANTHROPIC_API_KEY)"
    print_info "Continue config:       ~/.continue/config.yaml (deployed by setup_ai.sh)"
    print_info "Cline config:          sidebar → gear → API Provider: Ollama, Base URL: http://localhost:11434"
    print_info "Docs:                  https://code.visualstudio.com/docs"
    print_info ""
    print_warning "Do not run VS Code and Windsurf simultaneously for the same project — pick one."
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vscode
fi
