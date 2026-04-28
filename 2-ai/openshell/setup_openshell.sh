. "${REPO_ROOT}/utils.sh"
. "${REPO_ROOT}/helpers.sh"

# Install OpenShell — NVIDIA's sandboxed runtime for AI coding agents.
# Requires Docker running locally (Rancher Desktop or Colima).

_install_openshell_binary() {
    print_info "Installing OpenShell via curl..."
    curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh && return 0
    return 1
}

_install_openshell_uv() {
    if command_exists "uv"; then
        print_info "Installing OpenShell via uv..."
        uv tool install -U openshell && return 0
    fi
    return 1
}

_install_openshell() {
    _install_openshell_binary || _install_openshell_uv || {
        print_warning "OpenShell install failed — install manually"
        print_info "  curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh"
        return 1
    }
}

verify_openshell() {
    check_tool_with_version "OpenShell" "openshell"
}

setup_openshell() {
    print_info "Setting up OpenShell..."

    if ! command_exists "docker"; then
        print_warning "Docker not running — OpenShell requires Docker (Rancher Desktop or Colima)"
    fi

    verify_openshell || _install_openshell || { print_warning "OpenShell not installed — skipping"; return 1; }

    print_info ""
    print_info "=== OpenShell ==="
    print_info "Launch sandbox:   openshell sandbox create -- claude"
    print_info "List sandboxes:   openshell sandbox list"
    print_info "Connect:          openshell sandbox connect [name]"
    print_info "Providers:        openshell provider create --type anthropic --from-existing"
    print_info "Docs:             https://github.com/NVIDIA/OpenShell"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_openshell
fi
