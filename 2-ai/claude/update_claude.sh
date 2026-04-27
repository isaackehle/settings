#!/opt/homebrew/bin/bash

update_claude_settings() {
    local machine_dir="$1"
    local old_model="$2"
    local new_model="$3"

    local claude_config="$machine_dir/claude/claude.json"

    if [[ ! -f "$claude_config" ]]; then
        log_warn "Claude config not found: $claude_config"
        return
    fi

    log_info "Updating $(basename "$machine_dir")/claude/claude.json..."

    # Update the model name in claude.json
    sed -i '' "s|\"${old_model}\"|\"${new_model}\"|g" "$claude_config"

    log_success "  $(basename "$machine_dir")/claude/claude.json"
}