if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_omlx() {
    if ! command_exists "brew"; then
        log_error "Homebrew is required to install oMLX. Install Homebrew first."
        return 1
    fi
    log_info "Installing oMLX..."
    brew tap jundot/omlx https://github.com/jundot/omlx
    brew install omlx
}

verify_omlx() {
    check_tool_with_version "omlx" "0.0.0"
}

# Install oMLX and start the server.
setup_omlx() {
    log_info "Setting up oMLX..."

    verify_omlx || _install_omlx || { log_error "Failed to install oMLX"; return 1; }

    if curl -s http://localhost:8000/v1/models > /dev/null 2>&1; then
        log_info "oMLX server is already running."
    else
        log_info "Starting oMLX server..."
        if ! brew services start omlx; then
            log_warning "brew services start failed, attempting restart..."
            brew services restart omlx
        fi
    fi

    log_info "Verifying oMLX installation..."
    omlx --version
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_omlx
fi
