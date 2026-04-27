#!/opt/homebrew/bin/bash

update_litellm_yaml() {
    local machine_dir="$1"
    local old_colon="$2"
    local new_colon="$3"

    local old_dash new_dash
    old_dash=$(colon_to_dash "$old_colon")
    new_dash=$(colon_to_dash "$new_colon")
    local litellm_file="$machine_dir/litellm/litellm.yaml"

    if [[ ! -f "$litellm_file" ]]; then
        log_warn "LiteLLM config not found: $litellm_file"
        return
    fi

    log_info "Updating $(basename "$machine_dir")/litellm/litellm.yaml..."

    # model_name: qwen3-coder-30b-q5-32k   (unquoted dash form)
    sed -i '' "s|model_name: ${old_dash}|model_name: ${new_dash}|g" "$litellm_file"

    # model: ollama_chat/qwen3-coder-30b:q5-32k   (colon form)
    sed -i '' "s|ollama_chat/${old_colon}|ollama_chat/${new_colon}|g" "$litellm_file"

    # router alias values: "qwen3-coder-30b-q5-32k"  (quoted dash form)
    sed -i '' "s|\"${old_dash}\"|\"${new_dash}\"|g" "$litellm_file"

    log_success "  $(basename "$machine_dir")/litellm/litellm.yaml"
}
