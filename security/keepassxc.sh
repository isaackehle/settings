#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_keepassxc() {
    print_info "Installing KeePassXC..."
    brew install --cask keepassxc
}

verify_keepassxc() {
    brew list --cask keepassxc &>/dev/null
}

setup_keepassxc() {
    print_info "Setting up KeePassXC..."
    verify_keepassxc || _install_keepassxc || { print_error "Failed to install KeePassXC"; return 1; }
    print_status "KeePassXC setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_keepassxc
fi