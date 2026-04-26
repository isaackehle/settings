. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_helm() {
    print_info "Installing Helm..."
    brew install helm && return 0
    return 1
}

verify_helm() {
    check_tool_with_version "Helm" "helm"
}

setup_helm() {
    print_info "Setting up Helm..."

    verify_helm || _install_helm || { print_warning "Helm not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Helm ==="
    print_info "Search:        helm search hub <package>"
    print_info "Install:       helm install <release> <chart> -n <ns> --create-namespace"
    print_info "List:          helm list -A"
    print_info "Add repo:      helm repo add bitnami https://charts.bitnami.com/bitnami"
    print_info "Docs:          https://helm.sh/docs/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_helm
fi
