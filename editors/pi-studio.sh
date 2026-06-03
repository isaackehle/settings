if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Pi Studio — local Codex-style desktop GUI for the Pi coding agent (Tauri)
# Repo:     https://github.com/shixin-guo/pi-studio
# Install:  Download DMG from GitHub releases
# Docs:     See README on GitHub
# ---------------------------------------------------------------------------

PI_STUDIO_APP="/Applications/Pi Studio.app"
PI_STUDIO_RELEASES="https://github.com/shixin-guo/pi-studio/releases"

verify_pi_studio() {
    if [ -d "$PI_STUDIO_APP" ]; then
        log_status "Pi Studio found"
        return 0
    fi
    log_warning "Pi Studio not found"
    return 1
}

_install_pi_studio() {
    log_info "Pi Studio is a desktop GUI app — download from GitHub releases."
    log_info ""
    log_info "  $PI_STUDIO_RELEASES"
    log_info ""
    log_info "After downloading:"
    log_info "  1. Drag Pi Studio.app into /Applications"
    log_info "  2. Right-click → Open (Gatekeeper override — app is unsigned)"
    log_info "  3. If blocked: System Settings → Privacy & Security → Open Anyway"
    log_info ""
    read -p "  Open the releases page in browser? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "$PI_STUDIO_RELEASES"
    fi
    return 1
}

setup_pi_studio() {
    log_info "Setting up Pi Studio..."
    verify_pi_studio || _install_pi_studio || { log_warning "Pi Studio not installed — skipping config"; return 1; }

    log_info ""
    log_info "=== Pi Studio ==="
    log_info "App:      $PI_STUDIO_APP"
    log_info "Start:    Open from Applications"
    log_info "Config:   ~/.pi/agent/ (shared with Pi CLI)"
    log_info "Model credentials: Use 'pi /login' in any workspace"
    log_info "Note:     Embeds its own Pi runtime — no separate pi install needed"
    log_info "Docs:     https://github.com/shixin-guo/pi-studio"
    log_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_pi_studio
fi
