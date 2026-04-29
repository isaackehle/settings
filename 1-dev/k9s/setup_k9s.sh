if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_k9s() {
    print_info "Installing K9s..."
    brew install derailed/k9s/k9s && return 0
    return 1
}

verify_k9s() {
    check_tool_with_version "K9s" "k9s"
}

setup_k9s() {
    print_info "Setting up K9s..."

    verify_k9s || _install_k9s || { print_warning "K9s not installed — skipping"; return 1; }

    print_info ""
    print_info "=== K9s ==="
    print_info "Launch:        k9s"
    print_info "With context:  k9s --context my-cluster"
    print_info "Keybindings:   ? (in K9s)"
    print_info "Docs:          https://k9scli.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_k9s
fi
