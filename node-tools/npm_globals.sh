if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_npm_globals() {
    if ! command_exists "npm"; then
        print_warning "npm not found — install Node.js via fnm or nvm first"
        return 1
    fi

    print_info "Installing global npm packages..."
    npm install -g npm-check-updates
    npm install -g rimraf
}

setup_npm_globals() {
    print_info "Setting up global npm packages..."

    _install_npm_globals

    print_info ""
    print_info "=== NPM Globals ==="
    print_info "List globals:  npm ls -g --depth 0"
    print_info "Check updates: ncu -g"
    print_info "TypeScript:    see ../typescript/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_npm_globals
fi
