#!/opt/homebrew/bin/bash
# setup_ai.sh — Install and configure AI development tools

set -euo pipefail

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SETTINGS_BASE/.." && pwd)"

. "${SETTINGS_BASE}/helpers.sh"

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
    for check in verify_claude_code verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_litellm verify_github_copilot; do
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
    verify_claude_code  || setup_claude    || print_error "Failed to install Claude Code"
    verify_opencode     || setup_opencode  || print_error "Failed to install OpenCode"
    verify_crush        || setup_crush     || print_error "Failed to install Crush"
    verify_codex        || setup_codex     || print_error "Failed to install Codex"
    verify_gemini       || setup_gemini    || print_error "Failed to install Gemini"
    verify_grok         || setup_grok      || print_error "Failed to install Grok"
    verify_groq         || setup_groq      || print_error "Failed to install Groq"
    verify_litellm      || setup_litellm      || print_error "Failed to install LiteLLM"
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
    # All available tools and their descriptions
    local tools=(
        ollama
        models
        vscode
        windsurf
        claude
        codex
        crush
        gemini
        grok
        groq
        opencode
        continue
        litellm
        anythingllm
        copilot
        exo
        olol
    )
    local descs=(
        "ollama      - install server + start via brew services"
        "models      - install / prune Ollama models (auto-detects hardware)"
        "vscode      - install VS Code + Continue + Cline extensions"
        "windsurf    - install Windsurf IDE + deploy argv.json"
        "claude      - install CLI + deploy config"
        "codex       - install Codex CLI"
        "crush       - install + deploy config"
        "gemini      - install Gemini CLI"
        "grok        - install + deploy config"
        "groq        - deploy Groq config + API key instructions"
        "opencode    - install + deploy config"
        "continue    - deploy Continue.dev config"
        "litellm     - install proxy + deploy config"
        "anythingllm - install + configure Ollama provider"
        "copilot     - install gh-copilot extension + VS Code extensions"
        "exo         - install exo distributed inference"
        "olol        - install Ollama load balancer"
    )
    # Default selections
    local sel=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)

    while true; do
        echo ""
        echo "=== Select tools  (number to toggle, a=all, n=none, q=confirm) ==="
        for i in "${!tools[@]}"; do
            local mark; [ "${sel[$i]}" = "1" ] && mark="[x]" || mark="[ ]"
            printf "  %s %2d. %s\n" "$mark" "$((i+1))" "${descs[$i]}"
        done
        echo ""
        printf "Choice: "
        read -r input
        case "$input" in
            q|"") break ;;
            a) for i in "${!tools[@]}"; do sel[$i]=1; done ;;
            n) for i in "${!tools[@]}"; do sel[$i]=0; done ;;
            *)
                for num in $(echo "$input" | tr ',;' '  '); do
                    if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#tools[@]} )); then
                        local idx=$((num-1))
                        sel[$idx]=$(( 1 - sel[$idx] ))
                    fi
                done
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
    echo "=== Select action ==="
    echo "  1. setup   - backup existing + apply new config / install"
    echo "  2. restore - restore from latest backup"
    echo "  3. backup  - backup only"
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
            echo "  backup      - Backup all existing configurations"
            echo "  restore     - Restore all configurations from backup"
            echo "  vscode      - Install VS Code + Continue + Cline extensions"
            echo "  windsurf    - Install Windsurf IDE + deploy configs"
            echo "  continue    - Setup Continue.dev (backup + copy config)"
            echo "  opencode    - Setup OpenCode (backup + copy config)"
            echo "  crush       - Setup Crush (backup + copy config)"
            echo "  claude      - Setup Claude Code (install CLI + copy config)"
            echo "  setup       - Setup all tool configs at once"
            echo "  ollama      - Install + start Ollama server"
            echo "  models      - Install / prune Ollama models (auto-detects hardware)"
            echo "  grok        - Setup Grok CLI (offline AI via Ollama)"
            echo "  olol        - Setup olol: Ollama load balancer across multiple machines"
            echo "  exo         - Setup exo: split inference across Apple Silicon devices"
            echo "  codex       - Install Codex CLI"
            echo "  gemini      - Install Gemini CLI"
            echo "  litellm     - Setup LiteLLM proxy (install + deploy config)"
            echo "  anythingllm - Install AnythingLLM + print Ollama provider config"
            echo "  copilot     - Install gh-copilot extension + VS Code Copilot extensions"
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