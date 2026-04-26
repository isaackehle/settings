. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_go() {
    print_info "Installing Go..."
    brew install go && return 0
    return 1
}

verify_go() {
    check_tool_with_version "Go" "go"
}

setup_go() {
    print_info "Setting up Go..."

    verify_go || _install_go || { print_warning "Go not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Go ==="
    print_info "Version:       go version"
    print_info "Docs:          https://go.dev/doc/"
    print_info "Tour:          https://go.dev/tour/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_go
fi
