if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# OpenClaw — terminal AI agent (custom tap)
# ---------------------------------------------------------------------------

_openclaw_cfg_dir="$HOME/.openclaw"
_openclaw_cfg="$_openclaw_cfg_dir/config.json"

verify_openclaw() {
    if ! command -v openclaw &> /dev/null; then
        log_warning "OpenClaw binary not found in PATH"
        return 1
    fi
    if [ ! -f "$_openclaw_cfg" ]; then
        log_warning "OpenClaw config not found at $_openclaw_cfg"
        return 1
    fi
    log_status "OpenClaw installed and configured"
    return 0
}

_install_openclaw() {
    log_info "Installing OpenClaw..."

    # Requires a third-party tap
    if ! brew tap | grep -q "claw-suite/openclaw"; then
        read -p "  OpenClaw requires the claw-suite/tap. Add it? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_warning "Skipped adding tap — cannot install OpenClaw"
            return 1
        fi
        brew tap claw-suite/openclaw
    fi

    if brew install openclaw; then
        log_status "OpenClaw installed via Homebrew"
        return 0
    else
        log_error "Failed to install OpenClaw"
        return 1
    fi
}

_setup_openclaw_api_key() {
    if [ -f "$_openclaw_cfg" ] && grep -q '"api_key"' "$_openclaw_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    read -p "  Configure OpenClaw API key now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping API key setup — edit $_openclaw_cfg manually"
        return 0
    fi

    echo -n "  Enter API key (hidden): "
    read -r -s api_key
    echo

    if [ -n "$api_key" ]; then
        # Inject key into config if jq is available, else replace placeholder
        if command -v jq &> /dev/null; then
            local tmp
            tmp=$(mktemp)
            jq --arg k "$api_key" '.api_key = $k' "$_openclaw_cfg" > "$tmp" && mv "$tmp" "$_openclaw_cfg"
        else
            sed -i '' "s|YOUR_API_KEY|$api_key|g" "$_openclaw_cfg"
        fi
        chmod 600 "$_openclaw_cfg"
        log_status "API key written to $_openclaw_cfg"
    fi
}

setup_openclaw() {
    log_info "Setting up OpenClaw..."

    verify_openclaw || _install_openclaw || { log_error "Failed to install OpenClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_openclaw_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/openclaw/config.json"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/openclaw/config.json"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_openclaw_cfg"
        chmod 600 "$_openclaw_cfg"
        _setup_openclaw_api_key
    else
        log_warning "No OpenClaw config found at $src_cfg"
    fi

    log_info ""
    log_info "=== OpenClaw ==="
    log_info "Binary:  openclaw"
    log_info "Config:  $_openclaw_cfg"
    log_info "Docs:    https://github.com/claw-suite/openclaw"
    log_info ""
}

backup_openclaw() {
    if [ -f "$_openclaw_cfg" ]; then
        cp -r "$HOME/.openclaw" "${BACKUP_DIR}/openclaw_backup_${DATE}"
        cp "$_openclaw_cfg" "${BACKUP_DIR}/openclaw_config_backup_${DATE}.json"
        log_status "Backed up OpenClaw config"
    fi
}

restore_openclaw() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/openclaw_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/openclaw_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.openclaw"
        cp -R "$latest_dir/"* "$HOME/.openclaw/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.openclaw"
        cp "$latest_file" "$HOME/.openclaw/config.json"
        log_status "Restored OpenClaw config from $(basename "$latest_file")"
    else
        log_warning "No OpenClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_openclaw
fi
