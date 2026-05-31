if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Zoo Code — VS Code extension configuration (model settings, keybindings)
# This is not a standalone binary but a VS Code settings merge target.
# It deploys zoocode/settings.jsonc into VS Code user settings.
# ---------------------------------------------------------------------------

verify_zoocode() {
    # Zoocode has no binary — it's a VS Code configuration bundle
    local _vscode_settings="$HOME/Library/Application Support/Code/User/settings.json"
    if [ -f "$_vscode_settings" ]; then
        log_status "VS Code settings found"
        return 0
    fi
    log_warning "VS Code user settings not found — install VS Code first"
    return 1
}

setup_zoocode() {
    log_info "Setting up Zoo Code VS Code extension config..."

    verify_zoocode || { log_error "VS Code not installed"; return 1; }

    local _profdir _src _dest
    _profdir="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}"
    if [ ! -d "$_profdir" ]; then
        _profdir="${SETTINGS_BASE}/ai/profiles/default"
    fi

    _src="${_profdir}/zoocode/settings.jsonc"
    _dest="$HOME/Library/Application Support/Code/User/settings.json"

    if [ ! -f "$_src" ]; then
        log_warning "No profile config found — see ai/profiles/<machine>/zoocode/settings.jsonc"
        log_info "Zoo Code is a VS Code configuration template. Create $_src to customize."
        return 0
    fi

    # Merge zoocode settings into VS Code user settings
    log_info "Merging Zoo Code settings into VS Code..."
    _merge_vscode_extension "zoo-code" "$_src"

    log_info ""
    log_info "=== Zoo Code ==="
    log_info "Type:    VS Code settings merge"
    log_info "Config:  $_src"
    log_info "Target:  $_dest"
    log_info "Docs:    https://zoocode.com/docs"
    log_info ""
}

backup_zoocode() {
    local _dest="$HOME/Library/Application Support/Code/User/settings.json"
    if [ -f "$_dest" ]; then
        cp "$_dest" "${BACKUP_DIR}/vscode_settings_backup_${DATE}.json"
        log_status "Backed up VS Code settings"
    fi
}

restore_zoocode() {
    local latest
    latest=$(ls -t "${BACKUP_DIR}"/vscode_settings_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        cp "$latest" "$HOME/Library/Application Support/Code/User/settings.json"
        log_status "Restored VS Code settings from $(basename "$latest")"
    else
        log_warning "No VS Code settings backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_zoocode
fi
