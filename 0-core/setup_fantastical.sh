#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_fantastical() {
    print_info "Installing Fantastical..."
    brew install --cask fantastical
}

verify_fantastical() {
    brew list --cask fantastical &>/dev/null
}

setup_fantastical() {
    print_info "Setting up Fantastical..."
    verify_fantastical || _install_fantastical || { print_error "Failed to install Fantastical"; return 1; }
    print_status "Fantastical setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_fantastical
fi