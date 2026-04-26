. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_corepack() {
    print_info "Enabling Corepack..."
    corepack enable && return 0
    brew install corepack && corepack enable && return 0
    return 1
}

verify_corepack() {
    check_tool_with_version "Corepack" "corepack"
}

setup_corepack() {
    print_info "Setting up Corepack..."

    verify_corepack || _install_corepack || { print_warning "Corepack not available — skipping"; return 1; }

    print_info ""
    print_info "=== Corepack ==="
    print_info "Activate pnpm: corepack prepare pnpm@latest --activate"
    print_info "Activate yarn: corepack prepare yarn@4 --activate"
    print_info "Docs:          https://github.com/nodejs/corepack"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_corepack
fi
