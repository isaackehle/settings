. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_volta() {
    print_info "Installing Volta..."
    curl https://get.volta.sh | bash && return 0
    brew install volta && volta setup && return 0
    return 1
}

verify_volta() {
    check_tool_with_version "Volta" "volta"
}

setup_volta() {
    print_info "Setting up Volta..."

    verify_volta || _install_volta || { print_warning "Volta not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Volta ==="
    print_info "Install Node:  volta install node"
    print_info "Install Yarn:  volta install yarn"
    print_info "Pin project:   volta pin node@20"
    print_info "Docs:          https://volta.sh/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_volta
fi
