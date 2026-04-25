#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# SSH - Secure Shell for encrypted remote connections.

_install_ssh() {
    print_info "Installing OpenSSH and related tools..."
    brew install openssh openssl openssl@1.1 ssh-copy-id
}

verify_ssh() {
    command -v ssh &>/dev/null
}

setup_ssh() {
    print_info "Setting up SSH..."
    
    verify_ssh || _install_ssh || { print_error "Failed to install SSH tools"; return 1; }
    
    print_status "SSH tools setup complete."
    print_info "Manual Configuration:"
    print_info "  - Generate key: ssh-keygen -t ed25519 -C \"your_email@example.com\""
    print_info "  - Copy key: ssh-copy-id \$(whoami)@hostname"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ssh
fi