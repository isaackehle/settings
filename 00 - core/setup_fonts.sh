#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_fonts() {
    print_info "Installing fonts..."
    brew install fontconfig
    brew install font-hack-nerd-font
    brew install font-roboto font-roboto-mono font-roboto-slab
    brew install font-fira-code
}

verify_fonts() {
    brew list --formula fontconfig &>/dev/null && \
    brew list --formula font-hack-nerd-font &>/dev/null && \
    brew list --formula font-fira-code &>/dev/null
}

setup_fonts() {
    print_info "Setting up fonts..."
    verify_fonts || _install_fonts || { print_error "Failed to install fonts"; return 1; }
    print_status "Fonts setup complete. Start: Open terminal/editor preferences and choose the installed font."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_fonts
fi