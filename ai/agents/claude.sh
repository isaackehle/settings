#!/opt/homebrew/bin/bash

# setup_claude.sh — install and configure Claude Code

set -euo pipefail

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_claude() {
    if command -v claude &> /dev/null; then
        return 0
    fi
    return 1
}

backup_claude() {
    log_info "Backing up Claude Code config..."
    local config_file="$HOME/.claude/settings.json"
    if [ -f "$config_file" ]; then
        local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}/claude-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp "$config_file" "$backup_dir/"
        log_status "Claude Code config backed up to $backup_dir"
    else
        log_info "No Claude Code config to backup"
    fi
}

restore_claude() {
    log_info "Restoring Claude Code config..."
    local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}"
    local latest_backup=$(ls -dt "$backup_dir"/claude-* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ] && [ -f "$latest_backup/settings.json" ]; then
        mkdir -p "$HOME/.claude"
        cp "$latest_backup/settings.json" "$HOME/.claude/"
        log_status "Claude Code config restored from $latest_backup"
    else
        log_warning "No Claude Code backup found"
    fi
}

setup_claude() {
    log_info "Setting up Claude Code..."

    # Installation
    if ! command -v claude &> /dev/null; then
        log_info "Installing Claude Code via npm..."

        # Ensure npm can write globally without sudo
        # Prefer fnm/nvm managed node, fallback to user-local prefix
        if command -v fnm &> /dev/null; then
            eval "$(fnm env)" 2>/dev/null || true
        elif command -v nvm &> /dev/null; then
            source "$(brew --prefix nvm)/nvm.sh" 2>/dev/null || true
        fi

        # If npm prefix is system-owned, set user-local prefix
        local npm_prefix
        npm_prefix=$(npm config get prefix 2>/dev/null || echo "/usr/local")
        if [[ "$npm_prefix" == "/usr/local" ]] && [ ! -w "$npm_prefix" ]; then
            log_info "Configuring npm user-local prefix (~/.npm-global)..."
            mkdir -p "$HOME/.npm-global"
            npm config set prefix "$HOME/.npm-global"
            export PATH="$HOME/.npm-global/bin:$PATH"
            # Persist for future shells
            grep -q 'npm-global/bin' "$HOME/.zprofile" 2>/dev/null || \
                echo 'export PATH="$HOME/.npm-global/bin:$PATH"' >> "$HOME/.zprofile"
        fi

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
