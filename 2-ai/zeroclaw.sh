if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# ZeroClaw — fast, small, fully autonomous AI assistant (Rust rewrite of OpenClaw)
# Repo:     https://github.com/zeroclaw-labs/zeroclaw
# Install:  curl -fsSL .../install.sh | bash
# Setup:    auto-runs zeroclaw onboard after install
# ---------------------------------------------------------------------------

_zeroclaw_cfg_dir="$HOME/.zeroclaw"
_zeroclaw_cfg="$_zeroclaw_cfg_dir/config.toml"

verify_zeroclaw() {
    if ! command -v zeroclaw >/dev/null 2>&1; then
        log_warning "ZeroClaw not found in PATH"
        return 1
    fi
    log_status "ZeroClaw found: $(zeroclaw --version 2>/dev/null || echo installed)"
    return 0
}

_install_zeroclaw() {
    log_info "Installing ZeroClaw via official installer..."

    read -p "  Run the ZeroClaw install script? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped ZeroClaw installer"
        return 1
    fi

    if curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh | bash; then
        log_status "ZeroClaw installed"
        return 0
    fi
    log_error "Failed to install ZeroClaw"
    return 1
}

setup_zeroclaw() {
    log_info "Setting up ZeroClaw..."
    verify_zeroclaw || _install_zeroclaw || { log_error "Failed to install ZeroClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_zeroclaw_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/zeroclaw/config.toml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/zeroclaw/config.toml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_zeroclaw_cfg"
        chmod 600 "$_zeroclaw_cfg"
        log_status "Config deployed to $_zeroclaw_cfg"
    else
        log_warning "No ZeroClaw config found — run 'zeroclaw onboard' to configure"
    fi

    # Offer onboard
    if [ ! -f "$_zeroclaw_cfg" ]; then
        echo ""
        read -p "  Run 'zeroclaw onboard' now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            zeroclaw onboard || log_warning "ZeroClaw onboard may need manual re-run"
        fi
    fi

    log_info ""
    log_info "=== ZeroClaw ==="
    log_info "Binary:   zeroclaw"
    log_info "Config:   $_zeroclaw_cfg_dir"
    log_info "Setup:    zeroclaw onboard"
    log_info "Usage:    zeroclaw agent -a <alias>"
    log_info "          zeroclaw service install  # launchd/systemd"
    log_info "          zeroclaw service start"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "Docs:     https://github.com/zeroclaw-labs/zeroclaw"
    log_info ""
}

backup_zeroclaw() {
    if [ -d "$_zeroclaw_cfg_dir" ]; then
        cp -r "$_zeroclaw_cfg_dir" "${BACKUP_DIR}/zeroclaw_backup_${DATE}"
        log_status "Backed up ZeroClaw config"
    fi
}

restore_zeroclaw() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/zeroclaw_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_zeroclaw_cfg_dir"
        cp -R "$latest/"* "$_zeroclaw_cfg_dir/" 2>/dev/null || true
        log_status "Restored ZeroClaw config from $(basename "$latest")"
    else
        log_warning "No ZeroClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_zeroclaw
fi
