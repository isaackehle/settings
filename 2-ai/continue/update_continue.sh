#!/opt/homebrew/bin/bash

update_continue_config() {
    local machine_dir="$1"
    local old_model="$2"
    local new_model="$3"

    local continue_config="$machine_dir/continue/config.json"

    if [[ ! -f "$continue_config" ]]; then
        log_warn "Continue config not found: $continue_config"
        return
    fi

    log_info "Updating $(basename "$machine_dir")/continue/config.json..."

    # Update the model name in config.json
    sed -i '' "s|\"${old_model}\"|\"${new_model}\"|g" "$continue_config"

    log_success "  $(basename "$machine_dir")/continue/config.json"
}