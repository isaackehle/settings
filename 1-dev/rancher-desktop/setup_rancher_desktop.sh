. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_rancher_desktop() {
    print_info "Installing Rancher Desktop..."
    brew install --cask rancher && return 0
    return 1
}

verify_rancher_desktop() {
    check_tool_with_version "Rancher Desktop" "rdctl"
}

setup_rancher_desktop() {
    print_info "Setting up Rancher Desktop..."

    verify_rancher_desktop || _install_rancher_desktop || { print_warning "Rancher Desktop not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Rancher Desktop ==="
    print_info "Launch:        Open Rancher Desktop from Applications"
    print_info "Cluster info:  kubectl cluster-info"
    print_info "Get nodes:     kubectl get nodes"
    print_info "Docs:          https://docs.rancherdesktop.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_rancher_desktop
fi
