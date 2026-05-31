if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# IronClaw — nearai's Agent OS focused on privacy, security, extensibility
# Repo:     https://github.com/nearai/ironclaw
# Install:  brew install ironclaw  (or cargo build --release)
# Setup:    ironclaw onboard
# ---------------------------------------------------------------------------

_ironclaw_cfg_dir="$HOME/.ironclaw"
_ironclaw_cfg="$_ironclaw_cfg_dir/.env"
_ironclaw_yaml="$_ironclaw_cfg_dir/ironclaw.yaml"

verify_ironclaw() {
    if ! command -v ironclaw >/dev/null 2>&1; then
        log_warning "IronClaw not found in PATH"
        return 1
    fi
    log_status "IronClaw found: $(ironclaw --version 2>/dev/null || echo installed)"
    return 0
}

_install_ironclaw() {
    log_info "Installing IronClaw..."

    # Prefer Homebrew if available
    if command -v brew >/dev/null 2>&1; then
        if brew install ironclaw; then
            log_status "IronClaw installed via Homebrew"
            return 0
        fi
        log_warning "brew install ironclaw failed — falling back to installer script"
    fi

    # Fallback: official installer
    log_info "Running official IronClaw installer..."
    if curl --proto '=https' --tlsv1.2 -LsSf \
         https://github.com/nearai/ironclaw/releases/latest/download/ironclaw-installer.sh | sh; then
        log_status "IronClaw installed via official installer"
        return 0
    fi

    # Last resort: cargo
    if command -v cargo >/dev/null 2>&1; then
        log_info "Attempting cargo install ironclaw..."
        if cargo install ironclaw; then
            log_status "IronClaw installed via cargo"
            return 0
        fi
    fi

    log_error "Failed to install IronClaw (tried brew, installer, cargo)"
    return 1
}

setup_ironclaw() {
    log_info "Setting up IronClaw..."
    verify_ironclaw || _install_ironclaw || { log_error "Failed to install IronClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_ironclaw_cfg_dir"
    local src_cfg src_yaml
    src_cfg="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/ironclaw/.env"
    src_yaml="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/ironclaw/ironclaw.yaml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/ai/profiles/default/ironclaw/.env"
    fi
    if [ ! -f "$src_yaml" ]; then
        src_yaml="${SETTINGS_BASE}/ai/profiles/default/ironclaw/ironclaw.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_ironclaw_cfg"
        chmod 600 "$_ironclaw_cfg"
        log_status "Env config deployed to $_ironclaw_cfg"
    fi
    if [ -f "$src_yaml" ]; then
        copy_file "$src_yaml" "$_ironclaw_yaml"
        chmod 600 "$_ironclaw_yaml"
        log_status "YAML config deployed to $_ironclaw_yaml"
    fi

    # Offer onboard
    if ! [ -f "$_ironclaw_cfg" ] && ! [ -f "$_ironclaw_yaml" ]; then
        echo ""
        read -p "  Run 'ironclaw onboard' now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ironclaw onboard || log_warning "IronClaw onboard may need manual re-run"
        fi
    fi

    log_info ""
    log_info "=== IronClaw ==="
    log_info "Binary:   ironclaw"
    log_info "Config:   $_ironclaw_cfg_dir"
    log_info "Setup:    ironclaw onboard"
    log_info "Usage:    ironclaw run"
    log_info "          ironclaw run --ui"
    log_info "          ironclaw doctor"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "  ANTHROPIC_API_KEY=sk-ant-..."
    log_info "  OPENAI_API_KEY=sk-..."
    log_info "Docs:     https://github.com/nearai/ironclaw"
    log_info ""
}

backup_ironclaw() {
    if [ -d "$_ironclaw_cfg_dir" ]; then
        cp -r "$_ironclaw_cfg_dir" "${BACKUP_DIR}/ironclaw_backup_${DATE}"
        log_status "Backed up IronClaw config"
    fi
}

restore_ironclaw() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/ironclaw_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_ironclaw_cfg_dir"
        cp -R "$latest/"* "$_ironclaw_cfg_dir/" 2>/dev/null || true
        log_status "Restored IronClaw config from $(basename "$latest")"
    else
        log_warning "No IronClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ironclaw
fi
