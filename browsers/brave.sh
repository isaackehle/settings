#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_brave() {
    print_info "Installing Brave Browser..."
    brew install --cask brave-browser
}

verify_brave() {
    brew list --cask brave-browser &>/dev/null
}

setup_brave() {
    print_info "Setting up Brave Browser..."
    verify_brave || _install_brave || { print_error "Failed to install Brave Browser"; return 1; }
    print_status "Brave Browser setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_brave
fi