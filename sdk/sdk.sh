if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_android_studio() {
    print_info "Installing Android Studio..."
    brew install --cask android-studio && return 0
    return 1
}

verify_android_studio() {
    check_tool_with_version "Android Studio" "studio"
}

setup_sdk() {
    print_info "Setting up Android SDK..."

    verify_android_studio || _install_android_studio || { print_warning "Android Studio not installed — skipping"; return 1; }

    print_info ""
    print_info "=== Android SDK ==="
    print_info "Launch:        Open Android Studio from Applications"
    print_info "JVM tools:     see ../java/ for SDKMAN"
    print_info "Docs:          https://developer.android.com/studio"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_sdk
fi
