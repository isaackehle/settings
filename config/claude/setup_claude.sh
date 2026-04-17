. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Expects: BACKUP_DIR, DATE, NEW_CFG_DIR (set by setup_ai.sh)

_uninstall_claude_code_legacy() {
    if npm list -g @anthropic-ai/claude-code &>/dev/null 2>&1; then
        print_info "Removing legacy npm install of Claude Code..."
        npm uninstall -g @anthropic-ai/claude-code
    fi
    if command_exists brew && brew list --formula 2>/dev/null | grep -q '^claude'; then
        print_info "Removing legacy Homebrew install of Claude Code..."
        brew uninstall claude 2>/dev/null || brew uninstall claude-code 2>/dev/null || true
    fi
}

_install_claude_code_cli() {
    _uninstall_claude_code_legacy
    print_info "Installing Claude Code via curl..."
    curl -fsSL https://claude.ai/install.sh | bash && return 0
    print_info "Please manually install Claude Code from https://claude.ai/install.sh"
    return 1
}

verify_claude_code() {
    check_tool_with_version "Claude Code" "claude-code"
}

# Install CLI if needed, then deploy config
setup_claude() {
    print_info "Setting up Claude Code..."
    verify_claude_code || _install_claude_code_cli || print_warning "Claude Code CLI not installed — skipping"

    local src_cfg="$(dirname "${BASH_SOURCE[0]}")/config.json"
    local dest_cfg="$HOME/.claude/config.json"
    mkdir -p "$HOME/.claude"
    if [ -f "$src_cfg" ]; then
        [ -f "$dest_cfg" ] && backup_claude
        cp "$src_cfg" "$dest_cfg"
        print_status "Deployed Claude Code config to $dest_cfg"
    else
        print_warning "No config.json found at $src_cfg"
    fi
}

restore_claude() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/claude_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.claude"
        cp "$latest_file" "$HOME/.claude/config.json"
        print_status "Restored Claude Code config from $(basename "$latest_file")"
    else
        print_warning "No Claude Code config backup found in $BACKUP_DIR"
    fi
}

backup_claude() {
    if [ -f "$HOME/.claude/config.json" ]; then
        cp "$HOME/.claude/config.json" "$BACKUP_DIR/claude_config_backup_$DATE.json"
        print_status "Backed up Claude Code config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_claude
fi
