if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

OPENHANDS_IMAGE="docker.all-hands.dev/all-hands-ai/openhands:latest"
OPENHANDS_RUNTIME="docker.all-hands.dev/all-hands-ai/runtime:latest"
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
    if docker image inspect "$OPENHANDS_IMAGE" > /dev/null 2>&1; then
        log_status "OpenHands image found locally"
        return 0
    fi
    log_warning "OpenHands image not pulled yet"
    return 1
}

setup_openhands() {
    log_info "Setting up OpenHands..."
    _check_docker || return 1

    log_info "Pulling OpenHands image (this may take a while)..."
    docker pull "$OPENHANDS_IMAGE" || { log_error "Failed to pull OpenHands image"; return 1; }
    docker pull "$OPENHANDS_RUNTIME" || log_warning "Failed to pull runtime image — will pull on first run"

    mkdir -p "$HOME/.openhands-state"

    log_info ""
    log_info "=== OpenHands ==="
    log_info "Start:    ./open_hands.sh start"
    log_info "Web UI:   http://localhost:${OPENHANDS_PORT}"
    log_info "State:    ~/.openhands-state"
    log_info "Docs:     https://docs.all-hands.dev/"
    log_info ""
    log_info "Local model config (in web UI Settings):"
    log_info "  Provider: OpenAI"
    log_info "  Base URL: http://host.docker.internal:4000/v1"
    log_info "  API Key:  sk-local"
    log_info ""
}

start_openhands() {
    log_info "Starting OpenHands on port ${OPENHANDS_PORT}..."
    _check_docker || return 1

    docker run -it --rm \
        --pull=always \
        -e SANDBOX_RUNTIME_CONTAINER_IMAGE="$OPENHANDS_RUNTIME" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$HOME/.openhands-state:/.openhands-state" \
        -p "${OPENHANDS_PORT}:3000" \
        --add-host host.docker.internal:host-gateway \
        --name openhands-app \
        "$OPENHANDS_IMAGE"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-setup}" in
        start)  start_openhands ;;
        setup)  setup_openhands ;;
        *)      log_error "Usage: $0 [setup|start]"; exit 1 ;;
    esac
fi
