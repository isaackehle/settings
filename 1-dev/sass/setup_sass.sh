. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_sass() {
    install_via_npm "Sass" "sass"
}

verify_sass() {
    check_tool_with_version "Sass" "sass"
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
