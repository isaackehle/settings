. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_aws() {
    print_info "Installing AWS CLI and tools..."
    brew install awscli \
        && brew install 99designs/tap/aws-vault \
        && return 0
    return 1
}

verify_aws() {
    check_tool_with_version "AWS CLI" "aws"
}

setup_aws() {
    print_info "Setting up AWS..."

    verify_aws || _install_aws || { print_warning "AWS CLI not installed — skipping"; return 1; }

    print_info ""
    print_info "=== AWS CLI ==="
    print_info "Configure:     aws configure"
    print_info "SSO:           aws configure sso"
    print_info "Identity:      aws sts get-caller-identity"
    print_info "Vault add:     aws-vault add default"
    print_info "Vault exec:    aws-vault exec default -- zsh"
    print_info "Docs:          https://docs.aws.amazon.com/cli/latest/userguide/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_aws
fi
