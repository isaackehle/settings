if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_bun() {
    print_info "Installing Bun..."
    brew tap oven-sh/bun && brew install bun && return 0
    curl -fsSL https://bun.sh/install | bash && return 0
    return 1
}

verify_bun() {
    check_tool_with_version "Bun" "bun"
}

setup_bun() {
    print_info "Setting up Bun..."

    verify_bun || _install_bun || { print_warning "Bun not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Bun ==="
    print_info "Install deps:  bun install"
    print_info "Add package:   bun add <pkg>"
    print_info "Run script:    bun run build"
    print_info "Docs:          https://bun.sh/docs"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_bun
fi
