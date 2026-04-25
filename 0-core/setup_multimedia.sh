#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_multimedia_casks() {
    print_info "Installing multimedia GUI applications..."
    brew install --cask gimp inkscape omnigraffle colorsnapper handbrake vlc kodi burn spotify amazon-music mp3tag
}

_install_multimedia_formulae() {
    print_info "Installing multimedia CLI tools..."
    brew install imagemagick ffmpeg id3-editor x264 webp grc
}

verify_multimedia() {
    command -v ffmpeg &>/dev/null && command -v imagemagick &>/dev/null
}

setup_multimedia() {
    print_info "Setting up multimedia tools..."
    
    verify_multimedia || {
        _install_multimedia_casks || { print_error "Failed to install multimedia casks"; return 1; }
        _install_multimedia_formulae || { print_error "Failed to install multimedia formulae"; return 1; }
    }
    
    print_status "Multimedia tools setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_multimedia
fi