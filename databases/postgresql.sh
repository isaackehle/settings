if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_postgresql() {
    print_info "Installing PostgreSQL..."
    brew install postgresql@14 \
        && brew services start postgresql@14 \
        && /opt/homebrew/opt/postgresql@14/bin/createuser -s postgres 2>/dev/null || true
}

verify_postgresql() {
    check_tool_with_version "PostgreSQL" "psql"
}

setup_postgresql() {
    print_info "Setting up PostgreSQL..."

    verify_postgresql || _install_postgresql || { print_warning "PostgreSQL not installed — skipping"; return 1; }

    print_info ""
    print_info "=== PostgreSQL ==="
    print_info "Start:         brew services start postgresql@14"
    print_info "Stop:          brew services stop postgresql@14"
    print_info "Connect:       psql -U postgres"
    print_info "Docs:          https://www.postgresql.org/docs/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_postgresql
fi
