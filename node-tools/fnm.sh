if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_fnm() {
    print_info "Installing FNM..."
    brew install fnm && return 0
    return 1
}

verify_fnm() {
    check_tool_with_version "FNM" "fnm"
}

setup_fnm() {
    print_info "Setting up FNM..."

    verify_fnm || _install_fnm || { print_warning "FNM not installed — skipping"; return 1; }

    print_info ""
    print_info "=== FNM ==="
    print_info "Add to ~/.zshrc:  eval \"\$(fnm env --use-on-cd --shell zsh)\""
    print_info "Install:       fnm install"
    print_info "Use:           fnm use"
    print_info "Install v20:   fnm install 20"
    print_info "Docs:          https://github.com/Schniz/fnm"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_fnm
fi
