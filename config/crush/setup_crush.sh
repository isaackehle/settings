. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install and configure Crush
# Expects: BACKUP_DIR, DATE, NEW_CFG_DIR (set by setup_ai.sh) for config deploy

_install_crush() {
    if command_exists "npm"; then
        install_via_npm "Charmland Crush" "@charmland/crush" && return 0
        install_via_npm "AI SDK Crush" "@ai-sdk/crush" && return 0
        install_via_npm "Crush" "crush" && return 0
    fi
    if command_exists "brew"; then
        brew install charmland/tap/crush && return 0
    fi
    print_warning "Crush not found — install manually from https://github.com/charmverse/crush"
    return 1
}

verify_crush() {
    check_tool_with_version "Crush" "crush"
}

setup_crush() {
    print_info "Setting up Crush..."
    verify_crush || _install_crush || print_warning "Crush CLI not installed — skipping"
    [ -f "$HOME/.crush/config.json" ] && \
        cp "$HOME/.crush/config.json" "$BACKUP_DIR/crush_config_backup_$DATE.json" && \
        print_status "Backed up Crush config"
    mkdir -p "$HOME/.crush"
    if [ -f "$NEW_CFG_DIR/crush/crush.json" ]; then
        cp "$NEW_CFG_DIR/crush/crush.json" "$HOME/.crush/config.json"
        print_status "Copied Crush config"
    else
        print_warning "No crush/crush.json found in $NEW_CFG_DIR"
    fi
}

restore_crush() {
    local latest_file latest_dir
    latest_file=$(ls -t "$BACKUP_DIR"/crush_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.crush"
        cp "$latest_file" "$HOME/.crush/config.json"
        print_status "Restored Crush config from $(basename "$latest_file")"
    else
        print_warning "No Crush config backup found in $BACKUP_DIR"
    fi
    latest_dir=$(ls -dt "$BACKUP_DIR"/crush_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.crush"
        cp -r "$latest_dir"/. "$HOME/.crush/"
        print_status "Restored Crush directory from $(basename "$latest_dir")"
    fi
}

backup_crush() {
    if [ -f "$HOME/.crush/config.json" ]; then
        cp "$HOME/.crush/config.json" "$BACKUP_DIR/crush_config_backup_$DATE.json"
        print_status "Backed up Crush config"
    fi
    if [ -d "$HOME/.crush" ]; then
        cp -r "$HOME/.crush" "$BACKUP_DIR/crush_backup_$DATE"
        print_status "Backed up Crush directory"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_crush
fi
