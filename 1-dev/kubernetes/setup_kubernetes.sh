. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_kubernetes() {
    print_info "Installing Kubernetes tools..."
    brew install kubernetes-cli kubectx minikube
}

verify_kubernetes() {
    check_tool_with_version "kubectl" "kubectl"
}

setup_kubernetes() {
    print_info "Setting up Kubernetes..."

    verify_kubernetes || _install_kubernetes || { print_warning "kubectl not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Kubernetes ==="
    print_info "Get pods:      kubectl get pods"
    print_info "Switch ctx:    kubectx <cluster-name>"
    print_info "Local cluster: minikube start"
    print_info "Package mgr:   see ../helm/"
    print_info "Terminal UI:   see ../k9s/"
    print_info "Docs:          https://kubernetes.io/docs/home/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kubernetes
fi
