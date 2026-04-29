if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_flutter() {
    print_info "Installing Flutter..."
    brew install flutter && return 0
    return 1
}

verify_flutter() {
    check_tool_with_version "Flutter" "flutter"
}

setup_flutter() {
    print_info "Setting up Flutter..."

    verify_flutter || _install_flutter || { print_warning "Flutter not installed — skipping"; return 1; }

    flutter doctor

    print_info ""
    print_info "=== Flutter ==="
    print_info "New project:   flutter create my_app"
    print_info "Run:           flutter run"
    print_info "Doctor:        flutter doctor"
    print_info "Docs:          https://flutter.dev/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_flutter
fi
