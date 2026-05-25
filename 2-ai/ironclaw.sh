if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# IronClaw — lightweight pip-based terminal AI assistant
# ---------------------------------------------------------------------------

_ironclaw_cfg_dir="$HOME/.ironclaw"
_ironclaw_cfg="$_ironclaw_cfg_dir/settings.json"

verify_ironclaw() {
    if ! command -v ironclaw &> /dev/null; then
        log_warning "IronClaw binary not found in PATH"
        return 1
    fi
    if [ ! -f "$_ironclaw_cfg" ]; then
        log_warning "IronClaw config not found at $_ironclaw_cfg"
        return 1
    fi
    log_status "IronClaw installed and configured"
    return 0
}

_install_ironclaw() {
    log_info "Installing IronClaw via pip3..."
    if ! command -v pip3 &> /dev/null; then
        log_error "pip3 is required to install IronClaw"
        return 1
    fi
    if pip3 install --upgrade ironclaw; then
        log_status "IronClaw installed via pip3"
        return 0
    else
        log_error "Failed to install IronClaw via pip3"
        return 1
    fi
}

_setup_ironclaw_api_key() {
    if [ -f "$_ironclaw_cfg" ] && grep -q '"api_key"' "$_ironclaw_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    read -p "  Configure IronClaw API key now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping API key setup — edit $_ironclaw_cfg manually"
        return 0
    fi

    echo -n "  Enter API key (hidden): "
    read -r -s api_key
    echo

    if [ -n "$api_key" ]; then
        if command -v jq &> /dev/null; then
            local tmp
            tmp=$(mktemp)
            jq --arg k "$api_key" '.api_key = $k' "$_ironclaw_cfg" > "$tmp" && mv "$tmp" "$_ironclaw_cfg"
        else
            sed -i '' "s|YOUR_API_KEY|$api_key|g" "$_ironclaw_cfg"
        fi
        chmod 600 "$_ironclaw_cfg"
        log_status "API key written to $_ironclaw_cfg"
    fi
}

setup_ironclaw() {
    log_info "Setting up IronClaw..."

    verify_ironclaw || _install_ironclaw || { log_error "Failed to install IronClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_ironclaw_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/ironclaw/settings.json"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/ironclaw/settings.json"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_ironclaw_cfg"
        chmod 600 "$_ironclaw_cfg"
        _setup_ironclaw_api_key
    else
        log_warning "No IronClaw config found at $src_cfg"
    fi

    log_info ""
    log_info "=== IronClaw ==="
    log_info "Binary:  ironclaw"
    log_info "Config:  $_ironclaw_cfg"
    log_info "Docs:    https://github.com/claw-suite/ironclaw"
    log_info ""
}

backup_ironclaw() {
    if [ -f "$_ironclaw_cfg" ]; then
        cp -r "$HOME/.ironclaw" "${BACKUP_DIR}/ironclaw_backup_${DATE}"
        cp "$_ironclaw_cfg" "${BACKUP_DIR}/ironclaw_settings_backup_${DATE}.json"
        log_status "Backed up IronClaw config"
    fi
}

restore_ironclaw() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/ironclaw_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/ironclaw_settings_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.ironclaw"
        cp -R "$latest_dir/"* "$HOME/.ironclaw/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.ironclaw"
        cp "$latest_file" "$HOME/.ironclaw/settings.json"
        log_status "Restored IronClaw config from $(basename "$latest_file")"
    else
        log_warning "No IronClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ironclaw
fi
