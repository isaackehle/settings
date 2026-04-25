#!/bin/bash
. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

_install_prometheus() {
    print_info "Installing Prometheus..."
    brew install prometheus
}

verify_prometheus() {
    brew list prometheus &>/dev/null
}

setup_prometheus() {
    print_info "Setting up Prometheus..."
    verify_prometheus || _install_prometheus || { print_error "Failed to install Prometheus"; return 1; }
    
    print_info "Starting Prometheus service..."
    brew services start prometheus
    
    print_status "Prometheus setup complete. Access at http://localhost:9090"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_prometheus
fi