if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

_install_synology_tools() {
    print_info "Installing Synology tools..."
    brew install --cask synology-drive
    brew install --cask synology-chat
    brew install --cask synology-note-station-client
    brew install --cask synology-surveillance-station-client
    brew install --cask synology-image-assistant
    brew install --cask synologyassistant
}

setup_synology() {
    print_info "Setting up Synology environment..."

    _install_synology_tools

    print_info ""
    print_info "Start: Open Synology apps from Applications"
    print_info "References: https://www.synology.com/en-global/dsm"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_synology
fi
