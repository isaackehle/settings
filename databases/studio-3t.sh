#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_studio3t() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Studio 3T."
        return 1
    fi
    log_info "Installing Studio 3T..."
    brew install --cask studio-3t
}

verify_studio3t() {
    command_exists "studio-3t" || [ -d "/Applications/Studio 3T.app" ]
}

setup_studio3t() {
    log_info "Setting up Studio 3T..."
    verify_studio3t || _install_studio3t || { log_error "Failed to install Studio 3T"; return 1; }
    log_info "Studio 3T is ready."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_studio3t
fi
