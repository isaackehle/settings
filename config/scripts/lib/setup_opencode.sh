. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Install and configure OpenCode
# Expects: BACKUP_DIR, DATE, NEW_CFG_DIR (set by setup_ai.sh) for config deploy

_install_opencode() {
    if command_exists "npm"; then
        install_via_npm "OpenCode" "opencode-ai" && return 0
        install_via_npm "OpenCode" "@ai-sdk/opencode" && return 0
    fi
    if command_exists "brew"; then
        brew install anomalyco/tap/opencode && return 0
    fi
    print_warning "OpenCode not found — install manually from https://github.com/opencode-ai/opencode"
    return 1
}

verify_opencode() {
    check_tool_with_version "OpenCode" "opencode"
}

setup_opencode() {
    print_info "Setting up OpenCode..."
    verify_opencode || _install_opencode || print_warning "OpenCode CLI not installed — skipping"
    [ -f "$HOME/.config/opencode/config.jsonc" ] && \
        cp "$HOME/.config/opencode/config.jsonc" "$BACKUP_DIR/opencode_config_backup_$DATE.jsonc" && \
        print_status "Backed up OpenCode config"
    mkdir -p "$HOME/.config/opencode"
    if [ -f "$NEW_CFG_DIR/opencode/opencode.jsonc" ]; then
        cp "$NEW_CFG_DIR/opencode/opencode.jsonc" "$HOME/.config/opencode/config.jsonc"
        print_status "Copied OpenCode config"
    else
        print_warning "No opencode/opencode.jsonc found in $NEW_CFG_DIR"
    fi
}

restore_opencode() {
    local latest_file latest_dir
    latest_file=$(ls -t "$BACKUP_DIR"/opencode_config_backup_*.jsonc 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.config/opencode"
        cp "$latest_file" "$HOME/.config/opencode/config.jsonc"
        print_status "Restored OpenCode config from $(basename "$latest_file")"
    else
        print_warning "No OpenCode config backup found in $BACKUP_DIR"
    fi
    latest_dir=$(ls -dt "$BACKUP_DIR"/opencode_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.config/opencode"
        cp -r "$latest_dir"/. "$HOME/.config/opencode/"
        print_status "Restored OpenCode directory from $(basename "$latest_dir")"
    fi
}

backup_opencode() {
    if [ -f "$HOME/.config/opencode/config.jsonc" ]; then
        cp "$HOME/.config/opencode/config.jsonc" "$BACKUP_DIR/opencode_config_backup_$DATE.jsonc"
        print_status "Backed up OpenCode config"
    fi
    if [ -d "$HOME/.config/opencode" ]; then
        cp -r "$HOME/.config/opencode" "$BACKUP_DIR/opencode_backup_$DATE"
        print_status "Backed up OpenCode directory"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_opencode
fi
