. "$(dirname "${BASH_SOURCE[0]}")/../../utils.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../../helpers.sh"

_install_synology_tools() {
    print_info "Installing Synology tools..."
    brew install --cask synology-drive \
                    synology-chat \
                    synology-note-station-client \
                    synology-surveillance-station-client \
                    synology-image-assistant \
                    synology-assistant
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