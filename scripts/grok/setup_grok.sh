. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install and configure Grok CLI (@vibe-kit/grok-cli)
# A conversational AI terminal tool backed by xAI's Grok models.
# Configured here to use Ollama as the local provider.

_install_grok() {
    if command_exists "npm"; then
        print_info "Installing @vibe-kit/grok-cli..."
        install_via_npm "Grok CLI" "@vibe-kit/grok-cli" && return 0
    fi
    print_warning "npm not available — install manually: npm install -g @vibe-kit/grok-cli"
    return 1
}

verify_grok() {
    check_tool_with_version "Grok CLI" "grok"
}

setup_grok() {
    print_info "Setting up Grok CLI..."
    verify_grok || _install_grok || print_warning "Grok CLI not installed — skipping"

    local env_file="$HOME/.config/grok/_grok"
    mkdir -p "$HOME/.config/grok"

    cat > "$env_file" << 'EOF'
# Grok CLI — use Ollama as the local provider
export GROKCLI_PROVIDER=ollama
export OLLAMA_BASE_URL=http://localhost:11434
EOF

    if [ -n "$ZSH_VERSION" ]; then
        mkdir -p "$HOME/.zshrc.d"
        cp "$env_file" "$HOME/.zshrc.d/_grok"
        print_status "Grok env written to ~/.zshrc.d/_grok"
    else
        mkdir -p "$HOME/.profile.d"
        cp "$env_file" "$HOME/.profile.d/_grok"
        print_status "Grok env written to ~/.profile.d/_grok"
    fi

    print_info ""
    print_info "=== Grok CLI usage ==="
    print_info "Start:   grok"
    print_info "Provider: Ollama (http://localhost:11434)"
    print_info "Model:   set via OLLAMA_BASE_URL or pick in-session"
    print_info "Repo:    https://github.com/superagent-ai/grok-cli"
    print_info ""
}

backup_grok() {
    if [ -d "$HOME/.config/grok" ]; then
        cp -r "$HOME/.config/grok" "$BACKUP_DIR/grok_backup_$DATE"
        print_status "Backed up Grok config"
    fi
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_grok
fi
