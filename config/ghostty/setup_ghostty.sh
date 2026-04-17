. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install Ghostty terminal emulator and deploy config.

_install_ghostty() {
    if command_exists "brew"; then
        print_info "Installing Ghostty via Homebrew..."
        brew install --cask ghostty && return 0
    fi
    print_warning "Homebrew not available — download Ghostty from https://ghostty.org/download"
    return 1
}

verify_ghostty() {
    check_tool_with_version "Ghostty" "ghostty"
}

setup_ghostty() {
    print_info "Setting up Ghostty..."
    verify_ghostty || _install_ghostty || print_warning "Ghostty not installed — skipping config deploy"

    local cfg_dir="$HOME/.config/ghostty"
    local cfg_file="$cfg_dir/config"
    mkdir -p "$cfg_dir"

    local src_cfg="$(dirname "${BASH_SOURCE[0]}")/config"
    if [ -f "$src_cfg" ]; then
        [ -f "$cfg_file" ] && backup_ghostty
        cp "$src_cfg" "$cfg_file"
        print_status "Deployed Ghostty config to $cfg_file"
    else
        print_warning "No source config found at $src_cfg"
    fi

    print_info ""
    print_info "=== Ghostty ==="
    print_info "Config:  $cfg_file"
    print_info "Reload:  Cmd+Shift+,"
    print_info "Splits:  Cmd+D (right), Cmd+Shift+D (down)"
    print_info ""
}

backup_ghostty() {
    local cfg_file="$HOME/.config/ghostty/config"
    if [ -f "$cfg_file" ]; then
        cp "$cfg_file" "$BACKUP_DIR/ghostty_config_backup_$DATE"
        print_status "Backed up Ghostty config"
    fi
}

restore_ghostty() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/ghostty_config_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.config/ghostty"
        cp "$latest_file" "$HOME/.config/ghostty/config"
        print_status "Restored Ghostty config from $(basename "$latest_file")"
    else
        print_warning "No Ghostty config backup found in $BACKUP_DIR"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ghostty
fi
