if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Install Codex (try npm first, fallback to manual)
setup_codex() {
    log_info "Installing Codex..."

    # Try npm installation first
    if command_exists "npm"; then
        log_info "Attempting npm install..."

        # Try npm installation first
        if install_via_npm "OpenAI Codex" "@openai/codex"; then
            return 0
        fi

        if install_via_npm "AI SDK Codex" "@ai-sdk/codex"; then
            return 0
        fi

        # Try alternative package names
        if install_via_npm "Codex" "codex"; then
            return 0
        fi

    else
        log_warning "npm not available - skipping npm installation"
    fi

    # Try alternative methods or provide instructions
    log_info "Please manually install Codex from:"
    log_info "  https://github.com/codex-ai/codex"
    log_info "  Documentation: https://docs.codex.ai/"
    return 1
}

verify_codex() {
    check_tool_with_version "Codex" "codex"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_codex
fi
