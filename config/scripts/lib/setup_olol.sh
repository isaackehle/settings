. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Set up olol — Ollama load balancer across multiple machines
# olol routes different requests to different Ollama backends (one full model per machine).
# Does NOT split a single model across machines — each backend must fit the model independently.

_install_olol() {
    if ! command_exists "node"; then
        print_error "Node.js is required for olol. Install from: https://nodejs.org"
        return 1
    fi
    print_info "Installing olol from GitHub..."
    npm install -g https://github.com/K2/olol.git
}

verify_olol() {
    check_tool_with_version "olol" "olol"
}

setup_olol() {
    print_info "Setting up olol (Ollama load balancer)..."
    verify_olol || _install_olol || print_warning "olol not installed — skipping"

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
        print_status "Created starter olol config at $olol_cfg"
        print_warning "Add additional machines to the 'backends' array in $olol_cfg"
    else
        print_status "Existing olol config found at $olol_cfg — not overwritten"
    fi

    print_info ""
    print_info "=== olol usage ==="
    print_info "Start:        olol --config $olol_cfg"
    print_info "API endpoint: http://127.0.0.1:11435/v1  (use instead of :11434 in tool configs)"
    print_info "Add backends: edit 'backends' array in $olol_cfg"
    print_info ""
    print_info "Use case: run the same model on multiple machines and distribute requests."
    print_info "Does NOT reduce per-machine memory — each backend loads the full model."
}

restore_olol() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/olol_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.config/olol"
        cp "$latest_file" "$HOME/.config/olol/config.json"
        print_status "Restored olol config from $(basename "$latest_file")"
    else
        print_warning "No olol config backup found in $BACKUP_DIR"
    fi
}

backup_olol() {
    local olol_cfg="$HOME/.config/olol/config.json"
    if [ -f "$olol_cfg" ]; then
        cp "$olol_cfg" "$BACKUP_DIR/olol_config_backup_$DATE.json"
        print_status "Backed up olol config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_olol
fi
