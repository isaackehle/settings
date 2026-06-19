if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_crush() {
    if command_exists "crush"; then
        local ver
        ver=$(crush --version 2>/dev/null | head -1 || echo "installed")
        log_status "Crush found: $ver"
        return 0
    fi
    log_warning "Crush not found"
    return 1
}

backup_crush() {
    log_info "Backing up Crush config..."
    local config_file="$HOME/.config/crush/crush.json"
    if [ -f "$config_file" ]; then
        local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}/crush-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$backup_dir"
        cp "$config_file" "$backup_dir/"
        log_status "Crush config backed up to $backup_dir"
    else
        log_info "No Crush config to backup"
    fi
}

restore_crush() {
    log_info "Restoring Crush config..."
    local backup_dir="${BACKUP_DIR:-$HOME/.config-backups}"
    local latest_backup=$(ls -dt "$backup_dir"/crush-* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ] && [ -f "$latest_backup/crush.json" ]; then
        mkdir -p "$HOME/.config/crush"
        cp "$latest_backup/crush.json" "$HOME/.config/crush/"
        log_status "Crush config restored from $latest_backup"
    else
        log_warning "No Crush backup found"
    fi
}

_install_crush() {
    if command_exists "brew"; then
        log_info "Installing Crush via Homebrew..."
        brew install charmbracelet/tap/crush && return 0
    fi
    log_warning "Homebrew not available — see https://github.com/charmbracelet/crush for install options"
    return 1
}

setup_crush() {
    log_info "Setting up Crush..."
    verify_crush || _install_crush || { log_error "Failed to install Crush"; return 1; }

    local config_src="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/crush/crush.json"
    if [ -f "$config_src" ]; then
        log_info "Deploying crush.json for profile: ${MACHINE_PROFILE}"
        mkdir -p "$HOME/.config/crush"
        cp "$config_src" "$HOME/.config/crush/crush.json"
        log_status "Config deployed to ~/.config/crush/crush.json"
    else
        log_warning "No profile config found — copy manually: cp profiles/<machine>/crush/crush.json ~/.config/crush/crush.json"
    fi

    log_info ""
    log_info "=== Crush ==="
    log_info "Start:   crush"
    log_info "Config:  ~/.config/crush/crush.json"
    log_info "Docs:    https://github.com/charmbracelet/crush"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_crush
fi
