if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Rewritten 2026-07-16 — the previous version deployed a dedicated
# ~/.kilo/kilo.jsonc file, which the currently installed extension
# (kilocode.kilo-code v7.4.9) does not read at all (verified against the
# extension's own package.json — its only settings.json-exposed keys are
# kilo-code.new.model.providerID / .modelID; no file-based custom-provider
# config exists in this version). Also fixed: the old
# "${SETTINGS_BASE}/ai/profiles/${MACHINE_PROFILE}/kilocode" path pointed at
# a layout that predates the homelab repo split and no longer exists in
# either repo — config generation lives in `homelab`, not `settings`, now
# (see homelab/profiles/generate-configs.sh, which produces
# homelab/profiles/<profile>/kilocode/settings.jsonc).
#
# Second fix, same day: _install_kilocode() was installing
# "kilohealth.kilo-code" — verified wrong against
# ~/.vscode/extensions/extensions.json, where the actually-installed
# extension's real identifier is "kilocode.kilo-code" (source: "gallery",
# i.e. installed straight from the VS Code Marketplace under that id, not
# sideloaded — authoritative). A fresh machine running this script would
# have tried to install a different/nonexistent extension than the one
# already verified working here. Fixed in both the `code` and `windsurf`
# install commands, and the log line below.
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

verify_kilocode() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "kilo-code"; then
        log_status "Kilo Code extension found"
        return 0
    fi
    log_warning "Kilo Code extension not found"
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

    log_info ""
    log_info "=== Kilo Code ==="
    log_info "Extension:  kilocode.kilo-code"
    log_info "Snippet:    $settings_src"
    log_info "Merge into: ~/Library/Application Support/Code/User/settings.json"
    log_info "(not auto-merged — it's a snippet into a file with many other"
    log_info " unrelated settings; see the snippet's own comments for the"
    log_info " one-time provider setup steps in Kilo's UI)"
    log_info "Docs:       https://kilo.ai/docs"
    log_info ""
}

# Kept as no-ops (not removed) — ai/setup_ai.sh's backup:kilocode /
# restore:kilocode dispatch calls these by name. There's no longer a
# dedicated deployed config file to back up: the snippet above is merged by
# hand into VS Code's shared settings.json, which isn't something this
# script should be backing up/restoring on Kilo Code's behalf alone.
backup_kilocode() {
    log_info "Kilo Code has no dedicated config file to back up anymore — see setup_kilocode"
}

restore_kilocode() {
    log_info "Kilo Code has no dedicated config file to restore — re-run setup_kilocode instead"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_kilocode
fi
