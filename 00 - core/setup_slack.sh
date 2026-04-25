#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_slack() {
    print_info "Installing Slack..."
    brew install --cask slack
}

verify_slack() {
    brew list --cask slack &>/dev/null
}

setup_slack() {
    print_info "Setting up Slack..."
    verify_slack || _install_slack || { print_error "Failed to install Slack"; return 1; }
    print_status "Slack setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_slack
fi