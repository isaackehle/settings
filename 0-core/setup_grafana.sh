#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_grafana() {
    print_info "Installing Grafana..."
    brew install grafana
}

verify_grafana() {
    brew list grafana &>/dev/null
}

setup_grafana() {
    print_info "Setting up Grafana..."
    verify_grafana || _install_grafana || { print_error "Failed to install Grafana"; return 1; }
    
    print_info "Starting Grafana service..."
    brew services start grafana
    
    print_status "Grafana setup complete. Access at http://localhost:3000"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_grafana
fi