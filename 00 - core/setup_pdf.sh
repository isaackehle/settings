#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_pdf_tools() {
    print_info "Installing PDF tools..."
    brew install --cask adobe-acrobat-reader pdf-expert
}

verify_pdf_tools() {
    [[ -d "/Applications/Adobe Acrobat Reader.app" ]] || [[ -d "/Applications/PDF Expert.app" ]]
}

setup_pdf() {
    print_info "Setting up PDF tools..."
    
    verify_pdf_tools || _install_pdf_tools || { print_error "Failed to install PDF tools"; return 1; }
    
    print_status "PDF tools setup complete. Start: Open the apps from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pdf
fi