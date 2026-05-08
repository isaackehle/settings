if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

TABBY_MODEL="${TABBY_MODEL:-TabbyML/StarCoder-1B}"
TABBY_PORT="${TABBY_PORT:-8080}"

_install_tabby() {
    if command_exists "brew"; then
        log_info "Installing Tabby via Homebrew..."
        brew install tabbyml/tabby/tabby && return 0
    fi
    if command_exists "docker" && docker info > /dev/null 2>&1; then
        log_info "Docker available — Tabby will run via Docker (no local install needed)"
        docker pull tabbyml/tabby && return 0
    fi
    log_warning "Install Tabby manually: https://tabby.tabbyml.com/docs/installation/"
    return 1
}

verify_tabby() {
    if command_exists "tabby"; then
        local ver
        ver=$(tabby --version 2>/dev/null | head -1 || echo "installed")
        log_status "Tabby found: $ver"
        return 0
    fi
    if command_exists "docker" && docker image inspect tabbyml/tabby > /dev/null 2>&1; then
        log_status "Tabby Docker image available"
        return 0
    fi
    log_warning "Tabby not found"
    return 1
}

setup_tabby() {
    log_info "Setting up Tabby..."
    verify_tabby || _install_tabby || { log_warning "Tabby not installed — skipping"; return 0; }

    mkdir -p "$HOME/.tabby"

    log_info ""
    log_info "=== Tabby ==="
    log_info "Start (brew):   tabby serve --model ${TABBY_MODEL} --device metal"
    log_info "Start (docker): docker run -it --rm -p ${TABBY_PORT}:8080 -v ~/.tabby:/data tabbyml/tabby serve --model ${TABBY_MODEL}"
    log_info "Health check:   curl http://localhost:${TABBY_PORT}/v1/health"
    log_info "IDE plugin:     VS Code / JetBrains — search 'Tabby', set URL to http://localhost:${TABBY_PORT}"
    log_info "Docs:           https://tabby.tabbyml.com/docs/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_tabby
fi
