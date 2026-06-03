if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Pi — interactive coding agent CLI (npm)
# Repo:     https://github.com/earendil-works/pi
# Install:  npm i -g @earendil-works/pi-coding-agent
# Docs:     https://pi.dev/docs/latest
# ---------------------------------------------------------------------------

_pi_cfg_dir="$HOME/.pi/agent"

verify_pi() {
    if command -v pi >/dev/null 2>&1; then
        local ver
        ver=$(pi --version 2>/dev/null | head -1 || echo "installed")
        log_status "Pi found: $ver"
        return 0
    fi
    log_warning "Pi not found"
    return 1
}

_install_pi() {
    log_info "Installing Pi via npm..."

    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm is required to install Pi"
        log_info "Install Node.js first: brew install node"
        return 1
    fi

    local _pkg_mgr="npm"
    if command -v pnpm >/dev/null 2>&1; then
        _pkg_mgr="pnpm"
        log_info "Using pnpm for faster install"
    fi

    if $_pkg_mgr install -g @earendil-works/pi-coding-agent; then
        log_status "Pi installed via ${_pkg_mgr}"
        return 0
    fi
    log_error "Failed to install Pi"
    return 1
}

_setup_pi_auth() {
    if [ -f "$_pi_cfg_dir/auth.json" ]; then
        return 0
    fi

    echo ""
    log_info "Pi needs model provider credentials."
    log_info "You can configure them now or later via 'pi /login'."
    echo ""
    read -p "  Configure API keys now? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping — run 'pi /login' later or write ~/.pi/agent/auth.json directly"
        return 0
    fi

    pi /login || log_warning "Pi login may need manual re-run"
}

setup_pi() {
    log_info "Setting up Pi..."
    verify_pi || _install_pi || { log_error "Failed to install Pi"; return 1; }

    mkdir -p "$_pi_cfg_dir"
    _setup_pi_auth

    log_info ""
    log_info "=== Pi ==="
    log_info "Binary:   pi"
    log_info "Config:   $_pi_cfg_dir"
    log_info "Auth:     $_pi_cfg_dir/auth.json"
    log_info "Login:    pi /login"
    log_info "Usage:    pi                           (interactive session)"
    log_info "          pi --mode rpc                (RPC mode for Pi Studio)"
    log_info "          pi /install                  (install shell integration)"
    log_info "Update:   npm update -g @earendil-works/pi-coding-agent"
    log_info "Docs:     https://pi.dev/docs/latest"
    log_info "          https://github.com/earendil-works/pi"
    log_info "GUI:      Pi Studio (see pi-studio setup)"
    log_info ""
}

backup_pi() {
    if [ -d "$_pi_cfg_dir" ]; then
        cp -r "$_pi_cfg_dir" "${BACKUP_DIR}/pi_backup_${DATE}"
        log_status "Backed up Pi config"
    fi
}

restore_pi() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/pi_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_pi_cfg_dir"
        cp -R "$latest/"* "$_pi_cfg_dir/" 2>/dev/null || true
        log_status "Restored Pi config from $(basename "$latest")"
    else
        log_warning "No Pi backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pi
fi
