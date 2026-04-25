#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_edge() {
    print_info "Installing Microsoft Edge..."
    brew install --cask microsoft-edge
}

verify_edge() {
    brew list --cask microsoft-edge &>/dev/null
}

setup_edge() {
    print_info "Setting up Microsoft Edge..."
    verify_edge || _install_edge || { print_error "Failed to install Microsoft Edge"; return 1; }
    print_status "Microsoft Edge setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_edge
fi