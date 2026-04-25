#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# VNC - Remote desktop access using the VNC protocol.

_install_vnc_tools() {
    print_info "Installing VNC Viewer..."
    brew install --cask vnc-viewer
}

setup_vnc() {
    print_info "Setting up VNC connectivity..."
    
    _install_vnc_tools
    
    print_info "--- Configuration ---"
    print_info "macOS has a built-in VNC server."
    print_info "To enable: System Settings -> General -> Sharing -> Screen Sharing"
    print_info "Allow access for your user account in the sharing settings."
    
    print_info "--- Usage ---"
    print_info "Start: Open VNC Viewer from Applications to connect to remote hosts."
    
    print_status "VNC setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vnc
fi