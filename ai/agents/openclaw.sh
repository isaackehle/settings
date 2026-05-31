if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# OpenClaw — personal AI assistant with 25+ messaging channels (npm)
# Repo:     https://github.com/openclaw/openclaw
# Install:  npm install -g openclaw@latest
# Setup:    openclaw onboard --install-daemon
# ---------------------------------------------------------------------------

_openclaw_cfg_dir="$HOME/.openclaw"
_openclaw_cfg="$_openclaw_cfg_dir/openclaw.json"

verify_openclaw() {
    if ! command -v openclaw >/dev/null 2>&1; then
        log_warning "OpenClaw not found in PATH"
        return 1
    fi
    log_status "OpenClaw found: $(openclaw --version 2>/dev/null || echo installed)"
    return 0
}

_install_openclaw() {
    log_info "Installing OpenClaw via npm..."

    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is required to install OpenClaw"
        log_info "Install Node.js first: brew install node"
        return 1
    fi

    # Prefer pnpm if available, else npm
    local _pkg_mgr="npm"
    if command -v pnpm >/dev/null 2>&1; then
        _pkg_mgr="pnpm"
        log_info "Using pnpm for faster install"
    fi

    if $_pkg_mgr install -g openclaw@latest; then
        log_status "OpenClaw installed via ${_pkg_mgr}"
        return 0
    fi
    log_error "Failed to install OpenClaw"
    return 1
}

_setup_openclaw_config() {
    if [ -f "$_openclaw_cfg" ]; then
        return 0
    fi

    log_info "OpenClaw needs initial setup. Run 'openclaw onboard' after install."
    log_info "It will configure: provider, channels (Telegram, Slack, etc.), and daemon."
}

setup_openclaw() {
    log_info "Setting up OpenClaw..."
    verify_openclaw || _install_openclaw || { log_error "Failed to install OpenClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_openclaw_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/openclaw/openclaw.json"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/ai/profiles/default/openclaw/openclaw.json"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_openclaw_cfg"
        chmod 600 "$_openclaw_cfg"
        log_status "Config deployed to $_openclaw_cfg"
    else
        log_warning "No OpenClaw config found — run 'openclaw onboard' to configure"
    fi

    _setup_openclaw_config

    # Offer to run onboard
    if [ ! -f "$_openclaw_cfg" ]; then
        echo ""
        read -p "  Run 'openclaw onboard --install-daemon' now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            openclaw onboard --install-daemon || log_warning "OpenClaw onboard may need manual re-run"
        fi
    fi

    log_info ""
    log_info "=== OpenClaw ==="
    log_info "Binary:   openclaw"
    log_info "Config:   $_openclaw_cfg_dir"
    log_info "Setup:    openclaw onboard --install-daemon"
    log_info "Usage:    openclaw agent --message 'hello'"
    log_info "          openclaw message send --target +NUMBER --message 'hi'"
    log_info "          openclaw gateway status"
    log_info "Update:   openclaw update --channel stable|beta|dev"
    log_info "Docs:     https://docs.openclaw.ai"
    log_info "          https://github.com/openclaw/openclaw"
    log_info ""
}

backup_openclaw() {
    if [ -d "$_openclaw_cfg_dir" ]; then
        cp -r "$_openclaw_cfg_dir" "${BACKUP_DIR}/openclaw_backup_${DATE}"
        log_status "Backed up OpenClaw config"
    fi
}

restore_openclaw() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/openclaw_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_openclaw_cfg_dir"
        cp -R "$latest/"* "$_openclaw_cfg_dir/" 2>/dev/null || true
        log_status "Restored OpenClaw config from $(basename "$latest")"
    else
        log_warning "No OpenClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_openclaw
fi
