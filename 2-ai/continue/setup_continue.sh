#!/opt/homebrew/bin/bash
# setup_continue.sh — Setup and configuration for Continue

set -euo pipefail

# Environment Setup
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_continue_extension() {
    print_info "Installing Continue VS Code extension..."
    if command_exists "code"; then
        code --install-extension continue.continue && print_status "Continue extension installed"
        return 0
    else
        print_warning "VS Code CLI (code) not found — install extension from Marketplace"
        return 1
    fi
}

_install_continue_cli() {
    print_info "Installing Continue terminal agent..."
    if curl -fsSL https://raw.githubusercontent.com/continuedev/continue/main/extensions/cli/scripts/install.sh | bash; then
        print_status "Continue terminal agent installed"
        return 0
    else
        print_error "Failed to install Continue terminal agent"
        return 1
    fi
}

verify_continue() {
    local installed=0

    # Verify Extension
    extension_version=$(check_vscode_extension "continue.continue" 2>/dev/null)
    if [ -n "$extension_version" ]; then
        print_status "Continue VS Code extension 'continue.continue' is installed: $extension_version"
    else
        print_warning "Continue VS Code extension not found"
        installed=1
    fi

    # Verify CLI (cn)
    if command_exists "cn"; then
        print_status "Continue terminal agent (cn) is installed: $(cn --version)"
    else
        print_warning "Continue terminal agent (cn) not found"
        installed=1
    fi

    return $installed
}

setup_continue() {
    print_info "Setting up Continue..."

    if ! verify_continue; then
        _install_continue_extension || true
        _install_continue_cli || true

        # Final verification
        if ! verify_continue; then
            print_error "Some Continue components failed to install"
        fi
    else
        print_status "Continue is already fully installed"
    fi

    print_success "Continue setup complete."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_continue
fi
