#!/opt/homebrew/bin/bash
# setup_opencode.sh — Setup and configuration for OpenCode

set -euo pipefail

# Environment Setup
SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$SETTINGS_BASE/.." && pwd)"

# Source utilities
. "${REPO_ROOT}/helpers.sh"
. "${REPO_ROOT}/models_utils.sh"

log_info "Setting up OpenCode..."

# TODO: Add OpenCode-specific installation/configuration steps here

log_success "OpenCode setup complete."
log_info "Note: update_models_sh() is available from models_utils.sh for model updates."