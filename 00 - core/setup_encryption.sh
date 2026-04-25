#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_encryption_tools() {
    print_info "Installing encryption tools (mcrypt, md5sha1sum, mhash)..."
    brew install mcrypt
    brew install md5sha1sum
    brew install mhash
}

verify_encryption_tools() {
    command -v mcrypt &>/dev/null && \
    command -v md5sha1sum &>/dev/null && \
    command -v mhash &>/dev/null
}

setup_encryption() {
    print_info "Setting up encryption tools..."
    verify_encryption_tools || _install_encryption_tools || { print_error "Failed to install encryption tools"; return 1; }
    print_status "Encryption tools setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_encryption
fi