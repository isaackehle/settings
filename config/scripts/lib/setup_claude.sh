. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Expects: BACKUP_DIR, DATE, NEW_CFG_DIR (set by configure_devtools.sh)

# Install Claude Code CLI (try npm first, then Homebrew, then manual)
_install_claude_code_cli() {
    if command_exists "npm"; then
        install_via_npm "Anthropic Claude Code" "@anthropic-ai/claude-code" && return 0
        install_via_npm "Claude Code" "@ai-sdk/claude-code" && return 0
        install_via_npm "Claude Code" "claude-code" && return 0
    fi
    if command_exists "brew"; then
        print_info "Attempting Homebrew install..."
        brew install --cask claude-code && { print_status "Claude Code installed via Homebrew"; return 0; }
    fi
    print_info "Please manually install Claude Code from:"
    print_info "  https://github.com/claude-code/claude-code"
    print_info "  Documentation: https://docs.claudecode.com/"
    return 1
}

verify_claude_code() {
    check_tool_with_version "Claude Code" "claude-code"
}

# Install CLI if needed, then deploy config
setup_claude() {
    print_info "Setting up Claude Code..."
    verify_claude_code || _install_claude_code_cli || print_warning "Claude Code CLI not installed — skipping"
    [ -f "$HOME/.claude-code/config.json" ] && \
        cp "$HOME/.claude-code/config.json" "$BACKUP_DIR/claude_code_config_backup_$DATE.json" && \
        print_status "Backed up Claude Code config"
    mkdir -p "$HOME/.claude-code"
    if [ -f "$NEW_CFG_DIR/claude_code.json" ]; then
        cp "$NEW_CFG_DIR/claude_code.json" "$HOME/.claude-code/config.json"
        print_status "Copied Claude Code config"
    else
        print_warning "No claude_code.json found in $NEW_CFG_DIR"
    fi
}

restore_claude() {
    local latest_file latest_dir
    latest_file=$(ls -t "$BACKUP_DIR"/claude_code_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.claude-code"
        cp "$latest_file" "$HOME/.claude-code/config.json"
        print_status "Restored Claude Code config from $(basename "$latest_file")"
    else
        print_warning "No Claude Code config backup found in $BACKUP_DIR"
    fi
    latest_dir=$(ls -dt "$BACKUP_DIR"/claude_code_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.claude-code"
        cp -r "$latest_dir"/. "$HOME/.claude-code/"
        print_status "Restored Claude Code directory from $(basename "$latest_dir")"
    fi
}

backup_claude() {
    if [ -f "$HOME/.claude-code/config.json" ]; then
        cp "$HOME/.claude-code/config.json" "$BACKUP_DIR/claude_code_config_backup_$DATE.json"
        print_status "Backed up Claude Code config"
    fi
    if [ -d "$HOME/.claude-code" ]; then
        cp -r "$HOME/.claude-code" "$BACKUP_DIR/claude_code_backup_$DATE"
        print_status "Backed up Claude Code directory"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_claude
fi
