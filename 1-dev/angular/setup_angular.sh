if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_angular() {
    install_via_npm "Angular CLI" "@angular/cli"
}

verify_angular() {
    check_tool_with_version "Angular CLI" "ng"
}

setup_angular() {
    print_info "Setting up Angular CLI..."

    verify_angular || _install_angular || { print_warning "Angular CLI not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Angular CLI ==="
    print_info "New project:   ng new my-app"
    print_info "Serve:         ng serve"
    print_info "Docs:          https://angular.io/cli"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_angular
fi
