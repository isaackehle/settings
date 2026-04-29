if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_apache() {
    print_info "Installing Apache HTTP Server..."
    brew install httpd && return 0
    return 1
}

verify_apache() {
    check_tool_with_version "Apache HTTP Server" "httpd"
}

setup_apache() {
    print_info "Setting up Apache HTTP Server..."

    verify_apache || _install_apache || { print_warning "Apache not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Apache HTTP Server ==="
    print_info "Start:         brew services start httpd"
    print_info "Stop:          brew services stop httpd"
    print_info "Config:        /opt/homebrew/etc/httpd/httpd.conf"
    print_info "Docs:          https://httpd.apache.org/docs/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_apache
fi
