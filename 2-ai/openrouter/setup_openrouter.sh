if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"
. "${SETTINGS_BASE}/utils.sh"

# Set up OpenRouter — unified API key env var for the openrouter.ai gateway.

setup_openrouter() {
    log_info "Setting up OpenRouter..."

    local env_file="$HOME/.env.local"

    if grep -q "OPENROUTER_API_KEY" "$env_file" 2>/dev/null; then
        log_success "OPENROUTER_API_KEY already present in $env_file"
    else
        log_warning "OPENROUTER_API_KEY not found in $env_file"
        log_info "Add your key to $env_file:"
        log_info "  OPENROUTER_API_KEY=sk-or-..."
        log_info "Get a key at: https://openrouter.ai/keys"
    fi

    log_info ""
    log_info "=== OpenRouter ==="
    log_info "Base URL:  https://openrouter.ai/api/v1"
    log_info "Models:    https://openrouter.ai/models"
    log_info "Docs:      https://openrouter.ai/docs"
    log_info ""
    log_info "Use with Claude Code:"
    log_info "  ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1 \\"
    log_info "  ANTHROPIC_API_KEY=\$OPENROUTER_API_KEY \\"
    log_info "  claude"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_openrouter
fi
