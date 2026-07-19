if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# New 2026-07-17 — scoped narrowly to what was actually diagnosed and fixed
# live, NOT the full installer. Mistral Vibe is registered as a Zed
# external agent (agent_servers.mistral-vibe in zed/settings.json — see
# homelab's DEC-115/DEC-116), installed via a real, working install script
# (curl -LsSf https://mistral.ai/vibe/install.sh | bash — verified as the
# actual working URL by the user's own successful install), not through
# this repo yet. Full installer + VS Code-style extension wiring is
# deliberately deferred to ~/plans/zed-agent-servers-tooling-plan.md's
# List A/B matrix work — building it ad hoc here would contradict that
# plan's own "installers driven by the matrix, not built alongside it"
# scoping. This file exists only to capture the one real, reusable fix
# found so far: a bug in that install script's extraction step.

# _repair_mistral_vibe_symlinks — the install script's archive extraction
# does not preserve real symlinks: every symlink in the downloaded
# PyInstaller bundle (a standard macOS .framework layout — Python.framework
# in this case) comes out as a plain text file whose *content* is the
# intended symlink target, instead of an actual symlink. Confirmed live:
# `find "$BUNDLE" -type l` returned zero real symlinks anywhere in a fresh
# install — not an isolated glitch, the extraction step is systemically
# symlink-blind. This breaks the bundle at runtime with a PyInstaller
# bootloader error that reads like an architecture mismatch but isn't one:
#   [PYI-4491:ERROR] Failed to load Python shared library '.../Python':
#   dlopen(...): tried: '...' (slice is not valid mach-o file), ...
# The real underlying binary (Python.framework/Versions/3.12/Python) is a
# correctly-built arm64 Mach-O shared library — verified via `file`/`lipo
# -archs` before concluding this wasn't an architecture problem. Fixed by
# replacing each mangled stub with a real `ln -s` using its own text
# content as the target, then verified with a direct `ctypes.CDLL()` load
# (the same dlopen() PyInstaller's bootloader performs), not just by
# checking the file structure looked right.
#
# Re-run this after every Mistral Vibe (re)install, including on any other
# fleet machine — nothing suggests this was specific to `discovery` or to
# this one version; it's a bug in the install script itself.
_repair_mistral_vibe_symlinks() {
    local registry_dir="$HOME/Library/Application Support/Zed/external_agents/registry/mistral-vibe"
    if [ ! -d "$registry_dir" ]; then
        log_info "No Mistral Vibe registry directory found — nothing to repair"
        return 0
    fi

    local fixed=0
    # Every subdirectory under the registry is a version install
    # (v_<version>_<hash>/); repair each independently, they don't share
    # framework files.
    find "$registry_dir" -mindepth 1 -maxdepth 1 -type d | while IFS= read -r version_dir; do
        find "$version_dir" -type f -size -500c 2>/dev/null | while IFS= read -r f; do
            # Only treat it as a mangled symlink if it looks like a
            # relative filesystem path (no spaces, short) rather than
            # legitimate small text files this bundle also contains for
            # real (e.g. .dist-info/INSTALLER, top_level.txt — those are
            # normal Python packaging metadata, not symlinks, and must be
            # left alone).
            if file "$f" 2>/dev/null | grep -q "ASCII text"; then
                local content
                content="$(cat "$f" 2>/dev/null)"
                if [[ "$content" != *" "* ]] && [[ "$content" == *"Versions"* || "$content" == *".framework"* || "$content" == *"/"* && ${#content} -lt 100 ]]; then
                    # Confirm a sibling file at the target path actually
                    # exists before assuming this is a stray/legit file —
                    # don't blindly convert anything that merely looks
                    # path-shaped.
                    local dir target_check
                    dir="$(dirname "$f")"
                    target_check="$dir/$content"
                    if [ -e "$target_check" ] || [ -L "$target_check" ]; then
                        rm "$f"
                        ln -s "$content" "$f"
                        log_status "Repaired mangled symlink: $f -> $content"
                        fixed=$((fixed + 1))
                    fi
                fi
            fi
        done
    done

    if [ "$fixed" -gt 0 ]; then
        log_status "Repaired $fixed mangled symlink(s) in Mistral Vibe's bundle"
    else
        log_info "No mangled symlinks found — Mistral Vibe bundle looks intact"
    fi
}

verify_mistral_vibe() {
    local registry_dir="$HOME/Library/Application Support/Zed/external_agents/registry/mistral-vibe"
    if [ ! -d "$registry_dir" ]; then
        log_warning "Mistral Vibe not installed (no registry directory found)"
        return 1
    fi
    log_status "Mistral Vibe registry found: $registry_dir"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    verify_mistral_vibe
    _repair_mistral_vibe_symlinks
fi
