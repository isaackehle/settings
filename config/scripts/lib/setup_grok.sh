. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Install and configure Grok CLI

_install_grok() {
    if command_exists "npm"; then
        install_via_npm "Grok VibeKit" "@vibe-kit/grok-cli" && return 0
        install_via_npm "Grok" "@ai-sdk/grok" && return 0
        install_via_npm "Grok" "grok" && return 0
    fi
    print_warning "npm not available — Grok may need manual install from https://github.com/grok-ai/grok"
    return 1
}

verify_grok() {
    check_tool_with_version "Grok" "grok"
}

setup_grok() {
    print_info "Setting up Grok..."
    verify_grok || _install_grok || print_warning "Grok CLI not installed — skipping"

    # Deploy environment config
    mkdir -p "$HOME/.config/grok"

    cat > "$HOME/.config/grok/_grok" << 'EOF'
# Grok CLI Configuration
export GROK_BASE_URL=http://localhost:11434
export GROK_MODEL=llama3
EOF

    if [ -n "$ZSH_VERSION" ]; then
        mkdir -p "$HOME/.zshrc.d"
        cp "$HOME/.config/grok/_grok" "$HOME/.zshrc.d/grok_env"
        print_status "Grok environment file copied to $HOME/.zshrc.d/grok_env"
    else
        mkdir -p "$HOME/.profile.d"
        cp "$HOME/.config/grok/_grok" "$HOME/.profile.d/grok_env"
        print_status "Grok environment file copied to $HOME/.profile.d/grok_env"
    fi

    print_status "Grok CLI setup completed successfully"
    print_info "Grok env vars are in ~/.zshrc.d/grok_env (or ~/.profile.d/grok_env)"
    print_info "Use: grok --prompt \"Explain this codebase\" for offline AI assistance"
}

restore_grok() {
    local latest_dir
    latest_dir=$(ls -dt "$BACKUP_DIR"/grok_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.config/grok"
        cp -r "$latest_dir"/. "$HOME/.config/grok/"
        print_status "Restored Grok config from $(basename "$latest_dir")"
    else
        print_warning "No Grok config backup found in $BACKUP_DIR"
    fi
}

backup_grok() {
    if [ -d "$HOME/.config/grok" ]; then
        cp -r "$HOME/.config/grok" "$BACKUP_DIR/grok_backup_$DATE"
        print_status "Backed up Grok config directory"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_grok
fi
