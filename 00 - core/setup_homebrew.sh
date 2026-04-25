#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_homebrew() {
    print_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

verify_homebrew() {
    command -v brew &>/dev/null
}

setup_homebrew() {
    print_info "Setting up Homebrew..."
    verify_homebrew || _install_homebrew || { print_error "Failed to install Homebrew"; return 1; }
    
    print_info "Updating Homebrew..."
    brew update && brew upgrade
    
    print_status "Homebrew setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_homebrew
fi