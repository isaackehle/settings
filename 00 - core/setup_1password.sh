#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_1password() {
    print_info "Installing 1Password app and CLI..."
    brew install --cask 1password
    brew install 1password-cli
}

verify_1password() {
    # Verify both the app cask and the cli tool
    brew list --cask 1password &>/dev/null && command_exists "op"
}

setup_1password() {
    print_info "Setting up 1Password..."
    verify_1password || _install_1password || { print_error "Failed to install 1Password"; return 1; }
    print_status "1Password setup complete. Please set up your vaults on first launch."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_1password
fi