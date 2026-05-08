if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Install GPT4All — offline desktop app for local model inference.

_install_gpt4all() {
    if command_exists "brew"; then
        log_info "Installing GPT4All via Homebrew..."
        brew install --cask gpt4all && return 0
    fi
    log_warning "Homebrew not available — download from https://gpt4all.io"
    return 1
}

verify_gpt4all() {
    if [ -d "/Applications/GPT4All.app" ]; then
        log_status "GPT4All.app found"
        return 0
    fi
    log_warning "GPT4All not found in /Applications"
    return 1
}

setup_gpt4all() {
    log_info "Setting up GPT4All..."
    verify_gpt4all || _install_gpt4all || log_warning "GPT4All not installed — skipping"

    log_info ""
    log_info "=== GPT4All ==="
    log_info "Launch:   open /Applications/GPT4All.app"
    log_info "Models:   download from within the app (Explore Models tab)"
    log_info "API:      http://localhost:4891/v1  (enable in Settings → API Server)"
    log_info "Docs:     https://docs.gpt4all.io"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gpt4all
fi
