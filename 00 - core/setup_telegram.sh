#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_telegram() {
    print_info "Installing Telegram..."
    brew install --cask telegram
}

verify_telegram() {
    brew list --cask telegram &>/dev/null
}

setup_telegram() {
    print_info "Setting up Telegram..."
    verify_telegram || _install_telegram || { print_error "Failed to install Telegram"; return 1; }
    print_status "Telegram setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_telegram
fi