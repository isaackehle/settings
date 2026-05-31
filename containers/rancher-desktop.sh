#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_rancher_desktop() {
    log_info "Installing Rancher Desktop..."
    brew install --cask rancher && return 0
    return 1
}

verify_rancher_desktop() {
    check_tool_with_version "Rancher Desktop" "rdctl"
}

setup_rancher_desktop() {
    log_info "Setting up Rancher Desktop..."

    verify_rancher_desktop || _install_rancher_desktop || { log_warning "Rancher Desktop not installed — skipping"; return 1; }

    log_info ""
    log_info "=== Rancher Desktop ==="
    log_info "Launch:        Open Rancher Desktop from Applications"
    log_info "Cluster info:  kubectl cluster-info"
    log_info "Get nodes:     kubectl get nodes"
    log_info "Docs:          https://docs.rancherdesktop.io/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_rancher_desktop
fi
