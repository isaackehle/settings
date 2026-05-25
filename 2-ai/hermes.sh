if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Hermes — terminal AI assistant (brew formula)
# ---------------------------------------------------------------------------

_hermes_cfg_dir="$HOME/.hermes"
_hermes_cfg="$_hermes_cfg_dir/config.toml"

verify_hermes() {
    if ! command -v hermes &> /dev/null; then
        log_warning "Hermes binary not found in PATH"
        return 1
    fi
    if [ ! -f "$_hermes_cfg" ]; then
        log_warning "Hermes config not found at $_hermes_cfg"
        return 1
    fi
    log_status "Hermes installed and configured"
    return 0
}

_install_hermes() {
    log_info "Installing Hermes via Homebrew..."
    if brew install hermes-ai; then
        log_status "Hermes installed via Homebrew"
        return 0
    else
        log_error "Failed to install Hermes"
        return 1
    fi
}

_setup_hermes_api_key() {
    if [ -f "$_hermes_cfg" ] && grep -q 'api_key' "$_hermes_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    read -p "  Configure Hermes API key now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping API key setup — edit $_hermes_cfg manually"
        return 0
    fi

    echo -n "  Enter API key (hidden): "
    read -r -s api_key
    echo

    if [ -n "$api_key" ]; then
        sed -i '' "s|YOUR_API_KEY|$api_key|g" "$_hermes_cfg"
        chmod 600 "$_hermes_cfg"
        log_status "API key written to $_hermes_cfg"
    fi
}

setup_hermes() {
    log_info "Setting up Hermes..."

    verify_hermes || _install_hermes || { log_error "Failed to install Hermes"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_hermes_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/hermes/config.toml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/hermes/config.toml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_hermes_cfg"
        chmod 600 "$_hermes_cfg"
        _setup_hermes_api_key
    else
        log_warning "No Hermes config found at $src_cfg"
    fi

    log_info ""
    log_info "=== Hermes ==="
    log_info "Binary:  hermes"
    log_info "Config:  $_hermes_cfg"
    log_info "Docs:    https://github.com/hermes-ai/hermes"
    log_info ""
}

backup_hermes() {
    if [ -f "$_hermes_cfg" ]; then
        cp -r "$HOME/.hermes" "${BACKUP_DIR}/hermes_backup_${DATE}"
        cp "$_hermes_cfg" "${BACKUP_DIR}/hermes_config_backup_${DATE}.toml"
        log_status "Backed up Hermes config"
    fi
}

restore_hermes() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/hermes_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/hermes_config_backup_*.toml 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.hermes"
        cp -R "$latest_dir/"* "$HOME/.hermes/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.hermes"
        cp "$latest_file" "$HOME/.hermes/config.toml"
        log_status "Restored Hermes config from $(basename "$latest_file")"
    else
        log_warning "No Hermes backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_hermes
fi
