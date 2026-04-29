if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Install Gemini CLI and write local-model env vars for LiteLLM routing.

_install_gemini() {
    if command_exists "npm"; then
        print_info "Installing Google Gemini CLI via npm..."
        install_via_npm "Google Gemini CLI" "@google/gemini-cli" && return 0
    fi
    print_warning "npm not available — install manually: npm install -g @google/gemini-cli"
    return 1
}

verify_gemini() {
    check_with_version_via_npm "Gemini CLI" "@google/gemini-cli"
}

setup_gemini() {
    print_info "Setting up Gemini CLI..."
    verify_gemini || _install_gemini || print_warning "Gemini CLI not installed — skipping"

    # Deploy machine-specific settings.json
    local src_cfg mac_model gemini_cfg_dir="$HOME/.gemini"

    if declare -f find_source > /dev/null 2>&1; then
        src_cfg=$(find_source "gemini/settings.json")
    fi
    if [ -z "$src_cfg" ]; then
        mac_model="$(_detect_profile)"
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/$mac_model/gemini/settings.json"
    fi

    if [ -f "$src_cfg" ]; then
        mkdir -p "$gemini_cfg_dir"
        cp "$src_cfg" "$gemini_cfg_dir/settings.json"
        print_status "Deployed Gemini settings ($mac_model) to $gemini_cfg_dir/settings.json"
    else
        print_warning "No gemini/settings.json found for $mac_model"
    fi

    # Write env file for local-model mode via LiteLLM proxy
    local env_file
    mkdir -p "$HOME/.profile.d"
    env_file="$HOME/.profile.d/_gemini"

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