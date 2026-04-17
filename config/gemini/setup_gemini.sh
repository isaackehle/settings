. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install Gemini CLI and write local-model env vars for LiteLLM routing.

_install_gemini() {
    if command_exists "npm"; then
        print_info "Installing @google/gemini-cli via npm..."
        install_via_npm "Google Gemini CLI" "@google/gemini-cli" && return 0
    fi
    print_warning "npm not available — install manually: npm install -g @google/gemini-cli"
    return 1
}

verify_gemini() {
    check_tool_with_version "Gemini CLI" "gemini"
}

setup_gemini() {
    print_info "Setting up Gemini CLI..."
    verify_gemini || _install_gemini || print_warning "Gemini CLI not installed — skipping"

    # Write env file for local-model mode via LiteLLM proxy
    local env_file
    if [ -n "$ZSH_VERSION" ]; then
        mkdir -p "$HOME/.zshrc.d"
        env_file="$HOME/.zshrc.d/_gemini"
    else
        mkdir -p "$HOME/.profile.d"
        env_file="$HOME/.profile.d/_gemini"
    fi

    cat > "$env_file" << 'EOF'
# Gemini CLI — route to local LiteLLM proxy (comment out to use real Gemini API)
# export GOOGLE_GEMINI_BASE_URL="http://localhost:4000"
# export GEMINI_API_KEY="sk-dummy"
EOF
    print_status "Gemini env stub written to $env_file (commented out by default)"

    print_info ""
    print_info "=== Gemini CLI ==="
    print_info "Cloud:   gemini  (sign in with Google or set GEMINI_API_KEY)"
    print_info "Local:   uncomment GOOGLE_GEMINI_BASE_URL in $env_file"
    print_info "         then: litellm --config ~/.config/litellm/litellm.yaml --port 4000"
    print_info "         then: gemini --sandbox=false"
    print_info "Docs:    https://github.com/google-gemini/gemini-cli"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gemini
fi