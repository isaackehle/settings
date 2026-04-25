#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_filezilla() {
    print_info "Installing FileZilla..."
    brew install --cask filezilla
}

verify_filezilla() {
    brew list --cask filezilla &>/dev/null
}

setup_filezilla() {
    print_info "Setting up FileZilla..."
    verify_filezilla || _install_filezilla || { print_error "Failed to install FileZilla"; return 1; }
    print_status "FileZilla setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_filezilla
fi