if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_insync() {
    print_info "Installing insync tools..."
    brew install --cask insync
}

setup_insync() {
    print_info "Setting up insync..."

    _install_insync

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_insync
fi
