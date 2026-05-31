#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_rancher_cli() {
    log_info "Installing Rancher CLI..."
    brew install rancher-cli && return 0
    return 1
}

verify_rancher_cli() {
    command -v rancher > /dev/null 2>&1
}

setup_rancher_cli() {
    log_info "Setting up Rancher CLI..."

    verify_rancher_cli || _install_rancher_cli || { log_warning "Rancher CLI not installed — skipping"; return 1; }

    log_info ""
    log_info "=== Rancher CLI ==="
    log_info "Login:     rancher login https://<server> --token <token>"
    log_info "Clusters:  rancher cluster list"
    log_info "Context:   rancher cluster switch <name>"
    log_info "Projects:  rancher project list"
    log_info "Docs:      https://rancher.com/docs/rancher/v2.x/en/cli/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_rancher_cli
fi
