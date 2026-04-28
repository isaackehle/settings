if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Set up Perplexity API — adds API key env var for the Perplexity cloud inference API.

setup_perplexity() {
    print_info "Setting up Perplexity..."

    local env_file="$HOME/.env.local"

    if grep -q "PERPLEXITY_API_KEY" "$env_file" 2>/dev/null; then
        print_status "PERPLEXITY_API_KEY already present in $env_file"
    else
        print_warning "PERPLEXITY_API_KEY not found in $env_file"
        print_info "Add your key to $env_file:"
        print_info "  PERPLEXITY_API_KEY=pplx-..."
        print_info "Get a key at: https://console.perplexity.ai"
    fi

    print_info ""
    print_info "=== Perplexity API ==="
    print_info "Base URL:  https://api.perplexity.ai"
    print_info "OpenAI-compatible endpoint (use with any OpenAI SDK)"
    print_info "Models:    sonar, sonar-pro, sonar-reasoning, sonar-reasoning-pro"
    print_info "Docs:      https://docs.perplexity.ai"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_perplexity
fi
