. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

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
