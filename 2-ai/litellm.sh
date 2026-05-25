if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# teardown_litellm — Purge LiteLLM proxy, config, launchd service, and uv tool.
# Run this after migrating all tools to direct Ollama (:11434) or OpenRouter.

teardown_litellm() {
    log_info "Tearing down LiteLLM..."

    # 1. Stop and remove launchd service
    local _plist="$HOME/Library/LaunchAgents/ai.litellm.proxy.plist"
    if [ -f "$_plist" ]; then
        launchctl bootout gui/"$(id - u)" "$_plist" 2>/dev/null || launchctl remove ai.litellm.proxy 2>/dev/null || true
        rm -f "$_plist"
        log_status "Stopped and removed launchd service"
    fi

    # 2. Kill any running litellm processes
    if pgrep -f litellm >/dev/null 2>&1; then
        pkill -f litellm 2>/dev/null || true
        sleep 1
        pgrep -f litellm >/dev/null 2>&1 && pkill -9 -f litellm 2>/dev/null || true
        log_status "Killed running litellm processes"
    fi

    # 3. Uninstall via uv tool
    if command -v uv >/dev/null 2>&1; then
        uv tool uninstall litellm 2>/dev/null || true
        log_status "Uninstalled litellm via uv"
    fi

    # 4. Remove symlinks in ~/.local/bin
    for _link in litellm litellm-proxy litellm-proxy-endpoint litellm-start; do
        [ -L "$HOME/.local/bin/$_link" ] && rm -f "$HOME/.local/bin/$_link"
    done

    # 5. Remove config directory
    if [ -d "$HOME/.config/litellm" ]; then
        rm -rf "$HOME/.config/litellm"
        log_status "Removed ~/.config/litellm"
    fi

    # 6. Remind user to redeploy profile.d
    log_info ""
    log_info "Next steps:"
    log_info "  1. Run: bash setup_ai.sh deploy"
    log_info "     (to refresh profile.d files without LiteLLM references)"
    log_info "  2. Restart your terminal"
    log_info ""
    log_status "LiteLLM teardown complete"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    teardown_litellm
fi
