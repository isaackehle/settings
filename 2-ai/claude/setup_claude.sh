#!/opt/homebrew/bin/bash
# setup_claude.sh — install and configure Claude Code

set -euo pipefail

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

setup_claude() {
    log_info "Setting up Claude Code..."

    # Installation
    if ! command -v claude &> /dev/null; then
        log_info "Installing Claude Code via npm..."
        npm install -g @anthropic-ai/claude-code
    else
        log_info "Claude Code is already installed."
    fi

    # Configuration
    # Note: Claude Code primarily uses a central config; tool-specific 
    # settings are managed via swap-models.sh when changing models.
    log_success "Claude Code setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_claude
fi
