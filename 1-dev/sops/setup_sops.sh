. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_sops() {
    print_info "Installing SOPS..."
    brew install sops && return 0
    return 1
}

verify_sops() {
    check_tool_with_version "SOPS" "sops"
}

setup_sops() {
    print_info "Setting up SOPS..."

    verify_sops || _install_sops || { print_warning "SOPS not installed — skipping"; return 1; }

    print_info ""
    print_info "=== SOPS ==="
    print_info "Encrypt:       sops --encrypt secrets.yaml > secrets.enc.yaml"
    print_info "Edit:          sops secrets.enc.yaml"
    print_info "Decrypt:       sops --decrypt secrets.enc.yaml"
    print_info "Set editor:    export EDITOR='code -w'"
    print_info "Docs:          https://github.com/getsops/sops"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_sops
fi
