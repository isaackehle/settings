#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_chrome() {
    print_info "Installing Google Chrome..."
    brew install --cask google-chrome
}

verify_chrome() {
    brew list --cask google-chrome &>/dev/null
}

setup_chrome() {
    print_info "Setting up Google Chrome..."
    verify_chrome || _install_chrome || { print_error "Failed to install Google Chrome"; return 1; }
    print_status "Google Chrome setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_chrome
fi