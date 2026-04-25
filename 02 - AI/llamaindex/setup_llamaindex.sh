. "$(dirname "${BASH_SOURCE[0]}")/../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Install LlamaIndex — data framework for LLM applications (RAG, agents, indexing).

_install_llamaindex() {
    if command_exists "uv"; then
        print_info "Installing llama-index via uv..."
        uv pip install llama-index llama-index-llms-ollama && return 0
    fi
    if command_exists "pip3"; then
        print_info "Installing llama-index via pip..."
        pip3 install llama-index llama-index-llms-ollama && return 0
    fi
    print_warning "Neither uv nor pip available — install manually: pip install llama-index"
    return 1
}

verify_llamaindex() {
    if python3 -c "import llama_index" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import llama_index; print(llama_index.__version__)" 2>/dev/null || echo "installed")
        print_status "LlamaIndex installed: $ver"
        return 0
    fi
    print_warning "LlamaIndex not installed"
    return 1
}

setup_llamaindex() {
    print_info "Setting up LlamaIndex..."
    verify_llamaindex || _install_llamaindex || { print_warning "LlamaIndex not installed — skipping"; return 1; }

    print_info ""
    print_info "=== LlamaIndex ==="
    print_info "Ollama:   llama-index-llms-ollama provides native Ollama integration"
    print_info "Docs:     https://docs.llamaindex.ai"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_llamaindex
fi
