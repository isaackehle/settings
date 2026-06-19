if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_aider() {
    if command_exists "uv"; then
        log_info "Installing Aider via uv..."
        uv tool install aider-chat && return 0
    fi
    if command_exists "brew"; then
        log_info "Installing Aider via Homebrew..."
        brew install aider && return 0
    fi
    log_warning "Neither uv nor brew available — install via: pip install aider-chat"
    return 1
}

verify_aider() {
    if command_exists "aider"; then
        local ver
        ver=$(aider --version 2>/dev/null | head -1 || echo "installed")
        log_status "Aider found: $ver"
        return 0
    fi
    log_warning "Aider not found"
    return 1
}

backup_aider() {
    log_info "Backing up Aider config..."
    local config_file="$HOME/.aider.conf.yml"
    if [ -f "$config_file" ]; then
        local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}/aider-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp "$config_file" "$backup_dir/"
        log_status "Aider config backed up to $backup_dir"
    else
        log_info "No Aider config to backup"
    fi
}

restore_aider() {
    log_info "Restoring Aider config..."
    local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}"
    local latest_backup=$(ls -dt "$backup_dir"/aider-* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ] && [ -f "$latest_backup/aider.conf.yml" ]; then
        cp "$latest_backup/aider.conf.yml" "$HOME/.aider.conf.yml"
        log_status "Aider config restored from $latest_backup"
    else
        log_warning "No Aider backup found"
    fi
}

setup_aider() {
    log_info "Setting up Aider..."
    verify_aider || _install_aider || { log_error "Failed to install Aider"; return 1; }

    local config_src="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/aider/aider.conf.yml"
    if [ -f "$config_src" ]; then
        log_info "Deploying aider.conf.yml for profile: ${MACHINE_PROFILE}"
        cp "$config_src" "$HOME/.aider.conf.yml"
        log_status "Config deployed to ~/.aider.conf.yml"
    else
        log_warning "No profile config found — copy manually: cp ai/profiles/<machine>/aider/aider.conf.yml ~/.aider.conf.yml"
    fi

    log_info ""
    log_info "=== Aider ==="
    log_info "Start:    aider                (in any git repo)"
    log_info "Config:   ~/.aider.conf.yml"
    log_info "Docs:     https://aider.chat/docs/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_aider
fi
