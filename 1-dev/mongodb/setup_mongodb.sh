. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_mongodb() {
    print_info "Installing MongoDB..."
    brew tap mongodb/brew \
        && brew install mongodb-community \
        && brew services start mongodb-community
}

verify_mongodb() {
    check_tool_with_version "MongoDB" "mongod"
}

setup_mongodb() {
    print_info "Setting up MongoDB..."

    verify_mongodb || _install_mongodb || { print_warning "MongoDB not installed — skipping"; return 1; }

    print_info ""
    print_info "=== MongoDB ==="
    print_info "Start:         brew services start mongodb-community"
    print_info "Stop:          brew services stop mongodb-community"
    print_info "Connect:       mongosh"
    print_info "GUI:           brew install --cask studio-3t"
    print_info "Docs:          https://www.mongodb.com/docs/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_mongodb
fi
