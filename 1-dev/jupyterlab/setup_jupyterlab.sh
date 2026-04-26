. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_jupyterlab() {
    print_info "Installing JupyterLab..."
    pip3 install jupyterlab && return 0
    return 1
}

verify_jupyterlab() {
    check_tool_with_version "JupyterLab" "jupyter"
}

setup_jupyterlab() {
    print_info "Setting up JupyterLab..."

    verify_jupyterlab || _install_jupyterlab || { print_warning "JupyterLab not installed — skipping"; return 1; }

    print_info ""
    print_info "=== JupyterLab ==="
    print_info "Launch:        jupyter lab"
    print_info "Docs:          https://jupyterlab.readthedocs.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_jupyterlab
fi
