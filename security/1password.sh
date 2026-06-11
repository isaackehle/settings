#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

_install_1password() {
    print_info "Installing 1Password app and CLI..."
    brew install --cask 1password
    brew install 1password-cli
}

verify_1password() {
    # Verify both the app cask and the cli tool
    brew list --cask 1password &>/dev/null && command_exists "op"
}

setup_1password() {
    print_info "Setting up 1Password..."
    verify_1password || _install_1password || { print_error "Failed to install 1Password"; return 1; }
    print_status "1Password setup complete. Please set up your vaults on first launch."
}

setup_1password_service_account() {
    local sa_name="${1:-cli-automation}"

    print_step "1Password Service Account: $sa_name"

    # Prerequisites
    command_exists op || { print_error "1Password CLI not installed. Run setup_1password first."; return 1; }
    op whoami &>/dev/null || { print_error "Not signed in to 1Password. Unlock the desktop app first."; return 1; }

    # List eligible vaults (skip Private and Shared — service accounts can't access them)
    print_info "Fetching vaults..."
    local vaults
    vaults=$(op vault list --format json 2>/dev/null | python3 -c "
import json, sys
vaults = json.load(sys.stdin)
for v in vaults:
    if v['name'] not in ('Private', 'Shared'):
        print(f\"{v['name']}|{v['items']}\")
") || { print_error "Failed to list vaults."; return 1; }

    echo "  Eligible vaults:"
    local vault_args=() vault_count=0
    while IFS='|' read -r vname vitems; do
        [ -z "$vname" ] && continue
        echo "    [$((vault_count + 1))] $vname ($vitems items)"
        vault_args+=("--vault" "${vname}:read_items,write_items")
        ((vault_count++))
    done <<< "$vaults"

    if [ "$vault_count" -eq 0 ]; then
        print_error "No eligible vaults found."
        return 1
    fi

    print_info "Creating service account with full access to $vault_count vaults..."

    # Create the service account
    local token
    token=$(op service-account create "$sa_name" "${vault_args[@]}" --raw 2>&1) || {
        print_error "Failed to create service account: $(echo "$token" | head -1)"
        return 1
    }

    print_success "Service account '$sa_name' created."

    # Save token to a vault
    local store_vault
    read -rp "Save token in which vault? [dev]: " store_vault
    store_vault="${store_vault:-dev}"

    if op item create \
        --category "API Credential" \
        --title "Service Account - $sa_name" \
        --vault "$store_vault" \
        "credential type=Service Account" \
        "token=$token" \
        --format json &>/dev/null; then
        print_success "Token saved to op://$store_vault/Service Account - $sa_name/token"
    else
        print_warning "Could not save token to vault '$store_vault'. Token shown below — save it manually."
        echo "  $token"
    fi

    echo ""
    echo "To use this token in your shell, add:"
    echo "  export OP_SERVICE_ACCOUNT_TOKEN=\$(op read \"op://$store_vault/Service Account - $sa_name/token\")"
    echo ""
    echo "Or source a profile.d file if your dotfiles support it:"
    echo "  # ~/.profile.d/_1password"
    echo "  command -v op >/dev/null 2>&1 || return 0"
    echo "  export OP_SERVICE_ACCOUNT_TOKEN"
    echo "  OP_SERVICE_ACCOUNT_TOKEN=\$(op read \"op://$store_vault/Service Account - $sa_name/token\" 2>/dev/null)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_1password
fi