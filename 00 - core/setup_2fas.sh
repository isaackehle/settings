#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_2fas() {
    print_info "Installing 2FAS..."
    brew install --cask 2fas
}

verify_2fas() {
    brew list --cask 2fas &>/dev/null
}

setup_2fas() {
    print_info "Setting up 2FAS..."
    verify_2fas || _install_2fas || { print_error "Failed to install 2FAS"; return 1; }
    print_status "2FAS setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_2fas
fi