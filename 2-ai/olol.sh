if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Set up olol — Ollama load balancer across multiple machines
# olol routes different requests to different Ollama backends (one full model per machine).
# Does NOT split a single model across machines — each backend must fit the model independently.

# Known machines in the fleet (Star Trek theme)
declare -A MACHINE_HOSTNAMES=(
    ["ds9"]="DS9.local"           # Mac mini M2 16GB
    ["enterprise"]="Enterprise.local"  # MacBook M1 16GB
    ["discovery"]="Discovery.local"     # MacBook M5 Max 64GB
)

_install_olol() {
    if ! command_exists "node"; then
        log_error "Node.js is required for olol. Install from: https://nodejs.org"
        return 1
    fi
    log_info "Installing olol..."
    npm install -g olol 2>/dev/null || npm install -g @k2/olol 2>/dev/null || {
        log_error "Failed to install olol. Try: npm install -g olol"
        return 1
    }
}

verify_olol() {
    check_tool_with_version "olol" "olol"
}

# Check if a host is reachable and has Ollama running
_check_backend() {
    local hostname="$1"
    local port="${2:-11434}"

    # Try to connect with timeout
    if nc -z -w 2 "$hostname" "$port" 2>/dev/null; then
        return 0  # Available
    fi
    return 1  # Unreachable
}

# Auto-discover available backends
_discover_backends() {
    local backends_json="["
    local first=true
    local hostname

    # Get this machine's hostname
    hostname=$(hostname -s 2>/dev/null || hostname | cut -d. -f1)
    hostname="${hostname,,}"  # lowercase

    log_info "Discovering available Ollama backends..."

    # Always include local first
    log_info "  ✓ localhost (local)"
    backends_json="${backends_json}{ \"url\": \"http://127.0.0.1:11434\", \"name\": \"local\" }"

    # Check each known machine
    for key in "${!MACHINE_HOSTNAMES[@]}"; do
        local full_hostname="${MACHINE_HOSTNAMES[$key]}"

        # Skip if it's this machine (already added as local)
        if [[ "${key,,}" == "$hostname" ]]; then
            continue
        fi

        if _check_backend "$full_hostname"; then
            log_info "  ✓ $full_hostname ($key)"
            if [ "$first" = true ]; then
                first=false
            else
                backends_json="${backends_json},"
            fi
            backends_json="${backends_json}{ \"url\": \"http://${full_hostname}:11434\", \"name\": \"${key}\" }"
        else
            log_info "  ✗ $full_hostname ($key) - offline, skipping"
        fi
    done

    backends_json="${backends_json}]"
    echo "$backends_json"
}

setup_olol() {
    log_info "Setting up olol (Ollama load balancer)..."
    verify_olol || _install_olol || log_warning "olol not installed — skipping"

    local olol_cfg="$HOME/.config/olol/config.json"
    mkdir -p "$(dirname "$olol_cfg")"

    # Auto-discover backends
    local backends
    backends=$(_discover_backends)

    if [ -f "$olol_cfg" ]; then
        log_status "Existing olol config found at $olol_cfg"
        read -p "  Overwrite with auto-discovered backends? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Keeping existing config."
            return 0
        fi
    fi

    # Write config with discovered backends
    cat > "$olol_cfg" << EOF
{
  "port": 11435,
  "backends": $backends
}
EOF
    log_status "Created olol config at $olol_cfg"

    log_info ""
    log_info "=== olol usage ==="
    log_info "Start:        olol --config $olol_cfg"
    log_info "API endpoint: http://127.0.0.1:11435/v1"
    log_info ""
    log_info "Auto-discovery will skip offline machines — works while traveling!"
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
