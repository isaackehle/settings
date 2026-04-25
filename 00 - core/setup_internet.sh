#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_internet_tools() {
    print_info "Installing internet utilities..."
    brew install --cask wireshark
    brew install nmap mtr nikto dnsmap
}

verify_internet_tools() {
    command -v nmap &>/dev/null && command -v mtr &>/dev/null
}

setup_internet() {
    print_info "Setting up internet utilities..."
    verify_internet_tools || _install_internet_tools || { print_error "Failed to install internet utilities"; return 1; }
    print_status "Internet utilities setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_internet
fi