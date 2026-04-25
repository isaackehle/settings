#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_arc() {
    print_info "Installing Arc..."
    brew install --cask arc
}

verify_arc() {
    brew list --cask arc &>/dev/null
}

setup_arc() {
    print_info "Setting up Arc..."
    verify_arc || _install_arc || { print_error "Failed to install Arc"; return 1; }
    print_status "Arc setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_arc
fi