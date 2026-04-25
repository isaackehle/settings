#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_unsorted_packages() {
    print_info "Installing unsorted utility packages..."
    brew install coreutils findutils graphviz figlet grc imagemagick jq tldr moreutils mtr nmap rsync sqlite thefuck watch wget
}

verify_installations() {
    # Verify a few key packages from the list
    command -v jq &>/dev/null && command -v wget &>/dev/null && command -v nmap &>/dev/null
}

setup_installations() {
    print_info "Setting up unsorted installations..."
    verify_installations || _install_unsorted_packages || { print_error "Failed to install utility packages"; return 1; }
    print_status "Unsorted packages installation complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_installations
fi