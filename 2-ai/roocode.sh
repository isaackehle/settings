if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

verify_roocode() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "roo-cline"; then
        log_status "RooCode extension found"
        return 0
    fi
    log_warning "RooCode extension not found"
    return 1
}

_install_roocode() {
    if command_exists "code"; then
        log_info "Installing RooCode extension..."
        code --install-extension rooveterinaryinc.roo-cline && return 0
    fi
    if command_exists "windsurf"; then
        log_info "Installing RooCode in Windsurf..."
        windsurf --install-extension rooveterinaryinc.roo-cline && return 0
    fi
    log_warning "VS Code CLI (code) not found — install VS Code first"
    return 1
}

setup_roocode() {
    log_info "Setting up RooCode..."
    verify_roocode || _install_roocode || log_warning "RooCode not installed — skipping"

    local config_src="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/roocode/settings.jsonc"
    if [ -f "$config_src" ]; then
        log_info "Profile config available: $config_src"
        log_info "Merge into: ~/Library/Application Support/Code/User/settings.json"
    else
        log_warning "No profile config found — see 2-ai/profiles/<machine>/roocode/settings.jsonc"
    fi

    log_info ""
    log_info "=== RooCode ==="
    log_info "Extension: rooveterinaryinc.roo-cline"
    log_info "Config:    VS Code sidebar → Roo Code → API Provider: OpenAI Compatible"
    log_info "Base URL:  http://localhost:4000/v1"
    log_info "API Key:   sk-local"
    log_info "Docs:      https://roocode.com/docs"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_roocode
fi
