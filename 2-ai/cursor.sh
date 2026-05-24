if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_cursor() {
    if [ -d "/Applications/Cursor.app" ] || command_exists "cursor"; then
        log_status "Cursor found"
        return 0
    fi
    log_warning "Cursor not found"
    return 1
}

_install_cursor() {
    if command_exists "brew"; then
        log_info "Installing Cursor via Homebrew Cask..."
        brew install --cask cursor && return 0
    fi
    log_warning "Homebrew not available — download from https://cursor.com"
    return 1
}

setup_cursor() {
    log_info "Setting up Cursor..."
    verify_cursor || _install_cursor || log_warning "Cursor not installed — skipping config"

    local config_src="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/cursor/settings.jsonc"
    local config_dest="$HOME/Library/Application Support/Cursor/User/settings.json"
    if [ -f "$config_src" ]; then
        log_info "Profile config available: $config_src"
        log_info "Merge manually into: $config_dest"
        log_info "  (Cursor settings are JSONC — remove comments before merging)"
    else
        log_warning "No profile config found — see 2-ai/profiles/<machine>/cursor/settings.jsonc"
    fi

    log_info ""
    log_info "=== Cursor ==="
    log_info "Start:    open -a Cursor  (or: cursor <path>)"
    log_info "Config:   $config_dest"
    log_info "Ollama:   Settings (Cmd+Shift+J) → Models → Override OpenAI Base URL → http://localhost:11434/v1"
    log_info "API Key:  sk-local"
    log_info "Docs:     https://docs.cursor.com/"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_cursor
fi
