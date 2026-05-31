if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Install OpenAI Codex CLI.
setup_codex() {
    print_info "Installing Codex..."

    if command_exists "codex"; then
        local version
        version="$(codex --version 2>/dev/null || true)"
        if [ -n "$version" ]; then
            print_status "Codex already installed ($version)"
        else
            print_status "Codex already installed ($(command -v codex))"
        fi
        return 0
    fi

    if ! command_exists "npm"; then
        print_warning "npm not available — skipping Codex installation"
        print_info "Install manually with: npm install -g @openai/codex"
        return 1
    fi

    if install_via_npm "OpenAI Codex" "@openai/codex"; then
        return 0
    fi

    print_warning "Codex installation failed via npm."
    print_info "Manual install: npm install -g @openai/codex"
    print_info "Documentation: https://github.com/openai/codex"
    return 1
}

verify_codex() {
    command_exists "codex"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_codex
fi
