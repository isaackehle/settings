#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_iterm() {
    print_info "Installing iTerm2..."
    brew install --cask iterm2
}

_install_starship() {
    print_info "Installing Starship prompt..."
    brew install starship
    if ! grep -q 'starship init zsh' ~/.zshrc; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
        print_info "Added Starship init to ~/.zshrc"
    fi
}

verify_iterm() {
    # iTerm2 is a cask, check if the app exists
    [[ -d "/Applications/iTerm.app" ]]
}

verify_starship() {
    command -v starship &>/dev/null
}

setup_iterm() {
    print_info "Setting up iTerm2 and Starship..."
    
    verify_iterm || _install_iterm || { print_error "Failed to install iTerm2"; return 1; }
    verify_starship || _install_starship || { print_error "Failed to install Starship"; return 1; }
    
    print_status "iTerm2 and Starship setup complete. Start: Open iTerm2 from Applications."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_iterm
fi