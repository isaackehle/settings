if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Set up olol — Ollama load balancer across multiple machines
# olol routes different requests to different Ollama backends (one full model per machine).
# Does NOT split a single model across machines — each backend must fit the model independently.

_install_olol() {
    if ! command_exists "node"; then
        log_error "Node.js is required for olol. Install from: https://nodejs.org"
        return 1
    fi
    log_info "Installing olol from GitHub..."
    npm install -g https://github.com/K2/olol.git
}

verify_olol() {
    check_tool_with_version "olol" "olol"
}

setup_olol() {
    log_info "Setting up olol (Ollama load balancer)..."
    verify_olol || _install_olol || log_warning "olol not installed — skipping"

    local olol_cfg="$HOME/.config/olol/config.json"
    mkdir -p "$(dirname "$olol_cfg")"

    if [ ! -f "$olol_cfg" ]; then
        cat > "$olol_cfg" << 'EOF'
{
  "port": 11435,
  "backends": [
    { "url": "http://127.0.0.1:11434", "name": "local-m5max" }
  ]
}
EOF
        log_status "Created starter olol config at $olol_cfg"
        log_warning "Add additional machines to the 'backends' array in $olol_cfg"
    else
        log_status "Existing olol config found at $olol_cfg — not overwritten"
    fi

    log_info ""
    log_info "=== olol usage ==="
    log_info "Start:        olol --config $olol_cfg"
    log_info "API endpoint: http://127.0.0.1:11435/v1  (use instead of :11434 in tool configs)"
    log_info "Add backends: edit 'backends' array in $olol_cfg"
    log_info ""
    log_info "Use case: run the same model on multiple machines and distribute requests."
    log_info "Does NOT reduce per-machine memory — each backend loads the full model."
}

restore_olol() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/olol_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.config/olol"
        cp "$latest_file" "$HOME/.config/olol/config.json"
        log_status "Restored olol config from $(basename "$latest_file")"
    else
        log_warning "No olol config backup found in $BACKUP_DIR"
    fi
}

backup_olol() {
    local olol_cfg="$HOME/.config/olol/config.json"
    if [ -f "$olol_cfg" ]; then
        cp "$olol_cfg" "$BACKUP_DIR/olol_config_backup_$DATE.json"
        log_status "Backed up olol config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_olol
fi
