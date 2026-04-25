. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Authentication & Passwords
# Password managers and MFA tools.
#
# Installation:
# 1Password (CLI + app)
# brew install --cask 1password
# brew install 1password-cli
#
# 2FAS — TOTP MFA
# brew install --cask 2fas
#
# KeePassXC — open-source password manager
# brew install --cask keepassxc
#
# Proton Pass
# brew install --cask proton-pass
#
# Configuration:
# Set up your vaults and MFA seeds on first launch.
#
# Start / Usage:
# Start: Open the app from Applications.

setup_auth() {
    print_info "Setting up Authentication & Passwords..."

    print_info "Installing 1Password..."
    brew install --cask 1password
    brew install 1password-cli

    print_info "Installing 2FAS..."
    brew install --cask 2fas

    print_info "Installing KeePassXC..."
    brew install --cask keepassxc

    print_info "Installing Proton Pass..."
    brew install --cask proton-pass

    print_status "Authentication & Passwords setup complete. Open the apps from Applications to complete configuration."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_auth
fi