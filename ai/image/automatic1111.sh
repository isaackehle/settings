if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

WEBUI_DIR="${AUTOMATIC1111_DIR:-$HOME/stable-diffusion-webui}"

_install_automatic1111() {
    if ! command_exists "git"; then
        log_error "git is required. Install via: brew install git"
        return 1
    fi
    if ! command_exists "python3"; then
        log_error "Python 3 is required. Install via: brew install python@3.10"
        return 1
    fi

    log_info "Cloning Automatic1111 stable-diffusion-webui to ${WEBUI_DIR}..."
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$WEBUI_DIR" || {
        log_error "Failed to clone repo"
        return 1
    }
    log_status "Cloned successfully. Run: cd ${WEBUI_DIR} && ./webui.sh"
}

verify_automatic1111() {
    if [ -d "$WEBUI_DIR" ] && [ -f "$WEBUI_DIR/webui.sh" ]; then
        log_status "Automatic1111 found at: ${WEBUI_DIR}"
        return 0
    fi
    log_warning "Automatic1111 not found at: ${WEBUI_DIR}"
    return 1
}

setup_automatic1111() {
    log_info "Setting up Automatic1111..."
    verify_automatic1111 || _install_automatic1111 || { log_error "Failed to install Automatic1111"; return 1; }

    log_info ""
    log_info "=== Automatic1111 ==="
    log_info "Start:    cd ${WEBUI_DIR} && ./webui.sh"
    log_info "Web UI:   http://localhost:7860"
    log_info "Models:   ${WEBUI_DIR}/models/Stable-diffusion/"
    log_info "API docs: http://localhost:7860/docs  (start with --api)"
    log_info "Wiki:     https://github.com/AUTOMATIC1111/stable-diffusion-webui/wiki"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_automatic1111
fi
