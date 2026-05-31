if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Set up Hugging Face CLI for model downloads, dataset access, and Hub interaction.

_install_huggingface() {
    if command_exists "uv"; then
        log_info "Installing huggingface_hub via uv..."
        uv tool install "huggingface_hub[hf_xet,cli]" && return 0
    fi
    if command_exists "pip3"; then
        log_info "Installing huggingface_hub via pip..."
        pip3 install -U "huggingface_hub[hf_xet,cli]" && return 0
    fi
    log_warning "Neither uv nor pip available — install manually: pip install 'huggingface_hub[hf_xet,cli]'"
    return 1
}

verify_huggingface() {
    check_tool_with_version "Hugging Face CLI" "hf"
}

# Check whether the user is authenticated with Hugging Face.
# Returns 0 if logged in, 1 if not (or if the CLI is not available).
# Prints a wizard-friendly hint when auth is missing — does NOT block or prompt.
verify_hf_auth() {
    local hf_cli="${HF_CLI_BIN:-huggingface-cli}"

    if ! command -v "$hf_cli" >/dev/null 2>&1; then
        log_warning "HF CLI not installed — cannot verify auth"
        return 1
    fi

    local whoami_output
    if whoami_output="$("$hf_cli" auth whoami 2>&1)"; then
        local username
        username="$(echo "$whoami_output" | head -1)"
        log_info "Hugging Face: logged in as $username"
        return 0
    else
        log_warning "Not logged in to Hugging Face"
        log_info "  Gated models (e.g. Llama, Gemma) require authentication."
        log_info "  Run:  $hf_cli auth login"
        log_info "  Token: https://huggingface.co/settings/tokens"
        return 1
    fi
}

setup_huggingface() {
    log_info "Setting up Hugging Face CLI..."
    verify_huggingface || _install_huggingface || { log_warning "HF CLI not installed — skipping"; return 1; }

    log_info ""
    log_info "=== Hugging Face CLI (hf) ==="
    log_info "Login:      hf auth login"
    log_info "            (get token at https://huggingface.co/settings/tokens)"
    log_info "Download:   hf download <repo-id> --local-dir ./models"
    log_info "Cache:      ~/.cache/huggingface/hub/"
    log_info "Docs:       https://huggingface.co/docs/huggingface_hub/guides/cli"
    log_info ""
    log_warning "Run 'hf auth login' to authenticate before downloading gated models"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_huggingface
fi
