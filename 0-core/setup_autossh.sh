#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

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