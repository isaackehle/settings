if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Devin Desktop (formerly Windsurf) — Agent Command Center / IDE
# Rebrand: Windsurf → Devin Desktop effective June 2, 2026
# Transition: legacy Windsurf paths still read, new data written to Devin paths
# ---------------------------------------------------------------------------

_install_devin() {
    if command_exists "brew"; then
        print_info "Installing Devin Desktop via Homebrew..."
        brew install --cask devin && return 0
    fi
    print_warning "Homebrew not available — download Devin Desktop from https://devin.ai"
    return 1
}

verify_devin() {
    # Check for Devin.app (new name) or Windsurf.app (legacy)
    if [ -d "/Applications/Devin.app" ] || [ -d "/Applications/Windsurf.app" ]; then
        print_status "Devin Desktop found"
        return 0
    fi
    print_warning "Devin Desktop not found"
    return 1
}

setup_devin() {
    print_info "Setting up Devin Desktop..."
    verify_devin || _install_devin || print_warning "Devin Desktop not installed — skipping config deploy"

    # Devin Desktop reads legacy Windsurf paths during transition;
    # new data is written to Devin paths.  We deploy to both so the
    # config works regardless of whether the user has received the
    # OTA rebrand update yet.
    local devin_dir="$HOME/.config/Devin"
    local legacy_dir="$HOME/.config/Windsurf"
    local devin_ext_dir="$HOME/.devin"
    local legacy_ext_dir="$HOME/.windsurf"
    local codeium_dir="$HOME/.codeium"

    mkdir -p "$devin_dir" "$legacy_dir" "$devin_ext_dir" "$legacy_ext_dir" "$codeium_dir"

    local script_dir="$(dirname "${BASH_SOURCE[0]}")"

    # argv.json → deploy to both new and legacy paths
    if [ -f "$script_dir/argv.json" ]; then
        cp "$script_dir/argv.json" "$devin_dir/argv.json"
        cp "$script_dir/argv.json" "$legacy_dir/argv.json"
        print_status "Deployed argv.json to Devin ($devin_dir) and legacy Windsurf ($legacy_dir)"
    fi

    # codeium-config.json → still at ~/.codeium/config.json (unchanged)
    if [ -f "$script_dir/codeium-config.json" ]; then
        cp "$script_dir/codeium-config.json" "$codeium_dir/config.json"
        print_status "Deployed codeium config to $codeium_dir/config.json (telemetry disabled)"
    fi

    print_info ""
    print_info "=== Devin Desktop ==="
    print_info "IDE:        devin"
    print_info "App:        /Applications/Devin.app (or legacy Windsurf.app)"
    print_info "Config:     $devin_dir"
    print_info "Legacy:     $legacy_dir"
    print_info "Autocomplete: connect Ollama at http://localhost:11434/v1 in Settings > AI"
    print_info "Docs:       https://docs.devin.ai/desktop"
    print_info ""
}

backup_devin() {
    # Back up both Devin and legacy Windsurf config paths
    local devin_config="$HOME/.config/Devin/argv.json"
    local legacy_config="$HOME/.config/Windsurf/argv.json"
    local codeium_config="$HOME/.codeium/config.json"

    if [ -f "$devin_config" ]; then
        cp "$devin_config" "$BACKUP_DIR/devin_argv_backup_$DATE.json"
        print_status "Backed up Devin argv.json"
    fi
    if [ -f "$legacy_config" ]; then
        cp "$legacy_config" "$BACKUP_DIR/windsurf_argv_backup_$DATE.json"
        print_status "Backed up legacy Windsurf argv.json"
    fi
    if [ -f "$codeium_config" ]; then
        cp "$codeium_config" "$BACKUP_DIR/codeium_config_backup_$DATE.json"
        print_status "Backed up codeium config.json"
    fi
}

restore_devin() {
    # Restore Devin argv.json
    local latest_devin
    latest_devin=$(ls -t "$BACKUP_DIR"/devin_argv_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_devin" ]; then
        mkdir -p "$HOME/.config/Devin"
        cp "$latest_devin" "$HOME/.config/Devin/argv.json"
        print_status "Restored Devin argv.json from $(basename "$latest_devin")"
    else
        print_warning "No Devin config backup found in $BACKUP_DIR"
    fi

    # Also restore legacy Windsurf if available
    local latest_windsurf
    latest_windsurf=$(ls -t "$BACKUP_DIR"/windsurf_argv_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_windsurf" ]; then
        mkdir -p "$HOME/.config/Windsurf"
        cp "$latest_windsurf" "$HOME/.config/Windsurf/argv.json"
        print_status "Restored legacy Windsurf argv.json from $(basename "$latest_windsurf")"
    fi

    # Restore codeium config
    local latest_codeium
    latest_codeium=$(ls -t "$BACKUP_DIR"/codeium_config_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_codeium" ]; then
        mkdir -p "$HOME/.codeium"
        cp "$latest_codeium" "$HOME/.codeium/config.json"
        print_status "Restored codeium config.json from $(basename "$latest_codeium")"
    fi
}

# Keep legacy function names as aliases for backward compat
setup_windsurf() { setup_devin; }
backup_windsurf() { backup_devin; }
restore_windsurf() { restore_devin; }
verify_windsurf() { verify_devin; }

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_devin
fi
