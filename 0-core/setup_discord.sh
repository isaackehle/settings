#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_discord() {
    print_info "Installing Discord..."
    brew install --cask discord
}

verify_discord() {
    brew list --cask discord &>/dev/null
}

setup_discord() {
    print_info "Setting up Discord..."
    verify_discord || _install_discord || { print_error "Failed to install Discord"; return 1; }
    print_status "Discord setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_discord
fi