if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_rust() {
    print_info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh && return 0
    return 1
}

verify_rust() {
    check_tool_with_version "Rust" "rustc"
}

setup_rust() {
    print_info "Setting up Rust..."

    verify_rust || _install_rust || { print_warning "Rust not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Rust ==="
    print_info "Update:        rustup update"
    print_info "New project:   cargo new my-project"
    print_info "Build + run:   cargo run"
    print_info "Test:          cargo test"
    print_info "Docs:          https://doc.rust-lang.org/book/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_rust
fi
