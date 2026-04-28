if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Set up Groq — cloud LLM inference via API key.
# local-settings.json is used by the Groq Code CLI (~/.groq/).

_groq_cfg_dir="$HOME/.groq"
_groq_cfg="$_groq_cfg_dir/local-settings.json"

verify_groq() {
    if [ -f "$_groq_cfg" ]; then
        print_status "Groq local-settings.json present"
        return 0
    fi
    print_warning "Groq local-settings.json not found"
    return 1
}

setup_groq() {
    print_info "Setting up Groq..."
    mkdir -p "$_groq_cfg_dir"

    local src_cfg mac_model
    if declare -f find_source > /dev/null 2>&1; then
        src_cfg=$(find_source "groq/local-settings.json")
    fi

    if [ -z "$src_cfg" ]; then
        mac_model="$(_detect_profile)"
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/$mac_model/groq/local-settings.json"
    fi

    if [ -f "$src_cfg" ]; then
        [ -f "$_groq_cfg" ] && backup_groq
        cp "$src_cfg" "$_groq_cfg"
        print_status "Deployed Groq config to $_groq_cfg"
    else
        print_warning "No Groq config found at $src_cfg"
    fi

    print_info ""
    print_info "=== Groq setup ==="
    print_info "Add your API key to ~/.env.local:"
    print_info "  GROQ_API_KEY=gsk_..."
    print_info "Get a key at: https://console.groq.com/keys"
    print_info ""
}

backup_groq() {
    if [ -f "$_groq_cfg" ]; then
        cp "$_groq_cfg" "$BACKUP_DIR/groq_settings_backup_$DATE.json"
        print_status "Backed up Groq config"
    fi
}

restore_groq() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/groq_settings_backup_*.json 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_groq_cfg_dir"
        cp "$latest_file" "$_groq_cfg"
        print_status "Restored Groq config from $(basename "$latest_file")"
    else
        print_warning "No Groq config backup found in $BACKUP_DIR"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_groq
fi
