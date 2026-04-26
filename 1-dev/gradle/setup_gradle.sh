. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_gradle() {
    print_info "Installing Gradle..."
    if command_exists "sdk"; then
        sdk install gradle && return 0
    fi
    brew install gradle && return 0
    return 1
}

verify_gradle() {
    check_tool_with_version "Gradle" "gradle"
}

setup_gradle() {
    print_info "Setting up Gradle..."

    verify_gradle || _install_gradle || { print_warning "Gradle not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Gradle ==="
    print_info "Build:         ./gradlew build"
    print_info "Test:          ./gradlew test"
    print_info "Tasks:         ./gradlew tasks"
    print_info "Docs:          https://docs.gradle.org/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gradle
fi
