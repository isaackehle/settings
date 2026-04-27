#!/opt/homebrew/bin/bash
# setup_ai.sh — Install and configure AI development tools

set -euo pipefail

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SETTINGS_BASE/.." && pwd)"

. "${SETTINGS_BASE}/helpers.sh"
. "${SETTINGS_BASE}/utils.sh"
. "${SETTINGS_BASE}/2-ai/openrouter/setup_openrouter.sh"

# ============================================================================
# CONFIGURATION DEPLOYMENT
# ============================================================================

deploy_configs() {
    log_info "Deploying AI tool configurations..."

    # --- MCP config (~/.mcp.json) ---
    echo ""
    echo "MCP Servers"
    echo "-----------"
    read -p "Install Claude MCP servers? (y/n) " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local mcp_dest="$HOME/.mcp.json"
        local mcp_src
        mcp_src=$(find_source "mcp.json")
        [ -z "$mcp_src" ] && mcp_src="$SETTINGS_BASE/2-ai/mcp.json"

        local do_install=true
        if [ -f "$mcp_dest" ]; then
            read -p "  ~/.mcp.json already exists. Overwrite? (y/n) " -n 1 -r; echo
            [[ ! $REPLY =~ ^[Yy]$ ]] && do_install=false
        fi

        if [ "$do_install" = true ] && [ -f "$mcp_src" ]; then
            [ -L "$mcp_dest" ] && rm "$mcp_dest"
            cp "$mcp_src" "$mcp_dest"
            echo "  copied $mcp_src -> $mcp_dest"

            if grep -q "home-assistant" "$mcp_dest"; then
                echo ""
                echo "  Home Assistant server detected."
                read -p "    URL (enter = ${HOMEASSISTANT_URL:-keep placeholder}): " HA_URL
                HA_URL="${HA_URL:-$HOMEASSISTANT_URL}"
                [ -n "$HA_URL" ] && sed -i '' "s|YOUR_HOMEASSISTANT_URL|$HA_URL|g" "$mcp_dest" && echo "    Set HOMEASSISTANT_URL."
                read -p "    Long-lived token (enter = keep placeholder): " HA_TOKEN
                HA_TOKEN="${HA_TOKEN:-$HOMEASSISTANT_TOKEN}"
                [ -n "$HA_TOKEN" ] && sed -i '' "s|YOUR_LONG_LIVED_TOKEN|$HA_TOKEN|g" "$mcp_dest" && echo "    Set HOMEASSISTANT_TOKEN."
            fi
            chmod 600 "$mcp_dest"
        else
            [ "$do_install" = false ] && echo "  Skipped."
            [ ! -f "$mcp_src" ] && echo "  (skip) source not found: $mcp_src"
        fi
    fi

    # --- AI tool configs ---
    echo ""
    echo "Copying AI tool configs..."

    [ -L "$HOME/.groq" ] && rm "$HOME/.groq"
    mkdir -p "$HOME/.groq"
    _install_file "groq/local-settings.json" "$HOME/.groq/local-settings.json"

    [ -L "$HOME/.gemini" ] && rm "$HOME/.gemini"
    mkdir -p "$HOME/.gemini"
    _install_file "gemini/settings.json"  "$HOME/.gemini/settings.json"
    _install_file "gemini/GEMINI.md"      "$HOME/.gemini/GEMINI.md"
    _install_file "gemini/projects.json"  "$HOME/.gemini/projects.json"

    [ -L "$HOME/.continue" ] && rm "$HOME/.continue"
    mkdir -p "$HOME/.continue"
    local cont_src
    cont_src=$(find_source "continue/config.yaml")
    [ -z "$cont_src" ] && cont_src="$SETTINGS_BASE/2-ai/continue/config.yaml"
    _copy_file "$cont_src" "$HOME/.continue/config.yaml"

    # --- IDE selection ---
    echo ""
    echo "IDE Selection"
    echo "-------------"
    echo "  1) VS Code   (recommended — broader extension ecosystem)"
    echo "  2) Windsurf  (VS Code fork with built-in Codeium AI)"
    echo "  3) Both      (deploy configs for both, install neither)"
    echo ""
    read -p "Which IDE? [1/2/3] (Enter = 1): " IDE_CHOICE
    IDE_CHOICE="${IDE_CHOICE:-1}"

    if [[ "$IDE_CHOICE" == "2" || "$IDE_CHOICE" == "3" ]]; then
        [ -L "$HOME/.codeium" ] && rm "$HOME/.codeium"
        mkdir -p "$HOME/.codeium"
        _install_file "windsurf/codeium-config.json" "$HOME/.codeium/config.json"

        [ -L "$HOME/.windsurf" ] && rm "$HOME/.windsurf"
        mkdir -p "$HOME/.windsurf"
        _install_file "windsurf/argv.json" "$HOME/.windsurf/argv.json"
        print_status "Windsurf config deployed."
    fi

    if [[ "$IDE_CHOICE" == "1" || "$IDE_CHOICE" == "3" ]]; then
        print_info "VS Code config: extensions are installed via 'setup vscode' in the menu."
        print_info "Continue config is shared with both IDEs at ~/.continue/config.yaml."
    fi

    [ -L "$HOME/.config/opencode" ] && rm "$HOME/.config/opencode"
    mkdir -p "$HOME/.config/opencode"
    _install_file "opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

    [ -L "$HOME/.ollama" ] && rm "$HOME/.ollama"
    mkdir -p "$HOME/.ollama"
    _install_file "ollama/config.json" "$HOME/.ollama/config.json"

    mkdir -p "$HOME/.config/crush"
    _install_file "crush/crush.json" "$HOME/.config/crush/crush.json"

    mkdir -p "$HOME/.config/grok"
    _install_file "grok/grok.json" "$HOME/.config/grok/grok.json"

    mkdir -p "$HOME/.config/litellm"
    _install_file "litellm/.env"         "$HOME/.config/litellm/.env"
    _install_file "litellm/litellm.yaml" "$HOME/.config/litellm/config.yaml"

    # --- Shell profile.d ---
    echo ""
    echo "Copying profile.d files..."
    local profiled_src="$SETTINGS_BASE/2-ai/$MAC_MODEL/profile.d"
    [ ! -d "$profiled_src" ] && profiled_src="$SETTINGS_BASE/config/profile.d"
        if [ -d "$profiled_src" ]; then
            mkdir -p "$HOME/.profile.d"
            cp -R "$profiled_src/." "$HOME/.profile.d/"
            echo "  copied profile.d/ -> $HOME/.profile.d/"

            # --- Ollama Keep Alive Selection ---
            if [ -f "$HOME/.profile.d/_ollama" ]; then
                echo ""
                echo "  Ollama Memory Management"
                echo "  ------------------------"
                read -p "  Keep models warm in RAM? (0 = immediate unload, 5m = keep for 5 mins) [5m]: " KEEP_ALIVE
                KEEP_ALIVE="${KEEP_ALIVE:-5m}"
                sed -i '' "s/export OLLAMA_KEEP_ALIVE=\".*\"/export OLLAMA_KEEP_ALIVE=\"$KEEP_ALIVE\"/" "$HOME/.profile.d/_ollama"
                echo "    Set OLLAMA_KEEP_ALIVE to $KEEP_ALIVE"
            fi
        fi

    print_status "AI tool configs deployed."
}

# Function to backup existing configurations
backup_existing_configs() {
    print_status "Backing up existing AI tool configurations..."
    backup_continue
    backup_opencode
    backup_crush
    backup_claude
    backup_grok
    backup_olol
    backup_litellm
    print_status "All existing configurations backed up successfully"
}

# Function to restore configurations from backup
restore_configs() {
    print_status "Restoring AI tool configurations from backup..."
    restore_continue
    restore_opencode
    restore_crush
    restore_claude
    restore_grok
    restore_olol
    restore_litellm
    print_status "All configurations restored successfully"
}

verify_installations() {
    print_info "Verifying tool installations..."
    local verification_results=""
    local all_passed=true
    for check in verify_ollama verify_litellm verify_claude_code verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_groq verify_github_copilot; do
        local label="${check#verify_}"
        if $check; then
            verification_results="$verification_results ✓ $label - OK\n"
        else
            verification_results="$verification_results ✗ $label - FAILED\n"
            all_passed=false
        fi
    done
    echo -e "$verification_results"
    if [ "$all_passed" = true ]; then
        print_status "All AI development tools are properly installed and functional"
    else
        print_warning "Some tools may require manual configuration or additional setup"
        return 1
    fi
}

install_tools() {
    check_system_requirements
    verify_ollama       || setup_ollama       || print_error "Failed to install Ollama"
    verify_openrouter   || setup_openrouter   || print_error "Failed to setup OpenRouter"
    verify_litellm      || setup_litellm      || print_error "Failed to install LiteLLM"
    verify_claude_code  || setup_claude       || print_error "Failed to install Claude Code"
    verify_opencode     || setup_opencode     || print_error "Failed to install OpenCode"
    verify_crush        || setup_crush        || print_error "Failed to install Crush"
    verify_codex        || setup_codex        || print_error "Failed to install Codex"
    verify_gemini       || setup_gemini       || print_error "Failed to install Gemini"
    verify_grok         || setup_grok         || print_error "Failed to install Grok"
    verify_groq         || setup_groq         || print_error "Failed to install Groq"
    verify_anythingllm  || setup_anythingllm  || print_error "Failed to install AnythingLLM"
    verify_github_copilot || setup_github_copilot || print_error "Failed to install GitHub Copilot"
    verify_installations
}

# Dispatch a single action+tool pair
_run_one() {
    local action="$1" tool="$2"
    case "$action:$tool" in
        setup:claude)     setup_claude ;;
        setup:codex)      setup_codex ;;
        setup:continue)   setup_continue ;;
        setup:crush)      setup_crush ;;
        setup:exo)        setup_exo ;;
        teardown:exo)     teardown_exo ;;
        setup:gemini)     setup_gemini ;;
        setup:grok)       setup_grok ;;
        setup:groq)       setup_groq ;;
        setup:models)     install_coding_assistants ;;
        setup:ollama)     setup_ollama ;;
        setup:olol)       setup_olol ;;
        setup:anythingllm) setup_anythingllm ;;
        setup:litellm)    setup_litellm ;;
        setup:openrouter) setup_openrouter ;;
        setup:opencode)   setup_opencode ;;
        setup:copilot)    setup_github_copilot ;;
        setup:vscode)     setup_vscode ;;
        setup:windsurf)   setup_windsurf ;;
        restore:claude)   restore_claude ;;
        restore:continue) restore_continue ;;
        restore:crush)    restore_crush ;;
        restore:grok)     restore_grok ;;
        restore:groq)     restore_groq ;;
        restore:litellm)  restore_litellm ;;
        restore:olol)     restore_olol ;;
        restore:opencode) restore_opencode ;;
        restore:*)        print_info "No restore available for $tool — skipping" ;;
        backup:claude)    backup_claude ;;
        backup:continue)  backup_continue ;;
        backup:crush)     backup_crush ;;
        backup:grok)      backup_grok ;;
        backup:groq)      backup_groq ;;
        backup:litellm)   backup_litellm ;;
        backup:olol)      backup_olol ;;
        backup:opencode)  backup_opencode ;;
        backup:*)         print_info "No backup available for $tool — skipping" ;;
    esac
}

_run_for_tools() {
    local action="$1"; shift
    for tool in "$@"; do
        _run_one "$action" "$tool"
    done
}

# Interactive tool picker and action selector
interactive_menu() {
    # Tool definitions: name|group|description
    # Groups: servers, proxies, models, tools, editors, extensions, providers
    local tools_info=(
        "ollama|servers|Install server + start via brew services"
        "openrouter|proxies|Install OpenRouter proxy + deploy config"
        "litellm|proxies|Install LiteLLM proxy + deploy config"
        "models|models|Install / prune Ollama models (auto-detects hardware)"
        "claude|tools|Install CLI + deploy config"
        "codex|tools|Install Codex CLI"
        "crush|tools|Install + deploy crush config"
        "exo|servers|Install exo distributed inference"
        "olol|servers|Install Ollama load balancer"
        "grok|tools|Install + deploy grok config"
        "gemini|tools|Install Gemini CLI"
        "groq|providers|Deploy Groq config + API key instructions"
        "opencode|tools|Install + deploy opencode config"
        "continue|extensions|Deploy Continue.dev config"
        "vscode|editors|Install VS Code + Continue + Cline extensions"
        "windsurf|editors|Install Windsurf IDE + deploy argv.json"
        "anythingllm|tools|Install + configure Ollama provider"
        "copilot|extensions|Install gh-copilot extension + VS Code extensions"
    )

    # Parse tools into separate arrays
    local tools=() descs=() groups=()
    for entry in "${tools_info[@]}"; do
        IFS='|' read -r name group desc <<< "$entry"
        tools+=("$name")
        groups+=("$group")
        descs+=("$name - $desc")
    done

    # Default selections (all off)
    local sel=()
    for i in "${!tools[@]}"; do sel+=("0"); done

    # Build key→index mapping (a-z for first 18 tools)
    local key_map=()
    for i in "${!tools[@]}"; do
        key_map+=("$(printf "%d" $i)")
    done

    while true; do
        echo ""
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  Select tools (press key to toggle, q=confirm)                  ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""

        # Group tools by category and display with key bindings
        local prev_group=""
        for i in "${!tools[@]}"; do
            local g="${groups[$i]}"
            local mark; [ "${sel[$i]}" = "1" ] && mark="[x]" || mark="[ ]"
            local desc="${descs[$i]}"
            # Compute key letter (a=0, b=1, c=2, etc.)
            local key=$(printf "\\x%x" $((16#61 + i)))

            # Show group header if new group
            if [ "$g" != "$prev_group" ]; then
                echo ""
                echo "  ── $g ──"
                prev_group="$g"
            fi
            printf "    %s %s) %s\n" "$mark" "$key" "${descs[$i]}"
        done

        echo ""
        echo "────────────────────────────────────────────────────────────────"
        printf "Key (a-${key_char}, all/none, q=confirm): "
        read -r input
        case "$input" in
            q|"") break ;;
            all|a) for i in "${!sel[@]}"; do sel[$i]=1; done ;;
            none|n) for i in "${!sel[@]}"; do sel[$i]=0; done ;;
            *)
                # Find matching tool by letter
                local idx=$(printf "%d" "'$input") && idx=$((idx - 96))
                if [[ "$input" =~ ^[a-z]$ ]] && (( idx >= 1 && idx <= ${#tools[@]} )); then
                    local tool_idx=$((idx - 1))
                    sel[$tool_idx]=$(( 1 - sel[$tool_idx] ))
                fi
            ;;
        esac
    done

    local chosen=()
    for i in "${!tools[@]}"; do
        [ "${sel[$i]}" = "1" ] && chosen+=("${tools[$i]}")
    done

    if [ ${#chosen[@]} -eq 0 ]; then
        print_warning "No tools selected."
        return
    fi

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Select action                                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo "  1) setup   - backup existing + apply new config / install"
    echo "  2) restore - restore from latest backup"
    echo "  3) backup  - backup only"
    echo ""
    printf "Action [1]: "
    read -r act
    act="${act:-1}"

    case "$act" in
        1|setup)   _run_for_tools setup   "${chosen[@]}" ;;
        2|restore) _run_for_tools restore "${chosen[@]}" ;;
        3|backup)  _run_for_tools backup  "${chosen[@]}" ;;
        *) print_error "Invalid action"; return 1 ;;
    esac
}

# Main execution function
main() {
    case "$1" in
        backup)
            backup_existing_configs
        ;;
        restore)
            restore_configs
        ;;
        continue)
            setup_continue
        ;;
        opencode)
            setup_opencode
        ;;
        crush)
            setup_crush
        ;;
        claude)
            setup_claude
        ;;
        setup)
            setup_continue
            setup_opencode
            setup_crush
            setup_claude
            setup_github_copilot
            print_status "All tool configurations applied"
        ;;
        vscode)
            setup_vscode
        ;;
        windsurf)
            setup_windsurf
        ;;
        ollama)
            setup_ollama
        ;;
        grok)
            setup_grok
        ;;
        groq)
            setup_groq
        ;;
        openrouter)
            setup_openrouter
        ;;
        olol)
            setup_olol
        ;;
        exo)
            setup_exo
        ;;
        teardown-exo)
            teardown_exo
        ;;
        codex)
            setup_codex
        ;;
        gemini)
            setup_gemini
        ;;
        litellm)
            setup_litellm
        ;;
        anythingllm)
            setup_anythingllm
        ;;
        copilot)
            setup_github_copilot
        ;;
        check)
            check_system_requirements
        ;;
        verify)
            verify_installations
        ;;
        install)
            install_tools
        ;;
        models)
            install_coding_assistants
        ;;
        deploy)
            deploy_configs
        ;;
        "")
            interactive_menu
        ;;
        *)
            echo "Usage: $0 {backup|restore|deploy|vscode|windsurf|continue|opencode|crush|claude|setup|ollama|grok|olol|exo|codex|gemini|litellm|anythingllm|copilot|check|verify|install|models}"
            echo "  (no args)   - Interactive tool picker"
            echo "  deploy      - Copy all AI tool configs to their home-directory locations"
            echo ""
            echo "=== SERVERS ==="
            echo "  ollama      - Install + start Ollama server"
            echo "  olol        - Setup olol: Ollama load balancer across multiple machines"
            echo "  exo         - Setup exo: split inference across Apple Silicon devices"
            echo ""
            echo "=== PROXIES ==="
            echo "  openrouter  - Setup OpenRouter (API key + config)"
            echo "  litellm     - Setup LiteLLM proxy (install + deploy config)"
            echo ""
            echo "=== MODELS ==="
            echo "  models      - Install / prune Ollama models (auto-detects hardware)"
            echo ""
            echo "=== TOOLS ==="
            echo "  claude      - Install Claude Code CLI + deploy config"
            echo "  codex       - Install Codex CLI"
            echo "  crush       - Install Crush + deploy config"
            echo "  gemini      - Install Gemini CLI"
            echo "  grok        - Setup Grok CLI (offline AI via Ollama)"
            echo "  groq        - Deploy Groq config + API key instructions"
            echo "  opencode    - Setup OpenCode + deploy config"
            echo "  anythingllm - Install AnythingLLM + configure Ollama provider"
            echo ""
            echo "=== EDITORS ==="
            echo "  vscode      - Install VS Code + Continue + Cline extensions"
            echo "  windsurf    - Install Windsurf IDE + deploy configs"
            echo ""
            echo "=== EXTENSIONS ==="
            echo "  continue    - Deploy Continue.dev config"
            echo "  copilot     - Install gh-copilot extension + VS Code Copilot extensions"
            echo ""
            echo "=== COMMANDS ==="
            echo "  setup       - Setup all tool configs at once"
            echo "  deploy      - Copy all AI tool configs to home-directory locations"
            echo "  backup      - Backup all existing configurations"
            echo "  restore     - Restore all configurations from backup"
            echo "  check       - Check system requirements"
            echo "  verify      - Verify all tool installations"
            echo "  install     - Install all tools (check + install-if-missing + verify)"
            exit 1
        ;;
    esac

    echo ""
    echo "=== AI TOOL CONFIGURATION PROCESS COMPLETED ==="
    echo "Backup directory: $BACKUP_DIR"
}

# Run the script with provided argument
main "$1"