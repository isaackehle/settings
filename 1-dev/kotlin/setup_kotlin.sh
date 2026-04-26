. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_kotlin() {
    print_info "Installing Kotlin..."
    brew install kotlin && return 0
    return 1
}

verify_kotlin() {
    check_tool_with_version "Kotlin" "kotlin"
}

setup_kotlin() {
    print_info "Setting up Kotlin..."

    verify_kotlin || _install_kotlin || { print_warning "Kotlin not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Kotlin ==="
    print_info "Version:       kotlin -version"
    print_info "Detekt:        brew install detekt"
    print_info "ktlint:        brew install ktlint"
    print_info "Docs:          https://kotlinlang.org/docs/home.html"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kotlin
fi
