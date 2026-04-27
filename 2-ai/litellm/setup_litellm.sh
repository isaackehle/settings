#!/opt/homebrew/bin/bash
# Setup LiteLLM proxy

set -euo pipefail

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
. "${SETTINGS_BASE}/helpers.sh"

setup_litellm() {
    print_info "Setting up LiteLLM proxy..."


    pyenv install 3.13
    pyenv local 3.13

}

setup_litellm() {
    print_info "Setting up LiteLLM proxy..."

    verify_litellm || _install_litellm || { print_error "Failed to install litellm"; return 1; }

    setup_litellm_postgres

    _generate_prisma_client

    mkdir -p "$_local_dir"

    local src_cfg mac_model script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    if declare -f find_source > /dev/null 2>&1; then
        src_cfg=$(find_source "litellm/litellm.yaml")
    fi
    if [ -z "$src_cfg" ]; then
        mac_model="$(_detect_profile)"
        src_cfg="$script_dir/$mac_model/litellm/litellm.yaml"
    fi

    if [ -f "$src_cfg" ]; then
        if [ -f "$_local_cfg" ]; then
            backup_litellm
        fi
        cp "$src_cfg" "$_local_cfg"
        print_status "Deployed litellm config ($mac_model) to $_local_cfg"
    else
        print_warning "No source config found at $src_cfg — skipping config deploy"
    fi

    # Deploy .env (always overwrite so repo changes take effect)
    local env_file="$_local_dir/.env"
    local env_src
    env_src="$(find_source "litellm/.env" 2>/dev/null)"
    [ -z "$env_src" ] && env_src="$SETTINGS_BASE/litellm/.env"
    if [ -f "$env_src" ]; then
        cp "$env_src" "$env_file"
        print_status "Deployed .env to $env_file"
    else
        print_warning "No .env source found at $env_src — skipping .env deploy"
    fi

    # Configure litellm to run as a user-level service on port 4000 (optional)
    if command_exists "launchctl"; then
        local src_plist="$SETTINGS_BASE/litellm/ai.litellm.proxy.plist"

        cp $src_plist $HOME/Library/LaunchAgents

        print_info "Creating a directory for litellm service at location $_svc_dir..."
        sudo mkdir -p $_svc_dir 2>/dev/null || true

        print_info "Copying config to service location $_svc_cfg..."
        sudo cp "$src_cfg" "$_svc_cfg"

        print_info "Creating symbolic link for litellm executable..."
        sudo ln -sf $HOME/.local/share/uv/tools/litellm/bin/litellm $_svc_dir/litellm

        # Bootstrap the service (unload first in case it's already registered)
        local plist="$HOME/Library/LaunchAgents/ai.litellm.proxy.plist"
        local gui="gui/$(id -u)"
        launchctl bootout "$gui" "$plist" 2>/dev/null || true
        launchctl bootstrap "$gui" "$plist"

        print_info ""
        print_info "=== LiteLLM usage ==="
        print_info "Start proxy:   launchctl start ai.litellm.proxy"
    else
        print_warning "launchctl not found — skipping service setup (run litellm --config $_local_cfg --port 4000 to start)"

        print_info ""
        print_info "=== LiteLLM usage ==="
        print_info "Start proxy:   litellm --config $_local_cfg --port 4000"
    fi

    print_info "Web UI:        http://localhost:4000"
    print_info "API endpoint:  http://localhost:4000/v1  (OpenAI-compatible)"
    print_info "Master key:    set LITELLM_MASTER_KEY in $_local_dir/.env"
    print_info "DB container:  docker start litellm-postgres"
    print_info ""
}

restore_litellm() {
    local latest_file
    latest_file=$(ls -t "$BACKUP_DIR"/litellm_config_backup_*.yaml 2>/dev/null | head -1)
    if [ -n "$latest_file" ]; then
        mkdir -p "$_local_dir"
        cp "$latest_file" "$_local_cfg"
        print_status "Restored litellm config from $(basename "$latest_file")"
    else
        print_warning "No litellm config backup found in $BACKUP_DIR"
    fi
}

backup_litellm() {
    if [ -f "$_local_cfg" ]; then
        cp "$_local_cfg" "$BACKUP_DIR/litellm_config_backup_$DATE.yaml"
        print_status "Backed up litellm config"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SETTINGS_BASE="$(dirname "${BASH_SOURCE[0]}")/.."
    setup_litellm
fi


# TBD:
# docker pull docker.litellm.ai/berriai/litellm:main-latest
# https://docs.litellm.ai/docs/proxy/deploy
