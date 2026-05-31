#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_navicat() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install Navicat."
        return 1
    fi
    log_info "Installing Navicat Premium..."
    brew install --force navicat-premium
}

verify_navicat() {
    command_exists "navicat-premium"
}

setup_navicat() {
    log_info "Setting up Navicat Premium..."
    verify_navicat || _install_navicat || { log_error "Failed to install Navicat"; return 1; }
    log_info "Navicat Premium is ready."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_navicat
fi
