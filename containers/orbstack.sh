#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_orbstack() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install OrbStack."
        return 1
    fi
    log_info "Installing OrbStack..."
    brew install --cask orbstack
}

verify_orbstack() {
    command_exists "orb" || [ -d "/Applications/OrbStack.app" ]
}

setup_orbstack() {
    log_info "Setting up OrbStack..."
    verify_orbstack || _install_orbstack || { log_error "Failed to install OrbStack"; return 1; }
    log_info "OrbStack is ready. Start it from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_orbstack
fi
