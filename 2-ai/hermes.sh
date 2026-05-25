if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Hermes — Nous Research self-improving AI agent
# Repo:     https://github.com/NousResearch/hermes-agent
# Install:  curl -fsSL .../install.sh | bash
# Setup:    hermes setup  (or hermes onboard)
# ---------------------------------------------------------------------------

_hermes_cfg_dir="$HOME/.hermes"
_hermes_cfg="$_hermes_cfg_dir/config.yaml"

verify_hermes() {
    if ! command -v hermes >/dev/null 2>&1; then
        log_warning "Hermes not found in PATH"
        return 1
    fi
    log_status "Hermes found: $(hermes --version 2>/dev/null || echo installed)"
    return 0
}

_install_hermes() {
    log_info "Installing Hermes via official installer..."

    read -p "  Run the Hermes curl installer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped Hermes installer"
        return 1
    fi

    if curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash; then
        log_status "Hermes installed"
        # Reload shell to pick up ~/.local/bin or wherever it landed
        log_info "You may need to restart your shell or run: source ~/.bashrc"
        return 0
    fi
    log_error "Failed to install Hermes"
    return 1
}

_setup_hermes_api_key() {
    if [ -f "$_hermes_cfg" ] && grep -q 'api_key' "$_hermes_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    read -p "  Configure Nous Portal API key now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping API key — add later via 'hermes config set' or ~/.env.local"
        return 0
    fi

    echo -n "  Enter Nous Portal API key (hidden): "
    read -r -s api_key
    echo

    if [ -n "$api_key" ]; then
        mkdir -p "$_hermes_cfg_dir"
        cat > "$_hermes_cfg" << EOF
# Hermes configuration
# API keys are sourced from ~/.env.local — do not add real keys here.
# Add keys to ~/.env.local instead (sourced by your shell at login).
provider: nous
api_key: ${api_key}
EOF
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
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/hermes/config.yaml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/hermes/config.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_hermes_cfg"
        chmod 600 "$_hermes_cfg"
        log_status "Config deployed to $_hermes_cfg"
    else
        log_warning "No Hermes config found"
        _setup_hermes_api_key
    fi

    # Offer setup wizard
    if [ ! -f "$_hermes_cfg" ]; then
        echo ""
        read -p "  Run 'hermes setup' now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            hermes setup || log_warning "Hermes setup may need manual re-run"
        fi
    fi

    log_info ""
    log_info "=== Hermes ==="
    log_info "Binary:   hermes"
    log_info "Config:   $_hermes_cfg"
    log_info "Setup:    hermes setup"
    log_info "Usage:    hermes"
    log_info "          hermes model       # choose provider/model"
    log_info "          hermes gateway     # start messaging gateway"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "Docs:     https://hermes-agent.nousresearch.com/docs/"
    log_info "          https://github.com/NousResearch/hermes-agent"
    log_info ""
}

backup_hermes() {
    if [ -d "$_hermes_cfg_dir" ]; then
        cp -r "$_hermes_cfg_dir" "${BACKUP_DIR}/hermes_backup_${DATE}"
        log_status "Backed up Hermes config"
    fi
}

restore_hermes() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/hermes_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_hermes_cfg_dir"
        cp -R "$latest/"* "$_hermes_cfg_dir/" 2>/dev/null || true
        log_status "Restored Hermes config from $(basename "$latest")"
    else
        log_warning "No Hermes backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_hermes
fi
