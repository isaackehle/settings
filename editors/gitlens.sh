if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# New 2026-07-16 — GitLens (eamodio.gitlens, verified installed at v18.3.0)
# has real file-based settings for a local/custom AI backend (gitlens.ai.model,
# gitlens.ai.ollama.url, gitlens.ai.openaicompatible.url — verified against
# the installed extension's own package.json contributes.configuration, not
# assumed from docs), unlike Kilo Code/Cursor which need their in-app UI for
# a custom provider. Same generation/merge shape as kilocode.sh otherwise —
# config generation lives in `homelab`
# (homelab/profiles/generate-configs.sh --tool gitlens produces
# homelab/profiles/<profile>/gitlens/settings.jsonc).
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

verify_gitlens() {
    if command_exists "code" && code --list-extensions 2>/dev/null | grep -qi "eamodio.gitlens"; then
        log_status "GitLens extension found"
        return 0
    fi
    log_warning "GitLens extension not found"
    return 1
}

_install_gitlens() {
    if command_exists "code"; then
        log_info "Installing GitLens extension..."
        code --install-extension eamodio.gitlens && return 0
    fi
    if command_exists "windsurf"; then
        log_info "Installing GitLens in Windsurf..."
        windsurf --install-extension eamodio.gitlens && return 0
    fi
    log_warning "VS Code CLI (code) not found — install VS Code first"
    return 1
}

setup_gitlens() {
    log_info "Setting up GitLens..."
    verify_gitlens || _install_gitlens || log_warning "GitLens not installed — skipping"

    if [ ! -d "$HOMELAB_BASE" ]; then
        log_warning "homelab repo not found at $HOMELAB_BASE (override with \$HOMELAB_BASE) — skipping config"
        return 1
    fi

    local settings_src="${HOMELAB_BASE}/profiles/${MACHINE_PROFILE}/gitlens/settings.jsonc"
    if [ ! -f "$settings_src" ]; then
        log_warning "No settings.jsonc for profile '${MACHINE_PROFILE}' — generate it first:"
        log_info "  cd $HOMELAB_BASE && ./profiles/generate-configs.sh --engine <name> --profile ${MACHINE_PROFILE} --tool gitlens"
        return 1
    fi

    log_info ""
    log_info "=== GitLens ==="
    log_info "Extension:  eamodio.gitlens"
    log_info "Snippet:    $settings_src"
    log_info "Merge into: ~/Library/Application Support/Code/User/settings.json"
    log_info "(not auto-merged — it's a snippet into a file with many other"
    log_info " unrelated settings; unlike Kilo Code, these ARE real,"
    log_info " directly-usable keys once merged — no in-app wizard step"
    log_info " needed for the local model to work)"
    log_info "Docs:       https://help.gitkraken.com/gitlens/gitlens-ai/"
    log_info ""
}

# Kept as no-ops (not removed) — ai/setup_ai.sh's backup:gitlens /
# restore:gitlens dispatch calls these by name, same convention as
# kilocode.sh. No dedicated deployed config file to back up: the snippet
# above is merged by hand into VS Code's shared settings.json.
backup_gitlens() {
    log_info "GitLens has no dedicated config file to back up — see setup_gitlens"
}

restore_gitlens() {
    log_info "GitLens has no dedicated config file to restore — re-run setup_gitlens instead"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gitlens
fi
