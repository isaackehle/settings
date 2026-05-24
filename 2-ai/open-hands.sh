if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

OPENHANDS_PORT="${OPENHANDS_PORT:-3000}"

_check_docker() {
    if ! command_exists "docker"; then
        log_error "Docker is required. Install Rancher Desktop or Colima."
        return 1
    fi
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker daemon is not running. Start Rancher Desktop or Colima first."
        return 1
    fi
    return 0
}

verify_openhands() {
    if command_exists "openhands"; then
        log_status "OpenHands CLI installed"
        return 0
    fi
    log_warning "OpenHands CLI not installed"
    return 1
}

setup_openhands() {
    log_info "Setting up OpenHands..."
    _check_docker || return 1

    if ! command_exists "uv"; then
        log_info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        export PATH="$HOME/.local/bin:$PATH"
    fi

    log_info "Installing OpenHands CLI..."
    uv tool install openhands --python 3.12 || { log_error "Failed to install OpenHands"; return 1; }

    mkdir -p "$HOME/.openhands"

    log_info ""
    log_info "=== OpenHands ==="
    log_info "Start:    openhands serve"
    log_info "Web UI:   http://localhost:${OPENHANDS_PORT}"
    log_info "Config:   ~/.openhands"
    log_info "Docs:     https://docs.openhands.dev/"
    log_info ""
    log_info "Local model config (in web UI Settings):"
    log_info "  Provider: OpenAI"
    log_info "  Base URL: http://host.docker.internal:11434/v1"
    log_info "  API Key:  sk-local"
    log_info ""
    log_info "Or run with current directory mounted:"
    log_info "  openhands serve --mount-cwd"
    log_info ""
}

start_openhands() {
    log_info "Starting OpenHands on port ${OPENHANDS_PORT}..."
    _check_docker || return 1

    export PATH="$HOME/.local/bin:$PATH"
    openhands serve
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-setup}" in
        start)  start_openhands ;;
        setup)  setup_openhands ;;
        *)      log_error "Usage: $0 [setup|start]"; exit 1 ;;
    esac
fi
