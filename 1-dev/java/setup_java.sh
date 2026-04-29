if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_sdkman() {
    print_info "Installing SDKMAN..."
    curl -s "https://get.sdkman.io" | bash && return 0
    return 1
}

_install_java() {
    if command_exists "sdk"; then
        print_info "Installing Java via SDKMAN..."
        sdk install java && return 0
    fi
    print_info "Installing OpenJDK via Homebrew..."
    brew install openjdk && return 0
    return 1
}

verify_java() {
    check_tool_with_version "Java" "java"
}

setup_java() {
    print_info "Setting up Java..."

    command_exists "sdk" || _install_sdkman

    verify_java || _install_java || { print_warning "Java not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Java / SDKMAN ==="
    print_info "List versions: sdk list java"
    print_info "Use version:   sdk use java 21.0.2-tem"
    print_info "Set default:   sdk default java 21.0.2-tem"
    print_info "Docs:          https://sdkman.io/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_java
fi
