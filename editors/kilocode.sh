if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Rewritten 2026-07-17 — superseded the 2026-07-16 finding that Kilo Code
# (kilocode.kilo-code v7.4.9) had no file-based custom-provider config.
# That was true for the settings.json-only surface checked at the time,
# but real, live evidence the same day showed otherwise: the user
# hand-configured Kilo Code for real, and it wrote a genuine, working
# `kilo.jsonc` at the *VS Code workspace root* — confirmed live at
# `$SETTINGS_BASE/.kilo/kilo.jsonc` on this machine (NOT `$HOME/.kilo`,
# which this repo's own earlier investigation had only guessed at from
# the bundled extension.js's `HOME=[".kilo",".kilocode",".opencode"]`
# array, with no live example to confirm the base directory against).
# Real schema fetched and verified directly
# (`curl https://app.kilo.ai/config.json`) — structurally identical to
# OpenCode's own config schema (it even references "opencode.local" as a
# default mDNS domain, real evidence of shared lineage). See
# homelab/profiles/generate-configs.sh's `patch_kilocode()` (DEC-118) for
# the full finding and the model-id bug it also caught and fixed.
#
# This is now a real deploy (`kilo.jsonc` is a complete, working config
# file, not a merge-in snippet), not manual-merge instructions — mirrors
# how gitlens.sh/hermes.sh deploy their real config files, using the same
# `copy_file` helper (backs up the existing file before overwriting, per
# DEC-089) as everything else in this repo.
HOMELAB_BASE="${HOMELAB_BASE:-$HOME/code/isaackehle/homelab}"

# MACHINE_PROFILE (from helpers.sh, sourced above) auto-detects against
# $SETTINGS_BASE/profiles — which is `settings/profiles`, and doesn't exist;
# profiles live in `homelab/profiles`. Re-detect against the homelab repo
# specifically when running from settings' own context (MACHINE_PROFILE
# comes back empty), rather than assuming the caller already exported the
# right value.
if [ -z "${MACHINE_PROFILE:-}" ] && [ -d "$HOMELAB_BASE/profiles" ]; then
    PROFILES_DIR="$HOMELAB_BASE/profiles"
    MACHINE_PROFILE="$(_detect_profile)"
    export MACHINE_PROFILE
fi

_kilocode_live_path="${SETTINGS_BASE}/.kilo/kilo.jsonc"

verify_kilocode() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "kilo-code"; then
        log_status "Kilo Code extension found"
    else
        log_warning "Kilo Code extension not found"
        return 1
    fi
    if [ -f "$_kilocode_live_path" ]; then
        log_status "Kilo Code config found: $_kilocode_live_path"
        return 0
    fi
    log_warning "Kilo Code extension installed but no config at $_kilocode_live_path yet"
    return 1
}

_install_kilocode() {
    if command_exists "code"; then
        log_info "Installing Kilo Code extension..."
        code --install-extension kilocode.kilo-code && return 0
    fi
    if command_exists "windsurf"; then
        log_info "Installing Kilo Code in Windsurf..."
        windsurf --install-extension kilocode.kilo-code && return 0
    fi
    log_warning "VS Code CLI (code) not found — install VS Code first"
    return 1
}

setup_kilocode() {
    log_info "Setting up Kilo Code..."
    verify_kilocode || _install_kilocode || log_warning "Kilo Code not installed — skipping"

    if [ ! -d "$HOMELAB_BASE" ]; then
        log_warning "homelab repo not found at $HOMELAB_BASE (override with \$HOMELAB_BASE) — skipping config"
        return 1
    fi

    local settings_src="${HOMELAB_BASE}/profiles/${MACHINE_PROFILE}/kilocode/settings.jsonc"
    if [ ! -f "$settings_src" ]; then
        log_warning "No settings.jsonc for profile '${MACHINE_PROFILE}' — generate it first:"
        log_info "  cd $HOMELAB_BASE && ./profiles/generate-configs.sh --engine <name> --profile ${MACHINE_PROFILE} --tool kilocode"
        return 1
    fi

    mkdir -p "$(dirname "$_kilocode_live_path")"
    copy_file "$settings_src" "$_kilocode_live_path"

    log_info ""
    log_info "=== Kilo Code ==="
    log_info "Extension:  kilocode.kilo-code"
    log_info "Config:     $_kilocode_live_path"
    log_info "(real, complete config — model/small_model are regenerated from"
    log_info " engines.sh's role map; the permission block and any other"
    log_info " hand-added settings are preserved, not overwritten — see"
    log_info " patch_kilocode() in homelab/profiles/generate-configs.sh)"
    log_info "Docs:       https://kilo.ai/docs"
    log_info ""
}

backup_kilocode() {
    if [ -f "$_kilocode_live_path" ]; then
        cp "$_kilocode_live_path" "${BACKUP_DIR}/kilocode_kilo.jsonc.${DATE}"
        log_status "Backed up Kilo Code config"
    fi
}

restore_kilocode() {
    local latest
    latest=$(ls -t "${BACKUP_DIR}"/kilocode_kilo.jsonc.* 2>/dev/null | head -1)
    if [ -n "$latest" ]; then
        mkdir -p "$(dirname "$_kilocode_live_path")"
        cp "$latest" "$_kilocode_live_path"
        log_status "Restored Kilo Code config from $(basename "$latest")"
    else
        log_warning "No Kilo Code backup found in ${BACKUP_DIR}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kilocode
fi
