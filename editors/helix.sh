#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_helix() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Helix."
        return 1
    fi
    log_info "Installing Helix editor..."
    brew install helix
}

verify_helix() {
    command_exists "hx"
}

setup_helix() {
    log_info "Setting up Helix editor..."
    verify_helix || _install_helix || { log_error "Failed to install Helix"; return 1; }
    log_info "Helix is ready. Run: hx ."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_helix
fi
