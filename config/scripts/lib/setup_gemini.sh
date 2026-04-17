. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Install Gemini (try npm first, fallback to manual)
setup_gemini() {
    print_info "Installing Gemini..."

    # Try npm installation first
    if command_exists "npm"; then
        print_info "Attempting npm install..."

        # Try official Gemini package (different naming)
        if install_via_npm "Google Gemini CLI" "@google/gemini-cli"; then
            return 0
        fi

        # Try npm installation first
        if install_via_npm "Gemini" "@ai-sdk/gemini"; then
            return 0
        fi

        # Try alternative package names
        if install_via_npm "Gemini" "gemini"; then
            return 0
        fi
    fi

    if command_exists "brew"; then
        print_info "Attempting Homebrew install..."
        if brew install gemini-cli; then
            print_status "Gemini installed successfully via Homebrew"
            return 0
        fi
    fi

    # Try alternative methods or provide instructions
    print_info "Please manually install Gemini from:"
    print_info "  https://github.com/google/gemini"
    print_info "  Documentation: https://geminicli.com/docs/get-started/installation/"
    return 1
}

verify_gemini() {
    check_tool_with_version "Gemini" "gemini"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gemini
fi