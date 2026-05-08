if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Set up GitHub Copilot — VS Code extension + gh CLI extension.

EXTENSION_NAME="copilot-cli"

_install_copilot_cli() {
    print_info "Installing ${EXTENSION_NAME} via brew..."
    brew install "${EXTENSION_NAME}" && return 0
    print_warning "brew install failed — install manually: https://github.com/features/copilot/cli/"
    return 1
}


verify_github_cli() {
    # Check if GH extension is installed
    if gh_extension_exists "github/gh-copilot"; then
        print_status "gh-copilot extension installed"
        return 0
    fi

    # Check if brew package is installed
    if [[ -n "$(check_with_version_via_brew "$EXTENSION_NAME")" ]]; then
        print_status "copilot-cli brew package installed"
        return 0
    fi

    print_warning "GitHub Copilot CLI not found (neither gh extension nor brew package)"
    return 1
}


# _install_copilot_extension() {
#     # print_info "Installing copilot-cli via brew..."
#     # brew install copilot-cli && return 0
#     # print_warning "brew install failed — install manually: https://github.com/features/copilot/cli/"

#     if command_exists "gh"; then
#         print_info "Installing gh copilot extension..."
#         gh extension install github/gh-copilot && \
#             print_status "gh copilot extension installed" || \
#             print_warning "gh extension install failed — try: gh extension install github/gh-copilot"
#     else
#         print_warning "GitHub CLI (gh) not found — install with: brew install gh"
#     fi

#     if command_exists "code"; then
#         print_info "Installing GitHub Copilot VS Code extension..."
#         code --install-extension GitHub.copilot
#         code --install-extension GitHub.copilot-chat
#         print_status "GitHub Copilot extensions installed"
#     else
#         print_warning "VS Code CLI (code) not found — install extensions from Marketplace"
#     fi
#     return 1
# }

# verify_copilot_extension() {
#     if command_exists "gh" && gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
#         print_status "gh-copilot extension installed"
#         return 0
#     fi
#     print_warning "gh copilot extension not installed"
#     return 1
# }

setup_github_copilot() {
    print_info "Setting up GitHub Copilot CLI..."

    # verify_copilot_extension || _install_copilot_extension || { print_error "Failed to install GitHub Copilot extension"; }
    verify_github_cli || _install_copilot_cli || { print_error "Failed to install GitHub Copilot CLI"; }

    print_info ""
    print_info "=== GitHub Copilot ==="
    print_info "CLI:        gh copilot suggest <task>"
    print_info "CLI:        gh copilot explain <command>"
    # print_info "Ollama:     VS Code Copilot Chat → Add Models → Ollama (requires v0.18.3+)"
    print_info "Docs:       https://docs.github.com/en/copilot"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_github_copilot
fi
