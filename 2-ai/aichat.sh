if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# AIChat — all-in-one LLM CLI with local and remote support (brew)
# ---------------------------------------------------------------------------

_aichat_cfg_dir="$HOME/.config/aichat"
_aichat_cfg="$_aichat_cfg_dir/config.yaml"

verify_aichat() {
    if command -v aichat >/dev/null 2>&1; then
        log_status "AIChat found: $(aichat --version 2>/dev/null || echo installed)"
        return 0
    fi
    log_warning "AIChat not found"
    return 1
}

_install_aichat() {
    log_info "Installing AIChat via Homebrew..."
    if brew install aichat; then
        log_status "AIChat installed via Homebrew"
        return 0
    fi
    log_error "Failed to install AIChat via Homebrew"
    return 1
}

_setup_aichat_api_keys() {
    if [ -f "$_aichat_cfg" ] && grep -q 'ollama' "$_aichat_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    log_info "AIChat supports multiple providers: Ollama, OpenAI, Anthropic, Groq, etc."
    read -p "  Configure Ollama as the default provider for AIChat? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping provider config — edit $_aichat_cfg manually"
        return 0
    fi

    local tmp
    tmp=$(mktemp)
    cat > "$tmp" << 'EOF'
# Default model
model: ollama:qwen3.2-coder:7b

# Ollama provider
ollama:
  api_base: http://localhost:11434/v1

# Optional: direct cloud fallback
# openai:
#   api_key: sk-...
EOF
    cp "$tmp" "$_aichat_cfg"
    chmod 600 "$_aichat_cfg"
    rm "$tmp"
    log_status "Ollama default config written to $_aichat_cfg"
}

setup_aichat() {
    log_info "Setting up AIChat..."
    verify_aichat || _install_aichat || { log_error "Failed to install AIChat"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_aichat_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/aichat/config.yaml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/aichat/config.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_aichat_cfg"
        chmod 600 "$_aichat_cfg"
        _setup_aichat_api_keys
    else
        log_warning "No AIChat config found"
        _setup_aichat_api_keys
    fi

    log_info ""
    log_info "=== AIChat ==="
    log_info "Binary:  aichat"
    log_info "Config:  $_aichat_cfg"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "  OPENAI_API_KEY=sk-..."
    log_info "  ANTHROPIC_API_KEY=sk-ant-..."
    log_info "Usage:   aichat 'hello'"
    log_info "         aichat -f file.py -- explain this code"
    log_info "         aichat -R (start REPL)"
    log_info "Docs:    https://github.com/sigoden/aichat"
    log_info ""
}

backup_aichat() {
    if [ -f "$_aichat_cfg" ]; then
        cp -r "$_aichat_cfg_dir" "${BACKUP_DIR}/aichat_backup_${DATE}"
        cp "$_aichat_cfg" "${BACKUP_DIR}/aichat_config_backup_${DATE}.yaml"
        log_status "Backed up AIChat config"
    fi
}

restore_aichat() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/aichat_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/aichat_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$_aichat_cfg_dir"
        cp -R "$latest_dir/"* "$_aichat_cfg_dir/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$_aichat_cfg_dir"
        cp "$latest_file" "$_aichat_cfg"
        log_status "Restored AIChat config from $(basename "$latest_file")"
    else
        log_warning "No AIChat backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_aichat
fi
