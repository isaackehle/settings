if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ---------------------------------------------------------------------------
# PicoClaw — tiny, deployable AI assistant for embedded / edge devices
# Repo:     https://github.com/picoclaw-labs/picoclaw
# Install:  go install github.com/picoclaw-labs/picoclaw@latest  (or binary)
# Setup:    config file only — no interactive wizard
# ---------------------------------------------------------------------------
# NOTE: This tool is primarily for embedded/edge devices (ESP32, RPi, etc.).
# On macOS, this installs the CLI for managing/configuring PicoClaw instances.
# For actual embedded development, also install: esp-idf, esptool.py, Go.

_picoclaw_cfg_dir="$HOME/.config/picoclaw"
_picoclaw_cfg="$_picoclaw_cfg_dir/config.toml"

verify_picoclaw() {
    if ! command -v picoclaw >/dev/null 2>&1; then
        log_warning "PicoClaw not found in PATH"
        return 1
    fi
    log_status "PicoClaw found: $(picoclaw --version 2>/dev/null || echo installed)"
    return 0
}

_install_picoclaw() {
    log_info "Installing PicoClaw..."

    # Prefer go install
    if command -v go >/dev/null 2>&1; then
        log_info "Using go install..."
        if go install github.com/picoclaw-labs/picoclaw@latest; then
            log_status "PicoClaw installed via go install"
            # Ensure GOPATH/bin is in PATH
            local _gopath
            _gopath="$(go env GOPATH)"
            if [ -n "$_gopath" ] && ! echo "$PATH" | grep -q "$_gopath/bin"; then
                log_warning "Add to PATH: export PATH=\"\$PATH:$_gopath/bin\""
            fi
            return 0
        fi
        log_warning "go install failed — falling back to binary release"
    else
        log_warning "Go not found — falling back to binary release"
    fi

    # Fallback: binary download from GitHub releases
    log_info "Downloading PicoClaw binary from GitHub releases..."
    local _arch="$(uname -m)"
    local _os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    local _bin_name="picoclaw_${_os}_${_arch}"
    local _tmp_bin
    _tmp_bin="$(mktemp)"

    # Best-effort architecture mapping
    case "$_arch" in
        x86_64) _arch="amd64" ;;
        arm64|aarch64) _arch="arm64" ;;
    esac

    local _url="https://github.com/picoclaw-labs/picoclaw/releases/latest/download/picoclaw_${_os}_${_arch}"
    if curl -fsSL "${_url}" -o "$_tmp_bin"; then
        chmod +x "$_tmp_bin"
        local _dest="/usr/local/bin/picoclaw"
        if [ -w /usr/local/bin ]; then
            mv "$_tmp_bin" "$_dest"
        else
            log_warning "Need sudo to install to /usr/local/bin"
            sudo mv "$_tmp_bin" "$_dest"
        fi
        log_status "PicoClaw binary installed to $_dest"
        return 0
    else
        log_error "Failed to download PicoClaw binary"
        rm -f "$_tmp_bin"
        return 1
    fi
}

setup_picoclaw() {
    log_info "Setting up PicoClaw..."
    verify_picoclaw || _install_picoclaw || { log_error "Failed to install PicoClaw"; return 1; }

    # Deploy config (profile-specific → default)
    mkdir -p "$_picoclaw_cfg_dir"
    local src_cfg
    src_cfg="${SETTINGS_BASE}/2-ai/profiles/${MACHINE_PROFILE}/picoclaw/config.toml"
    if [ ! -f "$src_cfg" ]; then
        src_cfg="${SETTINGS_BASE}/2-ai/profiles/default/picoclaw/config.toml"
    fi

    if [ -f "$src_cfg" ]; then
        copy_file "$src_cfg" "$_picoclaw_cfg"
        chmod 600 "$_picoclaw_cfg"
        log_status "Config deployed to $_picoclaw_cfg"
    else
        log_warning "No PicoClaw config found"
    fi

    # Offer to install embedded dev toolchain
    echo ""
    read -p "  Install embedded dev toolchain (esp-idf, esptool)? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        _install_embedded_toolchain
    fi

    log_info ""
    log_info "=== PicoClaw ==="
    log_info "Binary:   picoclaw"
    log_info "Config:   $_picoclaw_cfg_dir"
    log_info "Usage:    picoclaw"
    log_info "Docs:     https://github.com/picoclaw-labs/picoclaw"
    log_info ""
    log_info "Embedded Development (optional):"
    log_info "  brew install esp-idf     # ESP32 toolchain"
    log_info "  pip3 install esptool     # Flashing tool"
    log_info "  go install ...           # For building from source"
    log_info ""
}

_install_embedded_toolchain() {
    log_info "Installing embedded development tools..."

    if command -v brew >/dev/null 2>&1; then
        if ! command -v idf.py >/dev/null 2>&1; then
            log_info "Installing esp-idf..."
            brew install esp-idf || log_warning "esp-idf install failed"
        fi
    fi

    if ! command -v esptool.py >/dev/null 2>&1 && command -v pip3 >/dev/null 2>&1; then
        log_info "Installing esptool..."
        pip3 install esptool || log_warning "esptool install failed"
    fi

    log_status "Embedded toolchain setup complete"
}

backup_picoclaw() {
    if [ -d "$_picoclaw_cfg_dir" ]; then
        cp -r "$_picoclaw_cfg_dir" "${BACKUP_DIR}/picoclaw_backup_${DATE}"
        log_status "Backed up PicoClaw config"
    fi
}

restore_picoclaw() {
    local latest
    latest=$(ls -dt "${BACKUP_DIR}"/picoclaw_backup_* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$_picoclaw_cfg_dir"
        cp -R "$latest/"* "$_picoclaw_cfg_dir/" 2>/dev/null || true
        log_status "Restored PicoClaw config from $(basename "$latest")"
    else
        log_warning "No PicoClaw backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_picoclaw
fi
