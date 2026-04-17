. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up Cline — autonomous AI coding agent for VS Code.
# The VS Code extension (saoudrizwan.claude-dev) is the primary install.
# The optional npm package provides a CLI wrapper.

_install_cline_npm() {
    if command_exists "npm"; then
        print_info "Installing cline CLI via npm..."
        install_via_npm "Cline" "cline" && return 0
    fi
    print_warning "npm not available — skipping Cline CLI install"
    return 1
}

verify_cline() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -q "saoudrizwan.claude-dev"; then
        print_status "Cline VS Code extension installed"
        return 0
    fi
    print_warning "Cline VS Code extension not found (saoudrizwan.claude-dev)"
    return 1
}

setup_cline() {
    print_info "Setting up Cline..."

    if command_exists "code"; then
        print_info "Installing Cline VS Code extension..."
        code --install-extension saoudrizwan.claude-dev && \
            print_status "Cline extension installed" || \
            print_warning "Extension install failed — install manually from VS Code Marketplace"
    else
        print_warning "VS Code CLI (code) not found — install Cline from VS Code Marketplace"
    fi

    _install_cline_npm || true

    print_info ""
    print_info "=== Cline setup ==="
    print_info "Extension:  saoudrizwan.claude-dev"
    print_info "Configure:  Cline panel → Settings → API Provider"
    print_info "Ollama:     API Provider = OpenAI Compatible, Base URL = http://localhost:11434/v1"
    print_info "Docs:       https://docs.cline.bot"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_cline
fi
