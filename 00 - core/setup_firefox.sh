#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_firefox() {
    print_info "Installing Firefox..."
    brew install --cask firefox
}

verify_firefox() {
    brew list --cask firefox &>/dev/null
}

setup_firefox() {
    print_info "Setting up Firefox..."
    verify_firefox || _install_firefox || { print_error "Failed to install Firefox"; return 1; }
    print_status "Firefox setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_firefox
fi