. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install vLLM — high-throughput LLM inference server with OpenAI-compatible API.
# Note: vLLM has limited macOS support. Full GPU acceleration requires Linux + NVIDIA GPU.
# On Apple Silicon, CPU-only mode is available but slow for large models.

_install_vllm() {
    if command_exists "uv"; then
        print_info "Installing vllm via uv..."
        uv pip install vllm && return 0
    fi
    if command_exists "pip3"; then
        print_info "Installing vllm via pip..."
        pip3 install vllm && return 0
    fi
    print_warning "Neither uv nor pip available — install manually: pip install vllm"
    return 1
}

verify_vllm() {
    if python3 -c "import vllm" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import vllm; print(vllm.__version__)" 2>/dev/null || echo "installed")
        print_status "vLLM installed: $ver"
        return 0
    fi
    print_warning "vLLM not installed"
    return 1
}

setup_vllm() {
    print_info "Setting up vLLM..."
    print_warning "vLLM is optimized for Linux + NVIDIA GPU. macOS support is limited."
    verify_vllm || _install_vllm || { print_warning "vLLM not installed — skipping"; return 1; }

    print_info ""
    print_info "=== vLLM ==="
    print_info "Start server:   python3 -m vllm.entrypoints.openai.api_server --model <model>"
    print_info "API endpoint:   http://localhost:8000/v1"
    print_info "Docker (recommended on mac):"
    print_info "  docker run --runtime nvidia --gpus all -p 8000:8000 vllm/vllm-openai:latest --model <model>"
    print_info "Docs:           https://docs.vllm.ai"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_vllm
fi
