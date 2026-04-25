#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

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