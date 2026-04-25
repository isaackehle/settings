#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_itsycal() {
    print_info "Installing Itsycal..."
    brew install --cask itsycal
}

verify_itsycal() {
    brew list --cask itsycal &>/dev/null
}

setup_itsycal() {
    print_info "Setting up Itsycal..."
    verify_itsycal || _install_itsycal || { print_error "Failed to install Itsycal"; return 1; }
    print_status "Itsycal setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_itsycal
fi