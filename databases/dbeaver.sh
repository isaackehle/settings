#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_dbeaver() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install DBeaver."
        return 1
    fi
    log_info "Installing DBeaver Community..."
    brew install --cask dbeaver-community
}

verify_dbeaver() {
    command_exists "dbeaver" || [ -d "/Applications/DBeaver.app" ]
}

setup_dbeaver() {
    log_info "Setting up DBeaver..."
    verify_dbeaver || _install_dbeaver || { log_error "Failed to install DBeaver"; return 1; }
    log_info "DBeaver is ready."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_dbeaver
fi
