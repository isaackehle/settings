#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

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