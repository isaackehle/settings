. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up GitHub Copilot — VS Code extension + gh CLI extension.

verify_github_copilot() {
    if command_exists "gh" && gh extension list 2>/dev/null | grep -q "github/gh-copilot"; then
        print_status "gh-copilot extension installed"
        return 0
    fi
    print_warning "gh copilot extension not installed"
    return 1
}

setup_github_copilot() {
    print_info "Setting up GitHub Copilot..."

    if command_exists "gh"; then
        print_info "Installing gh copilot extension..."
        gh extension install github/gh-copilot && \
            print_status "gh copilot extension installed" || \
            print_warning "gh extension install failed — try: gh extension install github/gh-copilot"
    else
        print_warning "GitHub CLI (gh) not found — install with: brew install gh"
    fi

    if command_exists "code"; then
        print_info "Installing GitHub Copilot VS Code extension..."
        code --install-extension GitHub.copilot
        code --install-extension GitHub.copilot-chat
        print_status "GitHub Copilot extensions installed"
    else
        print_warning "VS Code CLI (code) not found — install extensions from Marketplace"
    fi

    print_info ""
    print_info "=== GitHub Copilot ==="
    print_info "CLI:        gh copilot suggest <task>"
    print_info "CLI:        gh copilot explain <command>"
    print_info "Ollama:     VS Code Copilot Chat → Add Models → Ollama (requires v0.18.3+)"
    print_info "Docs:       https://docs.github.com/en/copilot"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_github_copilot
fi
