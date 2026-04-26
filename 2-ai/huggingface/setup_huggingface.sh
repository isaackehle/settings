. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up Hugging Face CLI for model downloads, dataset access, and Hub interaction.

_install_huggingface() {
    if command_exists "uv"; then
        print_info "Installing huggingface_hub via uv..."
        uv tool install "huggingface_hub[cli]" && return 0
    fi
    if command_exists "pip3"; then
        print_info "Installing huggingface_hub via pip..."
        pip3 install -U "huggingface_hub[cli]" && return 0
    fi
    print_warning "Neither uv nor pip available — install manually: pip install 'huggingface_hub[cli]'"
    return 1
}

verify_huggingface() {
    check_tool_with_version "Hugging Face CLI" "huggingface-cli"
}

setup_huggingface() {
    print_info "Setting up Hugging Face CLI..."
    verify_huggingface || _install_huggingface || { print_warning "HF CLI not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Hugging Face CLI ==="
    print_info "Login:      huggingface-cli login"
    print_info "            (get token at https://huggingface.co/settings/tokens)"
    print_info "Download:   huggingface-cli download <repo-id> --local-dir ./models"
    print_info "Cache:      ~/.cache/huggingface/hub/"
    print_info "Docs:       https://huggingface.co/docs/huggingface_hub/guides/cli"
    print_info ""
    print_warning "Run 'huggingface-cli login' to authenticate before downloading gated models"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_huggingface
fi
