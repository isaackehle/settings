if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_elixir() {
    print_info "Installing Elixir..."
    brew install elixir && return 0
    return 1
}

verify_elixir() {
    check_tool_with_version "Elixir" "elixir"
}

setup_elixir() {
    print_info "Setting up Elixir..."

    verify_elixir || _install_elixir || { print_warning "Elixir not installed — skipping"; return 1; }

    mix local.hex --force

    print_info ""
    print_info "=== Elixir ==="
    print_info "REPL:          iex"
    print_info "Docs:          https://hexdocs.pm/elixir/introduction.html"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_elixir
fi
