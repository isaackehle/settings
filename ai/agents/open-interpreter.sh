if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_open_interpreter() {
    if command_exists "uv"; then
        log_info "Installing Open Interpreter via uv..."
        uv tool install open-interpreter && return 0
    fi
    if command_exists "pip3"; then
        log_info "Installing Open Interpreter via pip..."
        pip3 install open-interpreter && return 0
    fi
    log_warning "Neither uv nor pip available — install via: pip install open-interpreter"
    return 1
}

verify_open_interpreter() {
    if command_exists "interpreter"; then
        local ver
        ver=$(interpreter --version 2>/dev/null | head -1 || echo "installed")
        log_status "Open Interpreter found: $ver"
        return 0
    fi
    log_warning "Open Interpreter not found"
    return 1
}

setup_open_interpreter() {
    log_info "Setting up Open Interpreter..."
    verify_open_interpreter || _install_open_interpreter || { log_error "Failed to install Open Interpreter"; return 1; }

    log_info ""
    log_info "=== Open Interpreter ==="
    log_info "Start:        interpreter"
    log_info "Local model:  interpreter --api_base http://localhost:11434/v1 --api_key sk-local --model <model>"
    log_info "One-shot:     interpreter -y \"<task>\""
    log_info "Safe mode:    interpreter --safe_mode ask"
    log_info "Docs:         https://docs.openinterpreter.com/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_open_interpreter
fi
