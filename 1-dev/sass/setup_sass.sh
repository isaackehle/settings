if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_sass() {
    install_via_npm "Sass" "sass"
}

verify_sass() {
    check_with_version_via_npm "Sass" "sass"
}

setup_sass() {
    print_info "Setting up Sass..."

    verify_sass || _install_sass || { print_warning "Sass not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Sass ==="
    print_info "Compile:       sass input.scss output.css"
    print_info "Watch:         sass --watch input.scss output.css"
    print_info "Docs:          https://sass-lang.com/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_sass
fi
