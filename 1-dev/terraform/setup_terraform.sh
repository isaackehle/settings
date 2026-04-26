. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_terraform() {
    print_info "Installing Terraform..."
    brew install terraform tfswitch && return 0
    return 1
}

verify_terraform() {
    check_tool_with_version "Terraform" "terraform"
}

setup_terraform() {
    print_info "Setting up Terraform..."

    verify_terraform || _install_terraform || { print_warning "Terraform not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Terraform ==="
    print_info "Init:          terraform init"
    print_info "Plan:          terraform plan"
    print_info "Apply:         terraform apply"
    print_info "Destroy:       terraform destroy"
    print_info "Docs:          https://developer.hashicorp.com/terraform/docs"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_terraform
fi
