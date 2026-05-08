if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_kilocode() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "kilo-code"; then
        log_status "Kilo Code extension found"
        return 0
    fi
    log_warning "Kilo Code extension not found"
    return 1
}

_install_kilocode() {
    if command_exists "code"; then
        log_info "Installing Kilo Code extension..."
        code --install-extension kilohealth.kilo-code && return 0
    fi
    if command_exists "windsurf"; then
        log_info "Installing Kilo Code in Windsurf..."
        windsurf --install-extension kilohealth.kilo-code && return 0
    fi
    log_warning "VS Code CLI (code) not found — install VS Code first"
    return 1
}

setup_kilocode() {
    log_info "Setting up Kilo Code..."
    verify_kilocode || _install_kilocode || log_warning "Kilo Code not installed — skipping"

    local config_src="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE:-}/kilocode/settings.jsonc"
    if [ -n "${MACHINE_PROFILE:-}" ] && [ -f "$config_src" ]; then
        log_info "Profile config available: $config_src"
        log_info "Merge into: ~/Library/Application Support/Code/User/settings.json"
    else
        log_warning "No profile config found — see 2-ai/profiles/<machine>/kilocode/settings.jsonc"
    fi

    log_info ""
    log_info "=== Kilo Code ==="
    log_info "Extension: kilohealth.kilo-code"
    log_info "Config:    VS Code sidebar → Kilo Code → API Provider: OpenAI Compatible"
    log_info "Base URL:  http://localhost:4000/v1"
    log_info "API Key:   sk-local"
    log_info "Docs:      https://kilocode.ai/docs"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kilocode
fi
