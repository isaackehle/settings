#!/opt/homebrew/bin/bash

# setup_opencode.sh — Setup and configuration for OpenCode

set -euo pipefail

# Environment Setup

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_opencode() {
    if command -v opencode &> /dev/null; then
        return 0
    fi
    return 1
}

backup_opencode() {
    log_info "Backing up OpenCode config..."
    local config_dir="$HOME/.config/opencode"
    if [ -d "$config_dir" ]; then
        local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}/opencode-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp -R "$config_dir" "$backup_dir/"
        log_status "OpenCode config backed up to $backup_dir"
    else
        log_info "No OpenCode config to backup"
    fi
}

restore_opencode() {
    log_info "Restoring OpenCode config..."
    local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}"
    local latest_backup=$(ls -dt "$backup_dir"/opencode-* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ] && [ -d "$latest_backup/opencode" ]; then
        cp -R "$latest_backup/opencode" "$HOME/.config/"
        log_status "OpenCode config restored from $latest_backup"
    else
        log_warning "No OpenCode backup found"
    fi
}

setup_opencode() {
    log_info "Setting up OpenCode..."

    # TODO: Add OpenCode-specific installation/configuration steps here

    log_success "OpenCode setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_opencode
fi
