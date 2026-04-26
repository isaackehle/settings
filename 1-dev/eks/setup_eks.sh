. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_eks() {
    print_info "Installing eksctl..."
    brew install eksctl && return 0
    return 1
}

verify_eks() {
    check_tool_with_version "eksctl" "eksctl"
}

setup_eks() {
    print_info "Setting up EKS..."

    verify_eks || _install_eks || { print_warning "eksctl not installed — skipping"; return 1; }

    print_info ""
    print_info "=== EKS ==="
    print_info "Create cluster: eksctl create cluster --name my-cluster --region us-east-1"
    print_info "Kubeconfig:     aws eks update-kubeconfig --name my-cluster --region us-east-1"
    print_info "List clusters:  aws eks list-clusters --region us-east-1"
    print_info "Docs:           https://docs.aws.amazon.com/eks/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_eks
fi
