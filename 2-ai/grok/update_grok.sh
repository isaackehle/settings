#!/opt/homebrew/bin/bash

update_grok_config() {
    local machine_dir="$1"
    local old_model="$2"
    local new_model="$3"

    local grok_config="$machine_dir/grok/config.json"

    if [[ ! -f "$grok_config" ]]; then
        log_warn "Grok config not found: $grok_config"
        return
    fi

    log_info "Updating $(basename "$machine_dir")/grok/config.json..."

    # Update the model name in config.json
    sed -i '' "s|\"${old_model}\"|\"${new_model}\"|g" "$grok_config"

    log_success "  $(basename "$machine_dir")/grok/config.json"
}