if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Plandex — terminal-based AI development planner (curl installer)
# ---------------------------------------------------------------------------

_plandex_cfg_dir="$HOME/.config/plandex"
_plandex_cfg="$_plandex_cfg_dir/config.env"

verify_plandex() {
    if command -v plandex >/dev/null 2>&1 || command -v pdx >/dev/null 2>&1; then
        log_status "Plandex found"
        return 0
    fi
    log_warning "Plandex not found (binary: plandex or pdx)"
    return 1
}

_install_plandex() {
    log_info "Installing Plandex via official installer..."

    read -p "  Run the Plandex curl installer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped Plandex installer"
        return 1
    fi

    if curl -sL https://plandex.ai/install.sh | bash; then
        log_status "Plandex installed"
        return 0
    fi
    log_error "Failed to install Plandex"
    return 1
}

_setup_plandex_api_key() {
    if [ -f "$_plandex_cfg" ] && grep -q 'OPENROUTER' "$_plandex_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    log_info "Plandex uses OpenRouter by default (or Claude subscription)."
    read -p "  Configure OpenRouter API key now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping API key — add OPENROUTER_API_KEY later to $_plandex_cfg or ~/.env.local"
        return 0
    fi

    echo -n "  Enter OpenRouter API key (hidden): "
    read -r -s api_key
    echo

    if [ -n "$api_key" ]; then
        cat > "$_plandex_cfg" << EOF
# Plandex provider configuration
# API keys are sourced from ~/.env.local — do not add real keys here.
# Add keys to ~/.env.local instead (sourced by your shell at login).
OPENROUTER_API_KEY=$api_key
EOF
        chmod 600 "$_plandex_cfg"
        log_status "OpenRouter key written to $_plandex_cfg"
    fi
}

setup_plandex() {
    log_info "Setting up Plandex..."
    verify_plandex || _install_plandex || { log_error "Failed to install Plandex"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_plandex_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/plandex/config.env"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/ai/profiles/default/plandex/config.env"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_plandex_cfg"
        chmod 600 "$_plandex_cfg"
        _setup_plandex_api_key
    else
        log_warning "No Plandex config found"
        _setup_plandex_api_key
    fi

    log_info ""
    log_info "=== Plandex ==="
    log_info "Binary:  plandex (or pdx alias)"
    log_info "Config:  $_plandex_cfg_dir"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "  OPENROUTER_API_KEY=sk-or-..."
    log_info "Usage:   cd your-project && plandex"
    log_info "         plandex (enters chat mode)"
    log_info "         plandex tell 'add a feature'"
    log_info "Docs:    https://docs.plandex.ai"
    log_info ""
}

backup_plandex() {
    if [ -f "$_plandex_cfg" ]; then
        cp -r "$_plandex_cfg_dir" "${BACKUP_DIR}/plandex_backup_${DATE}"
        cp "$_plandex_cfg" "${BACKUP_DIR}/plandex_config_backup_${DATE}.env"
        log_status "Backed up Plandex config"
    fi
}

restore_plandex() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/plandex_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/plandex_config_backup_*.env 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$_plandex_cfg_dir"
        cp -R "$latest_dir/"* "$_plandex_cfg_dir/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$_plandex_cfg_dir"
        cp "$latest_file" "$_plandex_cfg"
        log_status "Restored Plandex config from $(basename "$latest_file")"
    else
        log_warning "No Plandex backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_plandex
fi
