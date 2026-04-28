if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Set up Hugging Face CLI for model downloads, dataset access, and Hub interaction.

_install_huggingface() {
    if command_exists "uv"; then
        log_info "Installing huggingface_hub via uv..."
        uv tool install "huggingface_hub[cli]" && return 0
    fi
    if command_exists "pip3"; then
        log_info "Installing huggingface_hub via pip..."
        pip3 install -U "huggingface_hub[cli]" && return 0
    fi
    log_warning "Neither uv nor pip available — install manually: pip install 'huggingface_hub[cli]'"
    return 1
}

verify_huggingface() {
    check_tool_with_version "Hugging Face CLI" "huggingface-cli"
}

setup_huggingface() {
    log_info "Setting up Hugging Face CLI..."
    verify_huggingface || _install_huggingface || { log_warning "HF CLI not installed — skipping"; return 1; }

    log_info ""
    log_info "=== Hugging Face CLI ==="
    log_info "Login:      huggingface-cli login"
    log_info "            (get token at https://huggingface.co/settings/tokens)"
    log_info "Download:   huggingface-cli download <repo-id> --local-dir ./models"
    log_info "Cache:      ~/.cache/huggingface/hub/"
    log_info "Docs:       https://huggingface.co/docs/huggingface_hub/guides/cli"
    log_info ""
    log_warning "Run 'huggingface-cli login' to authenticate before downloading gated models"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_huggingface
fi
