#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_teams() {
    print_info "Installing Microsoft Teams..."
    brew install --cask microsoft-teams
}

verify_teams() {
    brew list --cask microsoft-teams &>/dev/null
}

setup_teams() {
    print_info "Setting up Microsoft Teams..."
    verify_teams || _install_teams || { print_error "Failed to install Microsoft Teams"; return 1; }
    print_status "Microsoft Teams setup complete. Start: Open the app from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_teams
fi