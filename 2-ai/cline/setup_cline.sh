#!/opt/homebrew/bin/bash

. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up Cline — autonomous AI coding agent for VS Code.
# The VS Code extension (saoudrizwan.claude-dev) is the primary install.
# The optional npm package provides a CLI wrapper.

_install_cline_cli() {
    if command_exists "npm"; then
        print_info "Installing cline CLI via npm..."

        if npm install -g cline --silent; then
            print_success "cline cli installed successfully via npm"
            return 0
        else
            print_error "npm installation failed for cline cli"
            return 1
        fi
    fi

    print_warning "npm not available — skipping Cline CLI install"
    return 1
}

verify_cline_cli() {
    if command_exists "cline" && code --list-extensions 2>/dev/null | grep -q "saoudrizwan.claude-dev"; then
        print_status "Cline cli installed"
        return 0
    fi

    print_warning "Cline cli not found"
    return 1
}

_install_cline_extension() {
    if command_exists "code"; then
        print_info "Installing Cline VS Code extension..."
        code --install-extension saoudrizwan.claude-dev && \
            print_status "Cline extension installed" \\
            return 0


        print_warning "Extension install failed — install manually from VS Code Marketplace"
        return 1

    fi

    print_warning "VS Code CLI (code) not found — install Cline from VS Code Marketplace"
    return 1

}

verify_cline_extension() {
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

    verify_cline_extension || _install_cline_extension || print_warning "Cline VS Code extension not installed"
    verify_cline_cli || _install_cline_cli || print_warning "Cline cli not installed"

    print_info ""
    print_info "=== Cline VS Code Extenstion setup ==="
    print_info "Extension:  saoudrizwan.claude-dev"
    print_info "Configure:  Cline panel → Settings → API Provider"
    print_info "LiteLLM:    API Provider = OpenAI Compatible, Base URL = http://localhost:4000/v1"
    print_info "Model:      qwen3-coder-30b:q6-32k (64GB) / qwen3:14b (16GB)"
    print_info "Docs:       https://docs.cline.bot"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_cline
fi
