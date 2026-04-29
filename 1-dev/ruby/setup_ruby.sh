if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_ruby() {
    print_info "Installing Ruby via RVM..."
    curl -sSL https://get.rvm.io | bash -s stable --ruby && return 0
    return 1
}

verify_ruby() {
    check_tool_with_version "Ruby" "ruby"
}

setup_ruby() {
    print_info "Setting up Ruby..."

    verify_ruby || _install_ruby || { print_warning "Ruby not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Ruby / RVM ==="
    print_info "Install v3.2:  rvm install 3.2"
    print_info "Use:           rvm use 3.2 --default"
    print_info "List:          rvm list"
    print_info "Docs:          https://rvm.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_ruby
fi
