. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Expects: BACKUP_DIR, DATE, SCRIPT_DIR (set by setup_ai.sh)
setup_continue() {
    print_info "Setting up Continue.dev..."
    [ -f "$HOME/.continue/config.yaml" ] && \
        cp "$HOME/.continue/config.yaml" "$BACKUP_DIR/continue_config_backup_$DATE.yaml" && \
        print_status "Backed up Continue.dev config"
    mkdir -p "$HOME/.continue"

    local src_cfg script_dir mac_model
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if declare -f detect_mac_model &>/dev/null; then
        mac_model="$(detect_mac_model)"
    else
        mac_model=""
    fi
    if [ -f "$script_dir/$mac_model/continue/config.yaml" ]; then
        src_cfg="$script_dir/$mac_model/continue/config.yaml"
    else
        print_warning "No continue/$mac_model/config.yaml found"
    fi
    if [ -f "$src_cfg" ]; then
        cp "$src_cfg" "$HOME/.continue/config.yaml"
        print_status "Copied Continue.dev config"
    else
        print_warning "No continue/config.yaml found"
    fi
}

restore_continue() {
    local latest_file latest_dir
    latest_file=$(ls -t "$BACKUP_DIR"/continue_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.continue"
        cp "$latest_file" "$HOME/.continue/config.yaml"
        print_status "Restored Continue.dev config from $(basename "$latest_file")"
    else
        print_warning "No Continue.dev config backup found in $BACKUP_DIR"
    fi
    latest_dir=$(ls -dt "$BACKUP_DIR"/continue_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.continue"
        cp -r "$latest_dir"/. "$HOME/.continue/"
        print_status "Restored Continue.dev directory from $(basename "$latest_dir")"
    fi
}

backup_continue() {
    if [ -f "$HOME/.continue/config.yaml" ]; then
        cp "$HOME/.continue/config.yaml" "$BACKUP_DIR/continue_config_backup_$DATE.yaml"
        print_status "Backed up Continue.dev config"
    fi
    if [ -d "$HOME/.continue" ]; then
        cp -r "$HOME/.continue" "$BACKUP_DIR/continue_backup_$DATE"
        print_status "Backed up Continue.dev directory"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_continue
fi
