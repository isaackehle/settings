if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_julia() {
    print_info "Installing Julia..."
    brew install julia && return 0
    return 1
}

verify_julia() {
    check_tool_with_version "Julia" "julia"
}

setup_julia() {
    print_info "Setting up Julia..."

    verify_julia || _install_julia || { print_warning "Julia not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Julia ==="
    print_info "REPL:          julia"
    print_info "Docs:          https://docs.julialang.org/en/v1/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_julia
fi
