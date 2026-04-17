. "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

# Set up exo — distributed split inference across Apple Silicon devices
# exo shards model layers across multiple Macs, reducing per-device memory requirements.
# Slower per-token than a single machine (network latency), but enables larger models.
setup_exo() {
    print_info "Setting up exo (distributed Apple Silicon inference)..."

    if ! command_exists "python3"; then
        print_error "Python 3 is required for exo. Install from: https://python.org"
        return 1
    fi

    if ! command_exists "exo"; then
        print_info "Installing exo-inference via pip..."
        pip install exo-inference
    else
        print_status "exo already installed: $(exo --version 2>&1 | head -1)"
    fi

    print_info ""
    print_info "=== exo usage ==="
    print_info "Start on this machine:  exo"
    print_info "Start on other Macs:    exo   (same command — peers auto-discover via mDNS)"
    print_info "API endpoint:           http://0.0.0.0:52415/v1"
    print_info ""
    print_info "To use exo with opencode/Continue, update the baseURL in configs:"
    print_info "  opencode:  change baseURL to http://127.0.0.1:52415/v1"
    print_info "  Continue:  change provider options apiBase to http://127.0.0.1:52415/v1"
    print_info ""
    print_info "Use case: model too large for one machine's RAM — exo splits layers across"
    print_info "devices. Requires all Macs on the same local network. Wired > WiFi for speed."
    print_warning "Token throughput will be lower than single-machine inference over WiFi."
    print_info ""
    print_info "Docs: https://github.com/exo-explore/exo"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_exo
fi
