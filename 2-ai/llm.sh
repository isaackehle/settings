if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# LLM — Simon Willison's CLI tool for LLMs (brew)
# ---------------------------------------------------------------------------

_llm_cfg_dir="$HOME/.config/io.datasette.llm"
_llm_cfg="$_llm_cfg_dir/default_model.txt"

verify_llm() {
    if command -v llm >/dev/null 2>&1; then
        log_status "LLM CLI found: $(llm --version 2>/dev/null || echo installed)"
        return 0
    fi
    log_warning "LLM CLI not found"
    return 1
}

_install_llm() {
    log_info "Installing LLM via Homebrew..."
    if brew install llm; then
        log_status "LLM installed via Homebrew"
        return 0
    fi
    log_error "Failed to install LLM via Homebrew"
    return 1
}

setup_llm() {
    log_info "Setting up LLM..."
    verify_llm || _install_llm || { log_error "Failed to install LLM"; return 1; }

    # Install Ollama plugin if not present
    if ! llm plugins 2>/dev/null | grep -q llm-ollama; then
        log_info "Installing llm-ollama plugin..."
        llm install llm-ollama >/dev/null 2>&1 || log_warning "Failed to install llm-ollama plugin"
    fi

    # Deploy config (profile-specific → default)
    mkdir -p "$_llm_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/llm/default_model.txt"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/llm/default_model.txt"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_llm_cfg"
        log_status "Config deployed to $_llm_cfg"
    else
        log_warning "No LLM default_model.txt config found"
    fi

    # Offer to set default model
    if ! [ -f "$_llm_cfg" ]; then
        echo ""
        read -p "  Set a default Ollama model for LLM now? (y/N) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "qwen3.5:4b" > "$_llm_cfg"
            log_status "Default model set to qwen3.5:4b (planning / fast)"
        fi
    fi

    log_info ""
    log_info "=== LLM ==="
    log_info "Binary:  llm"
    log_info "Config:  $_llm_cfg_dir"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "  OPENAI_API_KEY=sk-..."
    log_info "  ANTHROPIC_API_KEY=sk-ant-..."
    log_info "Usage:   llm 'prompt'"
    log_info "         llm -m qwen3-coder-30b-a3b:q5 'write a Python function'"
    log_info "         llm chat"
    log_info "Plugins: llm install llm-ollama  (for Ollama)"
    log_info "Docs:    https://llm.datasette.io"
    log_info ""
}

backup_llm() {
    if [ -d "$_llm_cfg_dir" ]; then
        cp -r "$_llm_cfg_dir" "${BACKUP_DIR}/llm_backup_${DATE}"
        log_status "Backed up LLM config"
    fi
}

restore_llm() {
    local latest_dir
    latest_dir=$(ls -dt "${BACKUP_DIR}"/llm_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$HOME/.config"
        cp -R "$latest_dir/"* "$_llm_cfg_dir/" 2>/dev/null || true
        log_status "Restored LLM config from $(basename "$latest_dir")"
    else
        log_warning "No LLM backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_llm
fi
