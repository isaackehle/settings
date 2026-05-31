#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_podman() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Podman."
        return 1
    fi
    log_info "Installing Podman..."
    brew install podman
}

_configure_podman() {
    log_info "Initializing Podman machine..."
    podman machine init 2>/dev/null || log_info "Podman machine already initialized"
    log_info "Starting Podman machine..."
    podman machine start 2>/dev/null || log_info "Podman machine already running"
}

verify_podman() {
    command_exists "podman"
}

setup_podman() {
    log_info "Setting up Podman..."
    verify_podman || _install_podman || { log_error "Failed to install Podman"; return 1; }
    _configure_podman
    log_info "Podman is ready. Use 'podman' instead of 'docker'."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_podman
fi
