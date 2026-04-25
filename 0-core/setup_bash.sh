#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Bash - Install modern Bash via Homebrew to replace the legacy macOS version.

_install_bash() {
    print_info "Installing modern Bash via Homebrew..."
    brew install bash
}

_configure_bash_preference() {
    print_info "Configuring Bash as the primary choice..."
    
    # Homebrew bash is installed to /opt/homebrew/bin/bash (Apple Silicon)
    # To make it the primary choice for hash bangs, we recommend using:
    # #!/usr/bin/env bash
    # instead of #!/bin/bash
    
    if [[ -f "$HOME/.zshrc" ]]; then
        # Ensure Homebrew's bin is at the front of the PATH in Zsh
        if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' "$HOME/.zshrc"; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zshrc"
        fi
    fi
}

setup_bash() {
    print_info "Setting up modern Bash..."
    
    _install_bash
    _configure_bash_preference
    
    print_info "--- Configuration ---"
    print_info "Modern Bash is installed via Homebrew."
    print_info "To ensure your scripts use this version instead of the legacy macOS bash (/bin/bash),"
    print_info "always use the following shebang at the top of your scripts:"
    print_info '  #!/usr/bin/env bash'
    
    print_status "Bash setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_bash
fi