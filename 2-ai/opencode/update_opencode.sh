#!/opt/homebrew/bin/bash

update_opencode_config() {
    local machine_dir="$1"
    local old_model="$2"
    local new_model="$3"

    local opencode_config="$machine_dir/opencode/config.json"

    if [[ ! -f "$opencode_config" ]]; then
        log_warn "OpenCode config not found: $opencode_config"
        return
    fi

    log_info "Updating $(basename "$machine_dir")/opencode/config.json..."

    # Update the model name in config.json
    sed -i '' "s|\"${old_model}\"|\"${new_model}\"|g" "$opencode_config"

    log_success "  $(basename "$machine_dir")/opencode/config.json"
}