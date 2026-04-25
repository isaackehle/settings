#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_deluge() {
    print_info "Installing Deluge..."
    brew install --cask deluge
}

verify_deluge() {
    brew list --cask deluge &>/dev/null
}

setup_deluge() {
    print_info "Setting up Deluge..."
    verify_deluge || _install_deluge || { print_error "Failed to install Deluge"; return 1; }
    print_status "Deluge setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_deluge
fi