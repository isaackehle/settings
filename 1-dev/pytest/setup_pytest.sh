if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_pytest() {
    print_info "Installing pytest..."
    pip install pytest pytest-cov && return 0
    return 1
}

verify_pytest() {
    check_tool_with_version "pytest" "pytest"
}

setup_pytest() {
    print_info "Setting up pytest..."

    verify_pytest || _install_pytest || { print_warning "pytest not installed — skipping"; return 1; }

    print_info ""
    print_info "=== pytest ==="
    print_info "Run all:       pytest"
    print_info "Verbose:       pytest -v"
    print_info "With coverage: pytest --cov=src --cov-report=term-missing"
    print_info "Match name:    pytest -k 'test_login'"
    print_info "Docs:          https://docs.pytest.org/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pytest
fi
