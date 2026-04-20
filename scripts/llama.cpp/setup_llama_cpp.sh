. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install llama.cpp — C++ LLM inference engine with OpenAI-compatible server.

_install_llama_cpp() {
    if command_exists "brew"; then
        print_info "Installing llama.cpp via Homebrew..."
        brew install llama.cpp && return 0
    fi
    print_warning "Homebrew not available — build from source: https://github.com/ggerganov/llama.cpp"
    return 1
}

verify_llama_cpp() {
    check_tool_with_version "llama.cpp" "llama-cli"
}

setup_llama_cpp() {
    print_info "Setting up llama.cpp..."
    verify_llama_cpp || _install_llama_cpp || { print_warning "llama.cpp not installed — skipping"; return 1; }

    print_info ""
    print_info "=== llama.cpp ==="
    print_info "CLI inference:    llama-cli -m model.gguf -p 'prompt'"
    print_info "OpenAI server:    llama-server -m model.gguf --port 8080"
    print_info "API endpoint:     http://localhost:8080/v1"
    print_info "Models:           download .gguf files from https://huggingface.co"
    print_info "GPU offload:      add -ngl 99 flag to offload layers to Metal/CUDA"
    print_info "Docs:             https://github.com/ggerganov/llama.cpp"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_llama_cpp
fi
