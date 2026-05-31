#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Virtual Machines - Run other operating systems on macOS.

_install_vm_apps() {
    print_info "Installing Virtual Machine applications..."

    # UTM — native Apple Silicon VM app (free)
    brew install --cask utm

    # VMware Fusion — commercial, strong Apple Silicon support
    brew install --cask vmware-fusion

    # Parallels Desktop — commercial, polished macOS integration
    brew install --cask parallels

    # VirtualBox — free, open-source (best on Intel / limited on Apple Silicon)
    brew install --cask virtualbox
}

setup_vm() {
    print_info "Setting up Virtualization tools..."

    _install_vm_apps

    print_info "--- Usage ---"
    print_info "Start: Open the installed VM apps from Applications."

    print_status "Virtual Machine setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vm
fi