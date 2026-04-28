#!/opt/homebrew/bin/bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Set up Cline — autonomous AI coding agent for VS Code.
# The VS Code extension (saoudrizwan.claude-dev) is the primary install.
# The optional npm package provides a CLI wrapper.

_install_cline_cli() {
    if command_exists "npm"; then
        log_info "Installing cline CLI via npm..."

        if npm install -g cline --silent; then
            log_success "cline cli installed successfully via npm"
            return 0
        else
            log_error "npm installation failed for cline cli"
            return 1
        fi
    fi

    log_warning "npm not available — skipping Cline CLI install"
    return 1
}

verify_cline_cli() {
    if command_exists "cline" && code --list-extensions 2>/dev/null | grep -q "saoudrizwan.claude-dev"; then
        log_status "Cline cli installed"
        return 0
    fi

    log_warning "Cline cli not found"
    return 1
}

_install_cline_extension() {
    if command_exists "code"; then
        log_info "Installing Cline VS Code extension..."
        code --install-extension saoudrizwan.claude-dev && \
            log_status "Cline extension installed" && \
            return 0

        log_warning "Extension install failed — install manually from VS Code Marketplace"
        return 1
    fi

    log_warning "VS Code CLI (code) not found — install Cline from VS Code Marketplace"
    return 1
}

verify_cline_extension() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -q "saoudrizwan.claude-dev"; then
        log_status "Cline VS Code extension installed"
        return 0
    fi
    log_warning "Cline VS Code extension not found (saoudrizwan.claude-dev)"
    return 1
}

setup_cline() {
    log_info "Setting up Cline..."

    if command_exists "code"; then
        log_info "Installing Cline VS Code extension..."
        code --install-extension saoudrizwan.claude-dev && \
            log_status "Cline extension installed" || \
            log_warning "Extension install failed — install manually from VS Code Marketplace"
    else
        log_warning "VS Code CLI (code) not found — install Cline from VS Code Marketplace"
    fi

    verify_cline_extension || _install_cline_extension || log_warning "Cline VS Code extension not installed"
    verify_cline_cli || _install_cline_cli || log_warning "Cline cli not installed"

    log_info ""
    log_info "=== Cline VS Code Extenstion setup ==="
    log_info "Extension:  saoudrizwan.claude-dev"
    log_info "Configure:  Cline panel → Settings → API Provider"
    log_info "LiteLLM:    API Provider = OpenAI Compatible, Base URL = http://localhost:4000/v1"
    log_info "Model:      qwen3-coder-30b:q6-32k (64GB) / qwen3:14b (16GB)"
    log_info "Docs:       https://docs.cline.bot"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_cline
fi
