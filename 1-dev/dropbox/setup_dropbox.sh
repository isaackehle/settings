if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_dropbox() {
    print_info "Installing dropbox..."
    brew install --cask dropbox
}

setup_dropbox() {
    print_info "Setting up dropbox..."

    _install_dropbox

}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_dropbox
fi
