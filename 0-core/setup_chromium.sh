#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_chromium() {
    print_info "Installing Chromium..."
    brew install --cask chromium
}

verify_chromium() {
    brew list --cask chromium &>/dev/null
}

setup_chromium() {
    print_info "Setting up Chromium..."
    verify_chromium || _install_chromium || { print_error "Failed to install Chromium"; return 1; }
    print_status "Chromium setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_chromium
fi