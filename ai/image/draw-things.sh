if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_draw_things() {
    if [ -d "/Applications/Draw Things.app" ]; then
        log_status "Draw Things.app found"
        return 0
    fi
    log_warning "Draw Things not found in /Applications"
    return 1
}

setup_draw_things() {
    log_info "Setting up Draw Things..."

    if verify_draw_things; then
        log_status "Draw Things is already installed."
    else
        log_warning "Draw Things is a Mac App Store app — install it manually:"
        log_info "  App Store: https://apps.apple.com/us/app/draw-things-ai-generation/id6444050820"
        log_info "  Direct:    https://drawthings.ai/"
    fi

    log_info ""
    log_info "=== Draw Things ==="
    log_info "Start:      Open from Applications (GUI only)"
    log_info "API server: Enable in Settings → API Server → port 7860"
    log_info "Models:     Download in-app or import .safetensors via Files"
    log_info "Site:       https://drawthings.ai/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_draw_things
fi
