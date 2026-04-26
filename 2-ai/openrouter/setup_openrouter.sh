. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up OpenRouter — unified API key env var for the openrouter.ai gateway.

setup_openrouter() {
    print_info "Setting up OpenRouter..."

    local env_file="$HOME/.env.local"

    if grep -q "OPENROUTER_API_KEY" "$env_file" 2>/dev/null; then
        print_status "OPENROUTER_API_KEY already present in $env_file"
    else
        print_warning "OPENROUTER_API_KEY not found in $env_file"
        print_info "Add your key to $env_file:"
        print_info "  OPENROUTER_API_KEY=sk-or-..."
        print_info "Get a key at: https://openrouter.ai/keys"
    fi

    print_info ""
    print_info "=== OpenRouter ==="
    print_info "Base URL:  https://openrouter.ai/api/v1"
    print_info "Models:    https://openrouter.ai/models"
    print_info "Docs:      https://openrouter.ai/docs"
    print_info ""
    print_info "Use with Claude Code:"
    print_info "  ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1 \\"
    print_info "  ANTHROPIC_API_KEY=\$OPENROUTER_API_KEY \\"
    print_info "  claude"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_openrouter
fi
