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

    cat > grok_setup.sh << 'EOF'
#!/bin/bash
# Grok CLI Setup Script

echo "Sourcing Grok environment variables..."
if [ -f "$HOME/.profile.d/grok_env" ]; then
    source "$HOME/.profile.d/grok_env"
    echo "Grok environment variables sourced from ~/.profile.d/grok_env"
elif [ -f "$HOME/.zshrc.d/grok_env" ]; then
    source "$HOME/.zshrc.d/grok_env"
    echo "Grok environment variables sourced from ~/.zshrc.d/grok_env"
else
    echo "Warning: Grok environment file not found in standard locations"
fi

echo ""
echo "To use Grok CLI:"
echo "1. Source this script: source grok_setup.sh"
echo "2. Use: grok --prompt \"Explain this codebase\""
echo ""
echo "This enables fully offline AI coding assistance when combined with Ollama, preserving privacy and reducing costs."
EOF

    chmod +x grok_setup.sh

    print_status "Grok CLI setup completed successfully"
    print_info "Run 'source grok_setup.sh' to set up Grok CLI environment variables"
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
