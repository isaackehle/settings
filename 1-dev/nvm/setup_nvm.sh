. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_nvm() {
    print_info "Installing NVM..."
    brew install nvm && mkdir -p ~/.nvm && return 0
    return 1
}

verify_nvm() {
    check_tool_with_version "NVM" "nvm"
}

setup_nvm() {
    print_info "Setting up NVM..."

    command_exists "nvm" || _install_nvm || { print_warning "NVM not installed — skipping"; return 1; }

    print_info ""
    print_info "=== NVM ==="
    print_info "Add to ~/.zshrc:"
    print_info "  export NVM_DIR=\"\$HOME/.nvm\""
    print_info "  source \$(brew --prefix nvm)/nvm.sh"
    print_info "Install LTS:   nvm install --lts"
    print_info "Use v20:       nvm install 20 && nvm use 20"
    print_info "Set default:   nvm alias default 20"
    print_info "Docs:          https://github.com/nvm-sh/nvm"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_nvm
fi
