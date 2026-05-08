. "${REPO_ROOT}/utils.sh"
. "${REPO_ROOT}/helpers.sh"

# Install PyTorch — ML framework. Uses the Apple Silicon (MPS) variant on macOS.

_install_pytorch() {
    if command_exists "uv"; then
        print_info "Installing PyTorch via uv..."
        uv pip install torch torchvision torchaudio && return 0
    fi
    if command_exists "pip3"; then
        print_info "Installing PyTorch via pip..."
        pip3 install torch torchvision torchaudio && return 0
    fi
    print_warning "Neither uv nor pip available — see https://pytorch.org/get-started/locally/"
    return 1
}

verify_pytorch() {
    if python3 -c "import torch" 2>/dev/null; then
        local ver
        ver=$(python3 -c "import torch; print(torch.__version__)" 2>/dev/null)
        local mps
        mps=$(python3 -c "import torch; print('MPS available' if torch.backends.mps.is_available() else 'MPS not available')" 2>/dev/null)
        print_status "PyTorch $ver — $mps"
        return 0
    fi
    print_warning "PyTorch not installed"
    return 1
}

setup_pytorch() {
    print_info "Setting up PyTorch..."
    verify_pytorch || _install_pytorch || { print_warning "PyTorch not installed — skipping"; return 1; }

    print_info ""
    print_info "=== PyTorch ==="
    print_info "Apple Silicon GPU (MPS): torch.device('mps')"
    print_info "Check:   python3 -c \"import torch; print(torch.backends.mps.is_available())\""
    print_info "Docs:    https://pytorch.org/docs"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pytorch
fi
