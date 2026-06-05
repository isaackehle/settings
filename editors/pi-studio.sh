if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# Pi Studio — local Codex-style desktop GUI for the Pi coding agent (Tauri)
# Repo:     https://github.com/shixin-guo/pi-studio
# Install:  Auto-downloads DMG from GitHub releases and installs to /Applications
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
    # Detect architecture
    local arch
    arch=$(uname -m)
    case "$arch" in
        arm64)  arch="aarch64" ;;
        x86_64) arch="x64" ;;
        *)
            log_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac

    log_info "Fetching latest Pi Studio release..."
    local api_url="https://api.github.com/repos/shixin-guo/pi-studio/releases/latest"
    local release_data
    release_data=$(curl -sL "$api_url") || { log_error "Failed to fetch release info"; return 1; }

    local version dmg_url
    version=$(echo "$release_data" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tag_name',''))") || version=""
    dmg_url=$(echo "$release_data" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for a in d.get('assets',[]):
    n=a.get('name','')
    if n.endswith('_${arch}.dmg'):
        print(a.get('browser_download_url',''))
        sys.exit(0)
" 2>/dev/null) || dmg_url=""

    if [ -z "$dmg_url" ]; then
        log_error "No DMG found for ${arch} in latest release"
        return 1
    fi

    log_info "Downloading Pi Studio ${version} (${arch})..."
    local tmp_dmg
    tmp_dmg=$(mktemp /tmp/pi-studio-XXXXXX.dmg)
    if ! curl -#L "$dmg_url" -o "$tmp_dmg"; then
        rm -f "$tmp_dmg"
        log_error "Download failed"
        return 1
    fi

    log_info "Mounting DMG..."
    local mount_point
    mount_point=$(hdiutil attach "$tmp_dmg" -nobrowse -plist 2>/dev/null | \
        python3 -c "
import plistlib,sys
d=plistlib.load(sys.stdin)
for e in d.get('system-entities',[]):
    mp=e.get('mount-point')
    if mp:
        print(mp)
        sys.exit(0)
") || {
        rm -f "$tmp_dmg"
        log_error "Failed to mount DMG"
        return 1
    }

    log_info "Installing Pi Studio to /Applications..."
    local install_cmd
    if [ -w /Applications ]; then
        install_cmd="cp -R"
    else
        install_cmd="sudo cp -R"
        log_info "Need sudo to copy to /Applications (enter password if prompted)"
    fi
    $install_cmd "$mount_point/Pi Studio.app" /Applications/ 2>/dev/null || {
        hdiutil detach "$mount_point" -quiet 2>/dev/null
        rm -f "$tmp_dmg"
        log_error "Failed to copy Pi Studio.app to /Applications"
        return 1
    }

    log_info "Cleaning up..."
    hdiutil detach "$mount_point" -quiet 2>/dev/null
    rm -f "$tmp_dmg"

    # Gatekeeper override — try to clear quarantine attribute
    xattr -d com.apple.quarantine /Applications/Pi\ Studio.app 2>/dev/null || true

    log_status "Pi Studio ${version} installed"
    return 0
}

backup_pi_studio() {
    # Pi Studio shares its config (~/.pi/agent/) with the Pi CLI,
    # which is backed up separately by backup_pi.
    log_info "Pi Studio config is shared with Pi — backed up by backup_pi"
}

restore_pi_studio() {
    if [ ! -d "$PI_STUDIO_APP" ]; then
        log_warning "Pi Studio app not found — reinstall with: bash setup_ai.sh pi-studio"
    else
        log_status "Pi Studio app present — config shared with Pi (restored by restore_pi)"
    fi
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
