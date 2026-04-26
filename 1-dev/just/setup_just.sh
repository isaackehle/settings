. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_just() {
    print_info "Installing Just..."
    brew install just && return 0
    return 1
}

verify_just() {
    check_tool_with_version "Just" "just"
}

setup_just() {
    print_info "Setting up Just..."

    verify_just || _install_just || { print_warning "Just not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Just ==="
    print_info "Run recipe:    just <recipe-name>"
    print_info "List recipes:  just --list"
    print_info "Docs:          https://just.systems"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_just
fi
