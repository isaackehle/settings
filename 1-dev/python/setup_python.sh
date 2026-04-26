. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_python() {
    print_info "Installing pyenv..."
    brew install xz pyenv && return 0
    return 1
}

verify_python() {
    check_tool_with_version "pyenv" "pyenv"
}

setup_python() {
    print_info "Setting up Python..."

    verify_python || _install_python || { print_warning "pyenv not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Python / pyenv ==="
    print_info "Add to ~/.zshrc:"
    print_info "  if command -v pyenv 1>/dev/null 2>&1; then"
    print_info "    eval \"\$(pyenv init --path)\""
    print_info "    eval \"\$(pyenv init -)\""
    print_info "  fi"
    print_info "List versions: pyenv install --list"
    print_info "Install:       pyenv install 3.14.4"
    print_info "Set global:    pyenv global 3.14.4"
    print_info "Set local:     pyenv local 3.11.9"
    print_info "Docs:          https://github.com/pyenv/pyenv"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_python
fi
