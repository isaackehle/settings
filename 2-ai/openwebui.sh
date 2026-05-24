#!/opt/homebrew/bin/bash

# OpenWebUI setup script

set -euo pipefail

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

OPENWEBUI_PORT="${OPENWEBUI_PORT:-8080}"
OPENWEBUI_CONTAINER="openwebui"

_check_docker() {
    # Check for Rancher Desktop docker socket first
    if [ -S "$HOME/.rd/docker.sock" ]; then
        export DOCKER_HOST="unix://$HOME/.rd/docker.sock"
    fi

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

verify_openwebui() {
    if docker ps --format '{{.Names}}' | grep -q "^${OPENWEBUI_CONTAINER}$"; then
        log_status "OpenWebUI container running"
        return 0
    fi
    if docker ps -a --format '{{.Names}}' | grep -q "^${OPENWEBUI_CONTAINER}$"; then
        log_warning "OpenWebUI container exists but not running"
        return 1
    fi
    log_warning "OpenWebUI not installed"
    return 1
}

setup_openwebui() {
    log_info "Setting up OpenWebUI..."
    _check_docker || return 1

    if docker ps -a --format '{{.Names}}' | grep -q "^${OPENWEBUI_CONTAINER}$"; then
        log_info "OpenWebUI container already exists"
        docker start "$OPENWEBUI_CONTAINER" 2>/dev/null || true
    else
        log_info "Creating OpenWebUI container..."
        docker run -d \
            --name "$OPENWEBUI_CONTAINER" \
            --restart unless-stopped \
            -p "${OPENWEBUI_PORT}:8080" \
            -v openwebui:/app/backend/data \
            --add-host=host.docker.internal:host-gateway \
            ghcr.io/open-webui/open-webui:main
    fi

    log_info ""
    log_info "=== OpenWebUI ==="
    log_info "Web UI:   http://localhost:${OPENWEBUI_PORT}"
    log_info ""
    log_info "To connect to Ollama:"
    log_info "  1. Add API URL: http://host.docker.internal:11434/v1"
    log_info ""
}

start_openwebui() {
    _check_docker || return 1

    if docker ps -a --format '{{.Names}}' | grep -q "^${OPENWEBUI_CONTAINER}$"; then
        docker start "$OPENWEBUI_CONTAINER"
        log_status "OpenWebUI started at http://localhost:${OPENWEBUI_PORT}"
    else
        log_error "OpenWebUI not setup. Run: bash 2-ai/openwebui.sh setup"
    fi
}

stop_openwebui() {
    docker stop "$OPENWEBUI_CONTAINER" 2>/dev/null && log_status "OpenWebUI stopped" || log_warning "OpenWebUI not running"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-setup}" in
        start)  start_openwebui ;;
        stop)   stop_openwebui ;;
        setup)  setup_openwebui ;;
        *)      log_error "Usage: $0 [setup|start|stop]"; exit 1 ;;
    esac
fi