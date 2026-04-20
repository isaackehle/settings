. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install Windsurf IDE and deploy argv.json + codeium telemetry config.

_install_windsurf() {
    if command_exists "brew"; then
        print_info "Installing Windsurf via Homebrew..."
        brew install --cask windsurf && return 0
    fi
    print_warning "Homebrew not available — download Windsurf from https://codeium.com/windsurf"
    return 1
}

verify_windsurf() {
    check_tool_with_version "Windsurf" "windsurf"
}

setup_windsurf() {
    print_info "Setting up Windsurf..."
    verify_windsurf || _install_windsurf || print_warning "Windsurf not installed — skipping config deploy"

    local argv_dir="$HOME/.windsurf"
    local codeium_dir="$HOME/.codeium"
    mkdir -p "$argv_dir" "$codeium_dir"

    local script_dir="$(dirname "${BASH_SOURCE[0]}")"

    if [ -f "$script_dir/argv.json" ]; then
        [ -f "$argv_dir/argv.json" ] && backup_windsurf
        cp "$script_dir/argv.json" "$argv_dir/argv.json"
        print_status "Deployed argv.json to $argv_dir/argv.json"
    fi

    if [ -f "$script_dir/codeium-config.json" ]; then
        cp "$script_dir/codeium-config.json" "$codeium_dir/config.json"
        print_status "Deployed codeium config to $codeium_dir/config.json (telemetry disabled)"
    fi

    print_info ""
    print_info "=== Windsurf ==="
    print_info "IDE:        windsurf"
    print_info "Autocomplete: connect Ollama at http://localhost:11434/v1 in Settings > AI"
    print_info "Docs:       https://docs.codeium.com/windsurf"
    print_info ""
}

backup_windsurf() {
    if [ -f "$HOME/.windsurf/argv.json" ]; then
        cp "$HOME/.windsurf/argv.json" "$BACKUP_DIR/windsurf_argv_backup_$DATE.json"
        print_status "Backed up Windsurf argv.json"
    fi
}

restore_windsurf() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/windsurf_argv_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$HOME/.windsurf"
        cp "$latest_file" "$HOME/.windsurf/argv.json"
        print_status "Restored Windsurf argv.json from $(basename "$latest_file")"
    else
        print_warning "No Windsurf config backup found in $BACKUP_DIR"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_windsurf
fi
