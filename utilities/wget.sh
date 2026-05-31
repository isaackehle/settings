#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_wget() {
    print_info "Installing wget..."
    brew install wget
}

verify_wget() {
    command -v wget &>/dev/null
}

setup_wget() {
    print_info "Setting up wget..."
    verify_wget || _install_wget || { print_error "Failed to install wget"; return 1; }
    print_status "wget setup complete. Usage: wget --help"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_wget
fi