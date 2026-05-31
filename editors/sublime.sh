if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_sublime() {
    if [ -d "/Applications/Sublime Text.app" ] || command_exists "subl"; then
        log_status "Sublime Text found"
        return 0
    fi
    log_warning "Sublime Text not found"
    return 1
}

_install_sublime() {
    log_info "Installing Sublime Text via Homebrew Cask..."
    brew install --cask sublime-text
}

setup_sublime() {
    log_info "Setting up Sublime Text..."
    verify_sublime || _install_sublime || { log_error "Failed to install Sublime Text"; return 1; }

    log_info ""
    log_info "=== Sublime Text ==="
    log_info "Start:   subl"
    log_info "Packages: Install Package Control via Tools → Install Package Control"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_sublime
fi
