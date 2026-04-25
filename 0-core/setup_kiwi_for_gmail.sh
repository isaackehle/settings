#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_kiwi_for_gmail() {
    print_info "Installing Kiwi for Gmail..."
    brew install --cask kiwi-for-gmail
}

verify_kiwi_for_gmail() {
    brew list --cask kiwi-for-gmail &>/dev/null
}

setup_kiwi_for_gmail() {
    print_info "Setting up Kiwi for Gmail..."
    verify_kiwi_for_gmail || _install_kiwi_for_gmail || { print_error "Failed to install Kiwi for Gmail"; return 1; }
    print_status "Kiwi for Gmail setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kiwi_for_gmail
fi