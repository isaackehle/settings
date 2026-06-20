#!/opt/homebrew/bin/bash
# remove-deprecated-tools.sh — Uninstall tools removed from all profiles.
#
# Run this once per machine after pulling the repo to evict stale installs.
# If any of these tools appear in configs again, ask: "This tool was removed.
# Should it be added back, or should the config reference be cleaned up?"
#
# Deprecated: cline, roocode, litellm, zoocode
#
# Usage: bash ai/agents/remove-deprecated-tools.sh

set -euo pipefail

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# ── VS Code extensions ────────────────────────────────────────────────────────
_uninstall_vscode_ext() {
    local ext="$1" label="$2"
    if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
        log_info "Removing VS Code extension: $label ($ext)"
        code --uninstall-extension "$ext" && log_success "Removed $label" || log_warning "Failed to remove $label"
    else
        echo "  VS Code extension not installed: $label"
    fi
}

echo "=== Removing deprecated VS Code extensions ==="
_uninstall_vscode_ext "saoudrizwan.claude-dev"  "Cline"
_uninstall_vscode_ext "RooVetGit.roo-cline"     "Roo Code"
_uninstall_vscode_ext "zoocode.zoocode"          "Zoo Code"
echo ""

# Also remove from Cursor if installed
if command -v cursor &>/dev/null; then
    echo "=== Removing deprecated Cursor extensions ==="
    _uninstall_vscode_ext_cursor() {
        local ext="$1" label="$2"
        if cursor --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
            log_info "Removing Cursor extension: $label ($ext)"
            cursor --uninstall-extension "$ext" && log_success "Removed $label" || log_warning "Failed to remove $label"
        else
            echo "  Cursor extension not installed: $label"
        fi
    }
    _uninstall_vscode_ext_cursor "saoudrizwan.claude-dev"  "Cline"
    _uninstall_vscode_ext_cursor "RooVetGit.roo-cline"     "Roo Code"
    _uninstall_vscode_ext_cursor "zoocode.zoocode"          "Zoo Code"
    echo ""
fi

# ── Python packages ───────────────────────────────────────────────────────────
echo "=== Removing deprecated Python packages ==="
if pip3 show litellm &>/dev/null 2>&1; then
    log_info "Removing LiteLLM..."
    pip3 uninstall -y litellm && log_success "Removed litellm" || log_warning "pip uninstall failed"
else
    echo "  litellm not installed via pip"
fi
if uv tool list 2>/dev/null | grep -q "litellm"; then
    log_info "Removing LiteLLM (uv tool)..."
    uv tool uninstall litellm && log_success "Removed litellm (uv)" || log_warning "uv uninstall failed"
else
    echo "  litellm not installed via uv"
fi
echo ""

# ── Stale config dirs ─────────────────────────────────────────────────────────
echo "=== Checking stale config directories ==="
stale_dirs=(
    "$HOME/.config/litellm"
    "$HOME/.litellm"
)
for d in "${stale_dirs[@]}"; do
    if [[ -d "$d" ]]; then
        log_warning "Stale config dir found: $d"
        read -rp "  Remove $d? (y/N) " ans
        [[ "$ans" =~ ^[Yy]$ ]] && rm -rf "$d" && log_success "Removed $d" || echo "  Skipped"
    else
        echo "  Not present: $d"
    fi
done
echo ""

echo "=== Done ==="
echo "Deprecated tools: cline, roocode, zoocode, litellm"
echo ""
echo "NOTE: If any of these appear again in kilo.jsonc, opencode.jsonc, or"
echo "any profile config, treat it as a mistake and ask before adding back."
