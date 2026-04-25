#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_comet() {
    print_info "Installing Comet..."
    brew install --cask comet
}

verify_comet() {
    brew list --cask comet &>/dev/null
}

setup_comet() {
    print_info "Setting up Comet..."
    verify_comet || _install_comet || { print_error "Failed to install Comet"; return 1; }
    print_status "Comet setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_comet
fi