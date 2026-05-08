if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_zed() {
    if [ -d "/Applications/Zed.app" ] || command_exists "zed"; then
        log_status "Zed found"
        return 0
    fi
    log_warning "Zed not found"
    return 1
}

_install_zed() {
    if command_exists "brew"; then
        log_info "Installing Zed via Homebrew Cask..."
        brew install --cask zed && return 0
    fi
    log_info "Installing Zed via install script..."
    curl -f https://zed.dev/install.sh | sh && return 0
}

setup_zed() {
    log_info "Setting up Zed..."
    verify_zed || _install_zed || { log_error "Failed to install Zed"; return 1; }

    local config_src="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE:-}/zed/settings.json"
    local config_dest="$HOME/.config/zed/settings.json"
    if [ -n "${MACHINE_PROFILE:-}" ] && [ -f "$config_src" ]; then
        log_info "Deploying Zed settings for profile: ${MACHINE_PROFILE}"
        mkdir -p "$HOME/.config/zed"
        cp "$config_src" "$config_dest"
        log_status "Config deployed to $config_dest"
    else
        log_warning "No profile config found — see 2-ai/profiles/<machine>/zed/settings.json"
    fi

    log_info ""
    log_info "=== Zed ==="
    log_info "Start:    zed"
    log_info "Config:   $config_dest"
    log_info "LiteLLM:  Zed discovers models automatically via http://localhost:4000/v1/models"
    log_info "Docs:     https://zed.dev/docs/ai"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_zed
fi
