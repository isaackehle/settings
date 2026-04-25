#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Ghostty - Fast, native macOS terminal emulator written in Zig. 
# GPU-accelerated, supports splits, tabs, and shell integration.
# Drop-in replacement for iTerm2 or Wezterm with lower latency.
# Website: https://ghostty.org
# Config reload: Cmd+Shift+, (no restart needed)

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

setup_ghostty() {
    print_info "Setting up Ghostty..."
    verify_ghostty || _install_ghostty || print_warning "Ghostty not installed — skipping config deploy"

    local cfg_dir="$HOME/.config/ghostty"
    local cfg_file="$cfg_dir/config"
    mkdir -p "$cfg_dir"

    # Note: source config is assumed to be in the same directory as this script
    local src_cfg="$(dirname "${BASH_SOURCE[0]}")/config"
    if [ -f "$src_cfg" ]; then
        [ -f "$cfg_file" ] && backup_ghostty
        cp "$src_cfg" "$cfg_file"
        print_status "Deployed Ghostty config to $cfg_file"
    else
        print_warning "No source config found at $src_cfg"
    fi

    print_info ""
    print_info "=== Ghostty Configuration Summary ==="
    print_info "Config Location:  $cfg_file"
    print_info "Reload Shortcut:  Cmd+Shift+,"
    print_info ""
    print_info "Key Settings:"
    print_info "  - Font: JetBrainsMono Nerd Font (Size 14)"
    print_info "  - Theme: light:Catppuccin Latte, dark:Catppuccin Mocha"
    print_info "  - Background: Opacity 0.92, Blur 20"
    print_info "  - Integration: zsh"
    print_info ""
    print_info "Keybindings:"
    print_info "  - Split Right: Cmd+D"
    print_info "  - Split Down:  Cmd+Shift+D"
    print_info "  - New Window:   Cmd+Shift+Enter"
    print_info "  - Navigate:     Cmd+Alt+Arrow Keys"
    print_info "  - Tab Switch:   Ctrl+Tab / Ctrl+Shift+Tab"
    print_info "  - Delete Word:  Cmd+Backspace"
    print_info "  - Tmux Session: Cmd+S"
    print_info ""
    
    print_status "Ghostty setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ghostty
fi