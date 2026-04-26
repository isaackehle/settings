. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_xcode() {
    print_info "Installing Xcode Command Line Tools..."
    xcode-select --install && return 0
    return 1
}

_accept_xcode_license() {
    sudo xcodebuild -license accept
}

verify_xcode() {
    check_tool_with_version "Xcode CLT" "xcodebuild"
}

setup_xcode() {
    print_info "Setting up Xcode..."

    verify_xcode || _install_xcode || { print_warning "Xcode CLT not installed — install from App Store"; return 1; }

    _accept_xcode_license

    print_info ""
    print_info "=== Xcode ==="
    print_info "Version:       xcodebuild -version"
    print_info "Select Xcode:  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    print_info "App Store:     https://apps.apple.com/us/app/xcode/id497799835"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_xcode
fi
