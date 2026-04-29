if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_pipenv() {
    print_info "Installing pipenv..."
    brew install pipenv && return 0
    pip install --user pipenv && return 0
    return 1
}

verify_pipenv() {
    check_tool_with_version "pipenv" "pipenv"
}

setup_pipenv() {
    print_info "Setting up pipenv..."

    verify_pipenv || _install_pipenv || { print_warning "pipenv not installed — skipping"; return 1; }

    print_info ""
    print_info "=== pipenv ==="
    print_info "Init env:      pipenv --python 3.13"
    print_info "Install:       pipenv install"
    print_info "Dev deps:      pipenv install --dev pytest pytest-cov"
    print_info "Shell:         pipenv shell"
    print_info "Run tests:     pipenv run pytest"
    print_info "Docs:          https://pipenv.pypa.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pipenv
fi
