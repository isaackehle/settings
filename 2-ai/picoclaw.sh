if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# PicoClaw — minimal AI assistant installed via official installer script
# ---------------------------------------------------------------------------

_picoclaw_cfg_dir="$HOME/.config/picoclaw"
_picoclaw_cfg="$_picoclaw_cfg_dir/config.yaml"

verify_picoclaw() {
    if ! command -v picoclaw &> /dev/null; then
        log_warning "PicoClaw binary not found in PATH"
        return 1
    fi
    if [ ! -f "$_picoclaw_cfg" ]; then
        log_warning "PicoClaw config not found at $_picoclaw_cfg"
        return 1
    fi
    log_status "PicoClaw installed and configured"
    return 0
}

_install_picoclaw() {
    log_info "Installing PicoClaw via official installer..."

    read -p "  Run the PicoClaw installer (curl | bash)? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped PicoClaw installer"
        return 1
    fi

    # Idempotent: installer typically handles re-runs, but we verify after
    if curl -fsSL https://picoclaw.dev/install.sh | bash; then
        log_status "PicoClaw installed"
        return 0
    else
        log_error "Failed to install PicoClaw"
        return 1
    fi
}

_setup_picoclaw_api_key() {
    if [ -f "$_picoclaw_cfg" ] && grep -q 'api_key' "$_picoclaw_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    read -p "  Configure PicoClaw API key now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping API key setup — edit $_picoclaw_cfg manually"
        return 0
    fi

    echo -n "  Enter API key (hidden): "
    read -r -s api_key
    echo

    if [ -n "$api_key" ]; then
        # YAML placeholder replacement
        sed -i '' "s|YOUR_API_KEY|$api_key|g" "$_picoclaw_cfg"
        chmod 600 "$_picoclaw_cfg"
        log_status "API key written to $_picoclaw_cfg"
    fi
}

setup_picoclaw() {
    log_info "Setting up PicoClaw..."

    verify_picoclaw || _install_picoclaw || { log_error "Failed to install PicoClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_picoclaw_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/picoclaw/config.yaml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/picoclaw/config.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_picoclaw_cfg"
        chmod 600 "$_picoclaw_cfg"
        _setup_picoclaw_api_key
    else
        log_warning "No PicoClaw config found at $src_cfg"
    fi

    log_info ""
    log_info "=== PicoClaw ==="
    log_info "Binary:  picoclaw"
    log_info "Config:  $_picoclaw_cfg"
    log_info "Docs:    https://picoclaw.dev"
    log_info ""
}

backup_picoclaw() {
    if [ -f "$_picoclaw_cfg" ]; then
        cp -r "$_picoclaw_cfg_dir" "${BACKUP_DIR}/picoclaw_backup_${DATE}"
        cp "$_picoclaw_cfg" "${BACKUP_DIR}/picoclaw_config_backup_${DATE}.yaml"
        log_status "Backed up PicoClaw config"
    fi
}

restore_picoclaw() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/picoclaw_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/picoclaw_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.config/picoclaw"
        cp -R "$latest_dir/"* "$HOME/.config/picoclaw/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.config/picoclaw"
        cp "$latest_file" "$HOME/.config/picoclaw/config.yaml"
        log_status "Restored PicoClaw config from $(basename "$latest_file")"
    else
        log_warning "No PicoClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_picoclaw
fi
