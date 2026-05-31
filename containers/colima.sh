#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_colima() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Colima."
        return 1
    fi
    log_info "Installing Colima..."
    brew install colima docker docker-compose
}

_configure_colima() {
    log_info "Starting Colima with default config..."
    colima start 2>/dev/null || log_info "Colima already running"
    log_info "Setting Docker context to colima..."
    docker context use colima 2>/dev/null || true
}

verify_colima() {
    command_exists "colima"
}

setup_colima() {
    log_info "Setting up Colima..."
    verify_colima || _install_colima || { log_error "Failed to install Colima"; return 1; }
    _configure_colima
    log_info "Colima is ready. Docker socket is at ~/.colima/docker.sock."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_colima
fi
