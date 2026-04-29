if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_typescript() {
    install_via_npm "TypeScript" "typescript"
}

verify_typescript() {
    check_tool_with_version "TypeScript" "tsc"
}

setup_typescript() {
    print_info "Setting up TypeScript..."

    verify_typescript || _install_typescript || { print_warning "TypeScript not installed — skipping"; return 1; }

    print_info ""
    print_info "=== TypeScript ==="
    print_info "Init tsconfig: tsc --init"
    print_info "Compile:       tsc"
    print_info "Docs:          https://www.typescriptlang.org/docs/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_typescript
fi
