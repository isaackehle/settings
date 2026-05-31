if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Fabric — Daniel Miessler's AI CLI workflow toolkit (brew as fabric-ai)
# ---------------------------------------------------------------------------

_fabric_cfg_dir="$HOME/.config/fabric"

verify_fabric() {
    if command -v fabric-ai >/dev/null 2>&1 || command -v fabric >/dev/null 2>&1; then
        log_status "Fabric found"
        return 0
    fi
    log_warning "Fabric not found (binary: fabric-ai or fabric)"
    return 1
}

_install_fabric() {
    log_info "Installing Fabric via Homebrew..."
    if brew install fabric-ai; then
        log_status "Fabric installed via Homebrew"

        # Warn user about alias
        if command -v fabric-ai >/dev/null 2>&1 && ! command -v fabric >/dev/null 2>&1; then
            log_warning "brew installs 'fabric-ai'. Add alias: alias fabric='fabric-ai'"
        fi
        return 0
    fi
    log_error "Failed to install Fabric via Homebrew"
    return 1
}

setup_fabric() {
    log_info "Setting up Fabric..."
    verify_fabric || _install_fabric || { log_error "Failed to install Fabric"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_fabric_cfg_dir"
    local src_dir
    src_dir="${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/fabric"
    if [ ! -d "$src_dir" ]; then
        src_dir="${SETTINGS_BASE}/ai/profiles/default/fabric"
    fi

    if [ -d "$src_dir" ]; then
        for f in "$src_dir"/*; do
            [ -f "$f" ] || continue
            local dest="$_fabric_cfg_dir/$(basename "$f")"
            copy_file "$f" "$dest"
        done
        log_status "Fabric config deployed"
    else
        log_warning "No Fabric config directory found"
    fi

    # Add alias to profile.d if needed
    local _fabric_alias="$HOME/.profile.d/_fabric"
    if command -v fabric-ai >/dev/null 2>&1 && ! alias fabric >/dev/null 2>&1; then
        cat > "$_fabric_alias" << 'EOF'
# Fabric alias (brew installs as fabric-ai)
command -v fabric-ai >/dev/null 2>&1 && alias fabric='fabric-ai'
EOF
        log_status "Wrote fabric alias to $_fabric_alias"
    fi

    log_info ""
    log_info "=== Fabric ==="
    log_info "Binary:  fabric (or fabric-ai)"
    log_info "Config:  $_fabric_cfg_dir"
    log_info "API keys: Store in ~/.env.local (source'd by your shell)"
    log_info "  OPENAI_API_KEY=sk-..."
    log_info "  ANTHROPIC_API_KEY=sk-ant-..."
    log_info "Setup:   fabric --setup"
    log_info "Usage:   echo 'text' | fabric --pattern summarize"
    log_info "         fabric -u https://example.com -p analyze_claims"
    log_info "Docs:    https://github.com/danielmiessler/fabric"
    log_info ""
}

backup_fabric() {
    if [ -d "$_fabric_cfg_dir" ]; then
        cp -r "$_fabric_cfg_dir" "${BACKUP_DIR}/fabric_backup_${DATE}"
        log_status "Backed up Fabric config"
    fi
}

restore_fabric() {
    local latest_dir
    latest_dir=$(ls -dt "${BACKUP_DIR}"/fabric_backup_* 2>/dev/null | head -1)
    if [ -n "$latest_dir" ]; then
        mkdir -p "$_fabric_cfg_dir"
        cp -R "$latest_dir/"* "$_fabric_cfg_dir/" 2>/dev/null || true
        log_status "Restored Fabric config from $(basename "$latest_dir")"
    else
        log_warning "No Fabric backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_fabric
fi
