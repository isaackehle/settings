. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_git() {
    print_info "Installing Git and GitHub CLI..."
    brew install gh git-filter-repo \
        && gh auth login \
        && return 0
    return 1
}

_install_git_gui() {
    print_info "Installing Git GUI tools..."
    brew install --cask github
    brew install --cask sourcetree
}

verify_git() {
    check_tool_with_version "GitHub CLI" "gh"
}

setup_git() {
    print_info "Setting up Git..."

    verify_git || _install_git || { print_warning "GitHub CLI not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Git ==="
    print_info "Configure:     git config --global user.name 'Your Name'"
    print_info "               git config --global user.email 'you@example.com'"
    print_info "gh auth:       gh auth login"
    print_info "GUI tools:     brew install --cask github  (GitHub Desktop)"
    print_info "Docs:          https://cli.github.com/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_git
fi
