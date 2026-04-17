. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Set up LiteLLM proxy — unified OpenAI-compatible API gateway in front of Ollama (and other providers).
# Reads model_list from a YAML config and exposes a single :4000 endpoint for all tools.

_install_litellm() {
    if command_exists "uv"; then
        print_info "Installing litellm[proxy] via uv..."
        uv tool install 'litellm[proxy]' && return 0
    fi
    if command_exists "pip3" || command_exists "pip"; then
        print_info "Installing litellm[proxy] via pip..."
        pip3 install 'litellm[proxy]' 2>/dev/null || pip install 'litellm[proxy]' && return 0
    fi
    print_error "Neither uv nor pip found. Install Python 3 or uv first."
    return 1
}

verify_litellm() {
    check_tool_with_version "litellm" "litellm --version"
}

_litellm_cfg_dir="$HOME/.config/litellm"
_litellm_cfg="$_litellm_cfg_dir/config.yaml"

setup_litellm() {
    print_info "Setting up LiteLLM proxy..."
    verify_litellm || _install_litellm || { print_error "Failed to install litellm"; return 1; }

    mkdir -p "$_litellm_cfg_dir"

    local src_cfg="$SCRIPT_DIR/litellm/litellm.yaml"
    if [ -f "$src_cfg" ]; then
        if [ -f "$_litellm_cfg" ]; then
            backup_litellm
        fi
        cp "$src_cfg" "$_litellm_cfg"
        print_status "Deployed litellm config to $_litellm_cfg"
    else
        print_warning "No source config found at $src_cfg — skipping config deploy"
    fi

    print_info ""
    print_info "=== LiteLLM usage ==="
    print_info "Start proxy:   litellm --config $_litellm_cfg"
    print_info "API endpoint:  http://localhost:4000/v1  (OpenAI-compatible)"
    print_info "Master key:    set in config under general_settings.master_key"
    print_info "Edit models:   $_litellm_cfg"
    print_info ""
}

restore_litellm() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/litellm_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_litellm_cfg_dir"
        cp "$latest_file" "$_litellm_cfg"
        print_status "Restored litellm config from $(basename "$latest_file")"
    else
        print_warning "No litellm config backup found in $BACKUP_DIR"
    fi
}

backup_litellm() {
    if [ -f "$_litellm_cfg" ]; then
        cp "$_litellm_cfg" "$BACKUP_DIR/litellm_config_backup_$DATE.yaml"
        print_status "Backed up litellm config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_litellm
fi


# TBD:
# docker pull docker.litellm.ai/berriai/litellm:main-latest
# https://docs.litellm.ai/docs/proxy/deploy