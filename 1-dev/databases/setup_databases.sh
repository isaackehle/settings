. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_gui_tools() {
    print_info "Installing database GUI tools..."
    brew install --force navicat-premium
    brew install --cask studio-3t
    brew install --cask dbeaver-community
}

setup_databases() {
    print_info "Setting up database GUI tools..."

    _install_gui_tools

    print_info ""
    print_info "=== Database GUI Tools ==="
    print_info "Navicat:       brew install --force navicat-premium"
    print_info "Studio 3T:     brew install --cask studio-3t"
    print_info "dBeaver:       brew install --cask dbeaver-community"
    print_info "PostgreSQL:    see ../postgresql/"
    print_info "MongoDB:       see ../mongodb/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_databases
fi
