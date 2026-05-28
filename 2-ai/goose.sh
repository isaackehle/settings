if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Goose — Block's open-source AI agent (curl installer)
# ---------------------------------------------------------------------------

_goose_cfg_dir="$HOME/.config/goose"
_goose_cfg="$_goose_cfg_dir/config.yaml"

verify_goose() {
    if command -v goose >/dev/null 2>&1; then
        log_status "Goose found: $(goose --version 2>/dev/null || echo installed)"
        return 0
    fi
    log_warning "Goose not found"
    return 1
}

_install_goose() {
    log_info "Installing Goose via official installer..."

    read -p "  Run the Goose curl installer? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Skipped Goose installer"
        return 1
    fi

    if curl -fsSL https://github.com/aaif-goose/goose/releases/download/stable/download_cli.sh | bash; then
        log_status "Goose installed"
        return 0
    fi
    log_error "Failed to install Goose"
    return 1
}

_setup_goose_provider() {
    if [ -f "$_goose_cfg" ] && grep -q 'provider' "$_goose_cfg" 2>/dev/null; then
        return 0
    fi

    echo ""
    read -p "  Configure Goose to use Ollama? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping provider config — run 'goose --setup' later or edit $_goose_cfg"
        return 0
    fi

    local tmp
    tmp=$(mktemp)
    cat > "$tmp" << 'EOF'
provider: ollama
ollama:
  host: http://localhost:11434
model: qwen3-coder-30b-a3b:q5
EOF
    cp "$tmp" "$_goose_cfg"
    chmod 600 "$_goose_cfg"
    rm "$tmp"
    log_status "Ollama config written to $_goose_cfg"
}

setup_goose() {
    log_info "Setting up Goose..."
    verify_goose || _install_goose || { log_error "Failed to install Goose"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_goose_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/goose/config.yaml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/goose/config.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_goose_cfg"
        chmod 600 "$_goose_cfg"
        _setup_goose_provider
    else
        log_warning "No Goose config found"
        _setup_goose_provider
    fi

    log_info ""
    log_info "=== Goose ==="
    log_info "Binary:  goose"
    log_info "Config:  $_goose_cfg"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "  OPENAI_API_KEY=sk-..."
    log_info "  ANTHROPIC_API_KEY=sk-ant-..."
    log_info "Usage:   goose"
    log_info "         goose --setup"
    log_info "Docs:    https://goose-docs.ai"
    log_info ""
}

backup_goose() {
    if [ -f "$_goose_cfg" ]; then
        cp -r "$_goose_cfg_dir" "${BACKUP_DIR}/goose_backup_${DATE}"
        cp "$_goose_cfg" "${BACKUP_DIR}/goose_config_backup_${DATE}.yaml"
        log_status "Backed up Goose config"
    fi
}

restore_goose() {
    local latest_dir latest_file
    latest_dir=$(ls -dt "${BACKUP_DIR}"/goose_backup_* 2>/dev/null | head -1)
    latest_file=$(ls -t "${BACKUP_DIR}"/goose_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$_goose_cfg_dir"
        cp -R "$latest_dir/"* "$_goose_cfg_dir/" 2>/dev/null || true
    fi
    if [ -n "$latest_file" ]; then
        mkdir -p "$_goose_cfg_dir"
        cp "$latest_file" "$_goose_cfg"
        log_status "Restored Goose config from $(basename "$latest_file")"
    else
        log_warning "No Goose backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_goose
fi
