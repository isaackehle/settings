#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Tweaks - macOS system enhancements, utilities, and productivity tools.

_install_input_tools() {
    print_info "Installing mouse and input tools..."
    brew install bettertouchtool
    brew install --force steermouse
}

_install_cli_tools() {
    print_info "Installing CLI utility tools..."
    brew install tree pstree rename vim watch
}

_apply_system_tweaks() {
    print_info "Applying system tweaks..."
    # Prevent .DS_Store files from being written to network drives
    defaults write com.apple.desktopservices DSDontWriteNetworkStores true
}

_install_maintenance_compression() {
    print_info "Installing cleanup and compression tools..."
    brew install ccleaner appcleaner unrar the-unarchiver
}

_install_general_utilities() {
    print_info "Installing general utility apps..."
    brew install alfred path-finder xquartz flux spectacle disk-inventory-x mounty controlplane
}

setup_tweaks() {
    print_info "Setting up macOS tweaks and utilities..."
    
    _install_input_tools
    _install_cli_tools
    _apply_system_tweaks
    _install_maintenance_compression
    _install_general_utilities
    
    print_info "--- Manual Installation Reminders ---"
    print_info "The following require manual installation or App Store:"
    print_info "  - Amphetamine (App Store)"
    print_info "  - Cisco AnyConnect"
    print_info "  - MenuMeters"
    print_info "  - Microsoft Remote Desktop"
    print_info "  - Microsoft Office"
    print_info "  - Paragon NTFS"
    
    print_info "--- SteerMouse Tip ---"
    print_info "For scroll issues while middle-clicking: Wheel Mode -> Ratchet, uncheck Smooth Scroll."
    
    print_status "macOS tweaks and utilities setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_tweaks
fi