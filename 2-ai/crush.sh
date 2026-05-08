if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_crush() {
    if command_exists "crush"; then
        local ver
        ver=$(crush --version 2>/dev/null | head -1 || echo "installed")
        log_status "Crush found: $ver"
        return 0
    fi
    log_warning "Crush not found"
    return 1
}

_install_crush() {
    if command_exists "brew"; then
        log_info "Installing Crush via Homebrew..."
        brew install charmbracelet/tap/crush && return 0
    fi
    log_warning "Homebrew not available — see https://github.com/charmbracelet/crush for install options"
    return 1
}

setup_crush() {
    log_info "Setting up Crush..."
    verify_crush || _install_crush || { log_error "Failed to install Crush"; return 1; }

    # Deploy machine-specific config if MACHINE_PROFILE is set
    local config_src="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE:-}/crush/crush.json"
    if [ -n "${MACHINE_PROFILE:-}" ] && [ -f "$config_src" ]; then
        log_info "Deploying crush.json for profile: ${MACHINE_PROFILE}"
        mkdir -p "$HOME/.config/crush"
        cp "$config_src" "$HOME/.config/crush/crush.json"
        log_status "Config deployed to ~/.config/crush/crush.json"
    else
        log_warning "No profile config found — copy manually: cp profiles/<machine>/crush/crush.json ~/.config/crush/crush.json"
    fi

    log_info ""
    log_info "=== Crush ==="
    log_info "Start:   crush"
    log_info "Config:  ~/.config/crush/crush.json"
    log_info "Docs:    https://github.com/charmbracelet/crush"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_crush
fi
