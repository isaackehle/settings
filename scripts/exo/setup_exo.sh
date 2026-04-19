. "$(dirname "${BASH_SOURCE[0]}")/../helpers.sh"

# Set up exo — distributed split inference across Apple Silicon devices
# exo shards model layers across multiple Macs, reducing per-device memory requirements.
# Slower per-token than a single machine (network latency), but enables larger models.
setup_exo() {
    print_info "Setting up exo (distributed Apple Silicon inference)..."

    local exo_dir="$HOME/code/exo"

    # --- Prerequisites ---
    if ! command_exists "uv"; then
        print_info "Installing uv (Python package manager)..."
        brew install uv || { print_error "brew install uv failed"; return 1; }
    fi

    if ! command_exists "node"; then
        print_info "Installing node..."
        brew install node || { print_error "brew install node failed"; return 1; }
    fi

    if ! command_exists "rustup"; then
        print_info "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env"
    fi

    if ! rustup toolchain list 2>/dev/null | grep -q nightly; then
        print_info "Installing Rust nightly toolchain..."
        rustup toolchain install nightly
    fi

    # macmon — use pinned fork to avoid crashes on M5
    if ! command_exists "macmon"; then
        print_info "Installing macmon (pinned fork — M5 compatible)..."
        cargo install \
            --git https://github.com/vladkels/macmon \
            --rev a1cd06b6cc0d5e61db24fd8832e74cd992097a7d \
            macmon \
            --force || print_warning "macmon install failed — exo will still run but without hardware monitoring"
    fi

    # --- Clone and build exo ---
    if [[ ! -d "$exo_dir" ]]; then
        print_info "Cloning exo to $exo_dir..."
        mkdir -p "$(dirname "$exo_dir")"
        git clone https://github.com/exo-explore/exo "$exo_dir" || { print_error "git clone failed"; return 1; }
    else
        print_status "exo repo already exists at $exo_dir"
        print_info "To update: cd $exo_dir && git pull"
    fi

    if [[ ! -d "$exo_dir/dashboard/node_modules" ]]; then
        print_info "Building exo dashboard..."
        (cd "$exo_dir/dashboard" && npm install && npm run build) || \
            print_warning "Dashboard build failed — exo API will still work without the UI"
    fi

    print_info ""
    print_info "=== exo usage ==="
    print_info "Start:          cd $exo_dir && uv run exo"
    print_info "Coordinator:    uv run exo --no-worker   (no inference, just routing)"
    print_info "Dashboard:      http://localhost:52415/"
    print_info "API endpoint:   http://localhost:52415/v1"
    print_info ""
    print_info "Run the same command on every Mac — peers auto-discover via mDNS."
    print_info "Wired (Thunderbolt/Ethernet) strongly preferred over WiFi."
    print_info ""
    print_info "Tool integration (replace LiteLLM base URL with exo when running distributed):"
    print_info "  Claude Code:  ANTHROPIC_BASE_URL=http://localhost:52415"
    print_info "  Continue:     provider: openai, apiBase: http://localhost:52415/v1"
    print_info "  OpenCode:     baseURL: http://localhost:52415/v1"
    print_info ""
    print_info "Docs: https://github.com/exo-explore/exo"
}

teardown_exo() {
    print_info "Removing exo..."

    local exo_dir="$HOME/code/exo"

    # Stop any running exo processes
    if pgrep -f "exo" &>/dev/null; then
        print_info "Stopping exo processes..."
        pkill -f "exo" || true
    fi

    # Remove cloned repo
    if [ -d "$exo_dir" ]; then
        print_info "Removing $exo_dir..."
        rm -rf "$exo_dir"
        print_status "Removed exo repo"
    else
        print_info "exo repo not found at $exo_dir — skipping"
    fi

    # Remove exo data/config/cache
    for dir in \
        "$HOME/.config/exo" \
        "$HOME/.local/share/exo" \
        "$HOME/.cache/exo"; do
        if [ -d "$dir" ]; then
            rm -rf "$dir"
            print_status "Removed $dir"
        fi
    done

    # Remove macmon (only if installed via cargo for exo)
    if command_exists "macmon"; then
        read -p "  Remove macmon (installed for exo)? (y/n) " -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cargo uninstall macmon 2>/dev/null && print_status "Removed macmon" || print_warning "macmon uninstall failed — remove manually: cargo uninstall macmon"
        fi
    fi

    print_status "exo removed. LiteLLM/Ollama configs unchanged."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-setup}" in
        setup)    setup_exo ;;
        teardown) teardown_exo ;;
        *) echo "Usage: $0 [setup|teardown]"; exit 1 ;;
    esac
fi
