if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_kilo_cfg_dir="$HOME/.kilo"
_kilo_cfg="$_kilo_cfg_dir/kilo.jsonc"

verify_kilocode() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "kilo-code"; then
        log_status "Kilo Code extension found"
        return 0
    fi
    log_warning "Kilo Code extension not found"
    return 1
}

_install_kilocode() {
    if command_exists "code"; then
        log_info "Installing Kilo Code extension..."
        code --install-extension kilohealth.kilo-code && return 0
    fi
    if command_exists "windsurf"; then
        log_info "Installing Kilo Code in Windsurf..."
        windsurf --install-extension kilohealth.kilo-code && return 0
    fi
    log_warning "VS Code CLI (code) not found — install VS Code first"
    return 1
}

setup_kilocode() {
    log_info "Setting up Kilo Code..."
    verify_kilocode || _install_kilocode || log_warning "Kilo Code not installed — skipping"

    local profdir="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/kilocode"

    # Deploy kilo.jsonc
    local kilo_src="${profdir}/kilo.jsonc"
    if [ -f "$kilo_src" ]; then
        [ -f "$_kilo_cfg" ] && backup_kilocode
        mkdir -p "$_kilo_cfg_dir"
        cp "$kilo_src" "$_kilo_cfg"
        log_status "Config deployed to $_kilo_cfg  (profile: ${MACHINE_PROFILE})"
    else
        log_warning "No kilo.jsonc found — see 2-ai/profiles/<machine>/kilocode/kilo.jsonc"
    fi

    # VS Code settings snippet (manual merge)
    local settings_src="${profdir}/settings.jsonc"
    if [ -f "$settings_src" ]; then
        log_info "VS Code snippet: $settings_src"
        log_info "Merge into: ~/Library/Application Support/Code/User/settings.json"
    fi

    log_info ""
    log_info "=== Kilo Code ==="
    log_info "Extension: kilohealth.kilo-code"
    log_info "Config:    $_kilo_cfg"
    log_info "Base URL:  http://localhost:4000/v1  (via LiteLLM)"
    log_info "API Key:   sk-local"
    log_info "Docs:      https://kilocode.ai/docs"
    log_info ""
}

backup_kilocode() {
    if [ -f "$_kilo_cfg" ]; then
        cp "$_kilo_cfg" "${BACKUP_DIR}/kilocode_config_backup_${DATE}.jsonc"
        log_status "Backed up Kilo Code config"
    fi
}

restore_kilocode() {
    local latest_file
    latest_file=$(ls -t "${BACKUP_DIR}"/kilocode_config_backup_*.jsonc 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_kilo_cfg_dir"
        cp "$latest_file" "$_kilo_cfg"
        log_status "Restored Kilo Code config from $(basename "$latest_file")"
    else
        log_warning "No Kilo Code backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kilocode
fi
