#!/opt/homebrew/bin/bash
# setup_claude.sh — install and configure Claude Code

set -euo pipefail

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "${SETTINGS_BASE}/../helpers.sh"

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