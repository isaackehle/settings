if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_zoocode() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "zoo-code"; then
        log_status "Zoo Code extension found"
        return 0
    fi
    log_warning "Zoo Code extension not found"
    return 1
}

_install_zoocode() {
    if command_exists "code"; then
        log_info "Installing Zoo Code extension..."
        code --install-extension zooveterinaryinc.zoo-code && return 0
    fi
    if command_exists "windsurf"; then
        log_info "Installing Zoo Code in Windsurf..."
        windsurf --install-extension zooveterinaryinc.zoo-code && return 0
    fi
    log_warning "VS Code CLI (code) not found — install VS Code first"
    return 1
}

setup_zoocode() {
    log_info "Setting up Zoo Code..."
    verify_zoocode || _install_zoocode || log_warning "Zoo Code not installed — skipping"

    local config_src="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/zoocode/settings.jsonc"
    if [ -f "$config_src" ]; then
        log_info "Profile config available: $config_src"
        log_info "Merge into: ~/Library/Application Support/Code/User/settings.json"
    else
        log_warning "No profile config found — see 2-ai/profiles/<machine>/zoocode/settings.jsonc"
    fi

    log_info ""
    log_info "=== Zoo Code ==="
    log_info "Extension: zooveterinaryinc.zoo-code"
    log_info "Config:    VS Code sidebar → Zoo Code → API Provider: OpenAI Compatible"
    log_info "Base URL:  http://localhost:11434/v1"
    log_info "API Key:   sk-local"
    log_info "Docs:      https://zoocode.com/docs"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_zoocode
fi