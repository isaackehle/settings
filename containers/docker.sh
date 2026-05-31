#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_docker() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Docker."
        return 1
    fi
    log_info "Installing Docker Desktop..."
    brew install --cask docker
}

verify_docker() {
    command_exists "docker"
}

setup_docker() {
    log_info "Setting up Docker Desktop..."
    verify_docker || _install_docker || { log_error "Failed to install Docker Desktop"; return 1; }
    log_info "Docker is ready. Start it from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_docker
fi
