. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install and configure Crush
# Expects: BACKUP_DIR, DATE, SCRIPT_DIR (set by setup_ai.sh) for config deploy

_crush_cfg_dir="$HOME/.config/crush"
_crush_cfg="$_crush_cfg_dir/crush.json"

_install_crush() {
    print_info "Installing Crush via brew..."
    brew install charmbracelet/tap/crush && return 0
    print_warning "brew install failed — install manually: https://github.com/charmbracelet/crush"
    return 1
}

verify_crush() {
    check_tool_with_version "Crush" "crush"
}

setup_crush() {
    print_info "Setting up Crush..."
    verify_crush || _install_crush || print_warning "Crush CLI not installed — skipping"

    [ -f "$_crush_cfg" ] && \
        cp "$_crush_cfg" "$BACKUP_DIR/crush_config_backup_$DATE.json" && \
        print_status "Backed up Crush config"

    mkdir -p "$_crush_cfg_dir"

    local crush_src=""
    if declare -f find_source > /dev/null 2>&1; then
        [ -z "${MAC_MODEL:-}" ] && MAC_MODEL="$(_detect_profile)"
        crush_src=$(find_source "crush/crush.json")
    fi
    [ -z "$crush_src" ] && crush_src="$SCRIPT_DIR/crush/crush.json"

    if [ -f "$crush_src" ]; then
        cp "$crush_src" "$_crush_cfg"
        print_status "Copied Crush config to $_crush_cfg"
    else
        print_warning "No crush/crush.json found in $SCRIPT_DIR"
    fi
}

restore_crush() {
    local latest_file latest_dir
    latest_file=$(ls -t "$BACKUP_DIR"/crush_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_crush_cfg_dir"
        cp "$latest_file" "$_crush_cfg"
        print_status "Restored Crush config from $(basename "$latest_file")"
    else
        print_warning "No Crush config backup found in $BACKUP_DIR"
    fi
    latest_dir=$(ls -dt "$BACKUP_DIR"/crush_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$_crush_cfg_dir"
        cp -r "$latest_dir"/. "$_crush_cfg_dir/"
        print_status "Restored Crush directory from $(basename "$latest_dir")"
    fi
}

backup_crush() {
    if [ -f "$_crush_cfg" ]; then
        cp "$_crush_cfg" "$BACKUP_DIR/crush_config_backup_$DATE.json"
        print_status "Backed up Crush config"
    fi
    if [ -d "$_crush_cfg_dir" ]; then
        cp -r "$_crush_cfg_dir" "$BACKUP_DIR/crush_backup_$DATE"
        print_status "Backed up Crush directory"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_crush
fi
