#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_ansible() {
    print_info "Installing Ansible..."
    brew install ansible
}

verify_ansible() {
    command_exists "ansible"
}

setup_ansible() {
    print_info "Setting up Ansible..."
    verify_ansible || _install_ansible || { print_error "Failed to install Ansible"; return 1; }
    print_status "Ansible setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ansible
fi