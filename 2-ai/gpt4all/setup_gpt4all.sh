. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install GPT4All — offline desktop app for local model inference.

_install_gpt4all() {
    if command_exists "brew"; then
        print_info "Installing GPT4All via Homebrew..."
        brew install --cask gpt4all && return 0
    fi
    print_warning "Homebrew not available — download from https://gpt4all.io"
    return 1
}

verify_gpt4all() {
    if [ -d "/Applications/GPT4All.app" ]; then
        print_status "GPT4All.app found"
        return 0
    fi
    print_warning "GPT4All not found in /Applications"
    return 1
}

setup_gpt4all() {
    print_info "Setting up GPT4All..."
    verify_gpt4all || _install_gpt4all || print_warning "GPT4All not installed — skipping"

    print_info ""
    print_info "=== GPT4All ==="
    print_info "Launch:   open /Applications/GPT4All.app"
    print_info "Models:   download from within the app (Explore Models tab)"
    print_info "API:      http://localhost:4891/v1  (enable in Settings → API Server)"
    print_info "Docs:     https://docs.gpt4all.io"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gpt4all
fi
