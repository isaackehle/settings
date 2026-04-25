#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_folx() {
    print_info "Installing Folx..."
    brew install --cask folx
}

verify_folx() {
    brew list --cask folx &>/dev/null
}

setup_folx() {
    print_info "Setting up Folx..."
    verify_folx || _install_folx || { print_error "Failed to install Folx"; return 1; }
    print_status "Folx setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_folx
fi