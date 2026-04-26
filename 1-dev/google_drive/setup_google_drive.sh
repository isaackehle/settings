. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_google_drive() {
    print_info "Installing google drive sync tools..."
    brew install --cask google-drive
}

setup_google_drive() {
    print_info "Setting up google drive sync..."

    _install_google_drive

    print_info ""
    print_info "Start:         Open Google Drive from Applications"
    print_info "Google Drive:  https://workspace.google.com/products/drive/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_google_drive
fi
