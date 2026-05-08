#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_proton_pass() {
    print_info "Installing Proton Pass..."
    brew install --cask proton-pass
}

verify_proton_pass() {
    brew list --cask proton-pass &>/dev/null
}

setup_proton_pass() {
    print_info "Setting up Proton Pass..."
    verify_proton_pass || _install_proton_pass || { print_error "Failed to install Proton Pass"; return 1; }
    print_status "Proton Pass setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_proton_pass
fi