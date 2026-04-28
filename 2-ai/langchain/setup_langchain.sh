if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/helpers.sh"

# Install LangChain Python package for building LLM-powered applications.

_install_langchain() {
    if command_exists "uv"; then
        print_info "Installing langchain via uv..."
        uv pip install langchain langchain-community langchain-ollama && return 0
    fi
    if command_exists "pip3"; then
        print_info "Installing langchain via pip..."
        pip3 install langchain langchain-community langchain-ollama && return 0
    fi
    print_warning "Neither uv nor pip available — install manually: pip install langchain"
    return 1
}

verify_langchain() {
    if python3 -c "import langchain" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import langchain; print(langchain.__version__)" 2>/dev/null)
        print_status "LangChain installed: $ver"
        return 0
    fi
    print_warning "LangChain not installed"
    return 1
}

setup_langchain() {
    print_info "Setting up LangChain..."
    verify_langchain || _install_langchain || { print_warning "LangChain not installed — skipping"; return 1; }

    print_info ""
    print_info "=== LangChain ==="
    print_info "Import:  from langchain_ollama import ChatOllama"
    print_info "Docs:    https://python.langchain.com/docs"
    print_info "Ollama:  langchain-ollama package provides native Ollama integration"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_langchain
fi
