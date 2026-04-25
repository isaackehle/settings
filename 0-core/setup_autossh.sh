#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_autossh() {
    print_info "Installing autossh..."
    brew install autossh
}

verify_autossh() {
    command_exists "autossh"
}

setup_autossh() {
    print_info "Setting up autossh..."
    verify_autossh || _install_autossh || { print_error "Failed to install autossh"; return 1; }
    print_status "autossh setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_autossh
fi