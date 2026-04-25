#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# VPN - Virtual Private Network clients for secure remote access.

_install_vpn_apps() {
    print_info "Installing VPN clients..."
    
    # Tunnelblick (OpenVPN client)
    brew install --cask tunnelblick
    
    # Proton VPN client
    brew install --cask protonvpn
}

setup_vpn() {
    print_info "Setting up VPN clients..."
    
    _install_vpn_apps
    
    print_info "--- Configuration ---"
    print_info "Import your VPN profile (.ovpn) into Tunnelblick or sign in to your Proton VPN account."
    
    print_info "--- Usage ---"
    print_info "Start: Open the installed VPN apps from Applications."
    
    print_status "VPN setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vpn
fi