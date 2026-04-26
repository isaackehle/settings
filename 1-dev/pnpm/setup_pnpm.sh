. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_pnpm() {
    print_info "Installing pnpm..."
    brew install pnpm && return 0
    corepack enable pnpm && return 0
    return 1
}

verify_pnpm() {
    check_tool_with_version "pnpm" "pnpm"
}

setup_pnpm() {
    print_info "Setting up pnpm..."

    verify_pnpm || _install_pnpm || { print_warning "pnpm not installed — skipping"; return 1; }

    print_info ""
    print_info "=== pnpm ==="
    print_info "Install deps:  pnpm install"
    print_info "Add package:   pnpm add <pkg>"
    print_info "Run script:    pnpm run build"
    print_info "Docs:          https://pnpm.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pnpm
fi
