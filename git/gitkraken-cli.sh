if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

# New 2026-07-16 — the standalone GitKraken CLI (binary: gk), not to be
# confused with the private copy of the same binary the GitLens VS Code
# extension bundles under its own globalStorage for internal use. Verified
# via `brew info gitkraken-cli`: it's a cask (not formula), installs a
# single `gk` binary artifact, same product/version as the bundled copy
# (`gk version` -> CLI Core 3.1.70, matching GitLens 18.3.0's bundled build).
# Two separate auth steps, confirmed via `gk auth --help` / `gk provider
# --help` on the real binary:
#   gk auth login       -> GitKraken platform account (browser OAuth)
#   gk provider add github -> links your actual GitHub account/token so
#                              `gk pr`/`gk issue`/`gk repo` etc. work against
#                              GitHub specifically — this is the "hook into
#                              my account through github" step.
# Both are interactive (browser/token prompts) — same as `gh auth login` in
# git.sh, this script only invokes them and lets them run, never fills in
# credentials itself.

_install_gitkraken_cli() {
    print_info "Installing GitKraken CLI..."
    brew install --cask gitkraken-cli \
        && gk auth login \
        && gk provider add github \
        && return 0
    return 1
}

verify_gitkraken_cli() {
    check_tool_with_version "GitKraken CLI" "gk"
}

setup_gitkraken_cli() {
    print_info "Setting up GitKraken CLI..."

    verify_gitkraken_cli || _install_gitkraken_cli || { print_warning "GitKraken CLI not installed — skipping"; return 1; }

    print_info ""
    print_info "=== GitKraken CLI ==="
    print_info "Binary:        gk"
    print_info "Platform auth: gk auth login       (GitKraken account, browser OAuth)"
    print_info "GitHub link:   gk provider add github  (links your GitHub account/token)"
    print_info "Other providers: gk provider add <gitlab|azure|bitbucket|...>"
    print_info "Check status:  gk whoami"
    print_info "Docs:          https://gitkraken.dev/"
    print_info ""
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_gitkraken_cli
fi
