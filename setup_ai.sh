#!/opt/homebrew/bin/bash
# setup_ai.sh — Install and configure AI development tools

set -euo pipefail

# Ensure we are running in bash, not sh or zsh
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script must be run with bash."
    echo "Please run it as: bash $(basename "$0")"
    exit 1
fi

SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$SETTINGS_BASE"

. "${SETTINGS_BASE}/helpers.sh"
# Source AI tool setup scripts
. "${SETTINGS_BASE}/2-ai/aider.sh"
. "${SETTINGS_BASE}/2-ai/anythingllm.sh"
. "${SETTINGS_BASE}/2-ai/claude.sh"
. "${SETTINGS_BASE}/2-ai/cline.sh"
. "${SETTINGS_BASE}/2-ai/codex.sh"
. "${SETTINGS_BASE}/2-ai/continue.sh"
. "${SETTINGS_BASE}/2-ai/crush.sh"
. "${SETTINGS_BASE}/2-ai/cursor.sh"
. "${SETTINGS_BASE}/2-ai/exo.sh"
. "${SETTINGS_BASE}/2-ai/gemini.sh"
. "${SETTINGS_BASE}/2-ai/github-copilot.sh"
. "${SETTINGS_BASE}/2-ai/grok.sh"
. "${SETTINGS_BASE}/2-ai/groq.sh"
. "${SETTINGS_BASE}/2-ai/install-models.sh"
. "${SETTINGS_BASE}/2-ai/kilocode.sh"
. "${SETTINGS_BASE}/2-ai/litellm.sh"
. "${SETTINGS_BASE}/2-ai/lmstudio.sh"
. "${SETTINGS_BASE}/2-ai/ollama.sh"
. "${SETTINGS_BASE}/2-ai/olol.sh"
. "${SETTINGS_BASE}/2-ai/open-hands.sh"
. "${SETTINGS_BASE}/2-ai/open-interpreter.sh"
. "${SETTINGS_BASE}/2-ai/opencode.sh"
. "${SETTINGS_BASE}/2-ai/openrouter.sh"
. "${SETTINGS_BASE}/2-ai/roocode.sh"
. "${SETTINGS_BASE}/2-ai/tabby.sh"
. "${SETTINGS_BASE}/2-ai/vscode.sh"
. "${SETTINGS_BASE}/2-ai/windsurf.sh"
. "${SETTINGS_BASE}/2-ai/zed.sh"

# ============================================================================
# CONFIGURATION DEPLOYMENT
# ============================================================================

deploy_configs() {
    log_info "Deploying AI tool configurations..."

    # --- MCP config (~/.mcp.json) ---
    print_step "MCP Servers"
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
    print_step "Copying AI tool configs"

    # Resolve per-profile config directory once
    local _profile _profdir
    _profile="$(_detect_profile)"
    _profdir="${SETTINGS_BASE}/2-ai/profiles/${_profile}"
    [ -n "$_profile" ] && log_info "Profile: ${_profile}" \
                       || log_warning "Profile not detected — per-profile configs will be skipped"

    [ -L "$HOME/.groq" ] && rm "$HOME/.groq"
    mkdir -p "$HOME/.groq"
    copy_file "${_profdir}/groq/local-settings.json" "$HOME/.groq/local-settings.json"

    [ -L "$HOME/.gemini" ] && rm "$HOME/.gemini"
    mkdir -p "$HOME/.gemini"
    copy_file "${_profdir}/gemini/settings.json" "$HOME/.gemini/settings.json"
    copy_file "${_profdir}/gemini/GEMINI.md"     "$HOME/.gemini/GEMINI.md"
    copy_file "${SETTINGS_BASE}/2-ai/gemini-projects.json" "$HOME/.gemini/projects.json"

    [ -L "$HOME/.continue" ] && rm "$HOME/.continue"
    mkdir -p "$HOME/.continue"
    copy_file "${_profdir}/continue/config.yaml" "$HOME/.continue/config.yaml"

    [ -L "$HOME/.config/opencode" ] && rm "$HOME/.config/opencode"
    mkdir -p "$HOME/.config/opencode"
    copy_file "${_profdir}/opencode/opencode.jsonc" "$HOME/.config/opencode/opencode.jsonc"

    [ -L "$HOME/.ollama" ] && rm "$HOME/.ollama"
    mkdir -p "$HOME/.ollama"
    copy_file "${_profdir}/ollama/config.json" "$HOME/.ollama/config.json"

    mkdir -p "$HOME/.config/crush"
    copy_file "${_profdir}/crush/crush.json" "$HOME/.config/crush/crush.json"

    mkdir -p "$HOME/.config/grok"
    copy_file "${_profdir}/grok/grok.json" "$HOME/.config/grok/grok.json"

    mkdir -p "$HOME/.config/litellm"
    copy_file "${SETTINGS_BASE}/2-ai/litellm/.env"         "$HOME/.config/litellm/.env"
    copy_file "${_profdir}/litellm/litellm.yaml"            "$HOME/.config/litellm/config.yaml"

    mkdir -p "$HOME/.config/zed"
    copy_file "${_profdir}/zed/settings.json" "$HOME/.config/zed/settings.json"

    mkdir -p "$HOME/.aider"
    copy_file "${_profdir}/aider/aider.conf.yml" "$HOME/.aider.conf.yml"

    # --- IDE selection ---
    print_step "IDE Selection"
    echo "  1) VS Code   (recommended — broader extension ecosystem)"
    echo "  2) Windsurf  (VS Code fork with built-in Codeium AI)"
    echo "  3) Both      (deploy configs for both, install neither)"
    echo ""
    read -p "Which IDE? [1/2/3] (Enter = 1): " IDE_CHOICE
    IDE_CHOICE="${IDE_CHOICE:-1}"

    if [[ "$IDE_CHOICE" == "2" || "$IDE_CHOICE" == "3" ]]; then
        [ -L "$HOME/.codeium" ] && rm "$HOME/.codeium"
        mkdir -p "$HOME/.codeium"
        copy_file "${_profdir}/windsurf/codeium-config.json" "$HOME/.codeium/config.json"

        [ -L "$HOME/.windsurf" ] && rm "$HOME/.windsurf"
        mkdir -p "$HOME/.windsurf"
        copy_file "${_profdir}/windsurf/argv.json" "$HOME/.windsurf/argv.json"
        log_status "Windsurf config deployed."
    fi

    if [[ "$IDE_CHOICE" == "1" || "$IDE_CHOICE" == "3" ]]; then
        log_info "VS Code config: extensions are installed via 'setup vscode' in the menu."
        log_info "Continue config is shared with both IDEs at ~/.continue/config.yaml."
    fi

    # --- Shell profile.d ---
    print_step "Copying profile.d files"
    local profiled_src="${_profdir}/profile.d"
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

    log_status "AI tool configs deployed."
}

# Function to backup existing configurations
backup_existing_configs() {
    log_status "Backing up existing AI tool configurations..."
    backup_continue
    backup_opencode
    backup_crush
    backup_claude
    backup_grok
    backup_olol
    backup_litellm
    log_status "All existing configurations backed up successfully"
}

# Function to restore configurations from backup
restore_configs() {
    log_status "Restoring AI tool configurations from backup..."
    restore_continue
    restore_opencode
    restore_crush
    restore_claude
    restore_grok
    restore_olol
    restore_litellm
    log_status "All configurations restored successfully"
}

verify_installations() {
    log_info "Verifying tool installations..."
    local verification_results=""
    local all_passed=true
    for check in verify_ollama verify_litellm verify_claude_code verify_cline_cli verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_groq verify_github_copilot verify_aider verify_cursor verify_roocode verify_kilocode verify_zed verify_tabby; do
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
        log_status "All AI development tools are properly installed and functional"
    else
        log_warning "Some tools may require manual configuration or additional setup"
        return 1
    fi
}

install_tools() {
    print_step "Checking system requirements"
    check_system_requirements
    print_step "Ollama"
    if ! verify_ollama; then
        setup_ollama || log_error "Failed to install Ollama"
    fi
    print_step "OpenRouter"
    if ! verify_openrouter; then
        setup_openrouter || log_error "Failed to setup OpenRouter"
    fi
    print_step "LiteLLM"
    if ! verify_litellm; then
        setup_litellm || log_error "Failed to install LiteLLM"
    fi
    print_step "Claude Code"
    if ! verify_claude_code; then
        setup_claude || log_error "Failed to install Claude Code"
    fi
    print_step "Cline"
    if ! verify_cline_cli; then
        setup_cline || log_error "Failed to install Cline"
    fi
    print_step "OpenCode"
    if ! verify_opencode; then
        setup_opencode || log_error "Failed to install OpenCode"
    fi
    print_step "Crush"
    if ! verify_crush; then
        setup_crush || log_error "Failed to install Crush"
    fi
    print_step "Codex"
    if ! verify_codex; then
        setup_codex || log_error "Failed to install Codex"
    fi
    print_step "Gemini"
    verify_gemini       || setup_gemini       || log_error "Failed to install Gemini"
    print_step "Grok"
    verify_grok         || setup_grok         || log_error "Failed to install Grok"
    print_step "Groq"
    verify_groq         || setup_groq         || log_error "Failed to install Groq"
    print_step "AnythingLLM"
    verify_anythingllm  || setup_anythingllm  || log_error "Failed to install AnythingLLM"
    print_step "GitHub Copilot"
    verify_github_copilot || setup_github_copilot || log_error "Failed to install GitHub Copilot"
    print_step "Aider"
    verify_aider       || setup_aider       || log_error "Failed to install Aider"
    print_step "Cursor"
    verify_cursor      || setup_cursor      || log_error "Failed to install Cursor"
    print_step "RooCode"
    verify_roocode     || setup_roocode     || log_error "Failed to install RooCode"
    print_step "Kilo Code"
    verify_kilocode    || setup_kilocode    || log_error "Failed to install Kilo Code"
    print_step "Zed"
    verify_zed         || setup_zed         || log_error "Failed to install Zed"
    print_step "Tabby"
    verify_tabby       || setup_tabby       || log_error "Failed to install Tabby"
    print_step "Open Hands"
    setup_openhands    || log_error "Failed to install Open Hands"
    print_step "Verifying all installations"
    verify_installations
}

# Dispatch a single action+tool pair
_run_one() {
    local action="$1" tool="$2"
    case "$action:$tool" in
        setup:aider)      setup_aider ;;
        setup:claude)     setup_claude ;;
        setup:cline)      setup_cline ;;
        setup:codex)      setup_codex ;;
        setup:continue)   setup_continue ;;
        setup:crush)      setup_crush ;;
        setup:cursor)     setup_cursor ;;
        setup:exo)        setup_exo ;;
        teardown:exo)     teardown_exo ;;
        setup:gemini)     setup_gemini ;;
        setup:grok)       setup_grok ;;
        setup:groq)       setup_groq ;;
        setup:kilocode)   setup_kilocode ;;
        setup:models)     install_coding_assistants ;;
        setup:ollama)     setup_ollama ;;
        setup:olol)       setup_olol ;;
        setup:anythingllm) setup_anythingllm ;;
        setup:lmstudio)    setup_lmstudio ;;
        setup:litellm)    setup_litellm ;;
        setup:open-hands) setup_openhands ;;
        setup:openrouter) setup_openrouter ;;
        setup:opencode)   setup_opencode ;;
        setup:roocode)    setup_roocode ;;
        setup:tabby)      setup_tabby ;;
        setup:copilot)    setup_github_copilot ;;
        setup:vscode)     setup_vscode ;;
        setup:windsurf)   setup_windsurf ;;
        setup:zed)        setup_zed ;;
        restore:claude)   restore_claude ;;
        restore:continue) restore_continue ;;
        restore:crush)    restore_crush ;;
        restore:grok)     restore_grok ;;
        restore:groq)     restore_groq ;;
        restore:litellm)  restore_litellm ;;
        restore:olol)     restore_olol ;;
        restore:opencode) restore_opencode ;;
        restore:*)        log_info "No restore available for $tool — skipping" ;;
        backup:claude)    backup_claude ;;
        backup:continue)  backup_continue ;;
        backup:crush)     backup_crush ;;
        backup:grok)      backup_grok ;;
        backup:groq)      backup_groq ;;
        backup:litellm)   backup_litellm ;;
        backup:olol)      backup_olol ;;
        backup:opencode)  backup_opencode ;;
        backup:*)         log_info "No backup available for $tool — skipping" ;;
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
    local tools_info=(
        "ollama|servers|Install server + start via brew services"
        "exo|servers|Install exo distributed inference"
        "olol|servers|Install Ollama load balancer"
        "lmstudio|servers|Install LM Studio (GUI app)"
        "openrouter|proxies|Install OpenRouter proxy + deploy config"
        "litellm|proxies|Install LiteLLM proxy + deploy config"
        "models|models|Install / prune Ollama models (auto-detects hardware)"
        "groq|providers|Deploy Groq config + API key instructions"
        "claude|tools|Install CLI + deploy config"
        "cline|tools|Install VS Code extension + CLI"
        "codex|tools|Install Codex CLI"
        "crush|tools|Install + deploy crush config"
        "grok|tools|Install + deploy grok config"
        "gemini|tools|Install Gemini CLI"
        "opencode|tools|Install + deploy opencode config"
        "anythingllm|tools|Install + configure Ollama provider"
        "aider|tools|Install Aider coding agent + deploy config"
        "open-hands|tools|Install Open Hands (Docker) + deploy config"
        "cursor|editors|Install Cursor IDE + show LiteLLM config"
        "roocode|editors|Install RooCode VS Code extension"
        "kilocode|editors|Install Kilo Code VS Code extension"
        "zed|editors|Install Zed editor + deploy config"
        "tabby|servers|Install Tabby autocomplete server"
        "vscode|editors|Install VS Code + Continue + Cline extensions"
        "windsurf|editors|Install Windsurf IDE + deploy argv.json"
        "continue|extensions|Deploy Continue.dev config"
        "copilot|extensions|Install gh-copilot extension + VS Code extensions"
    )

    local tools=() descs=() groups=()
    for entry in "${tools_info[@]}"; do
        IFS='|' read -r name group desc <<< "$entry"
        tools+=("$name")
        groups+=("$group")
        descs+=("$name - $desc")
    done

    declare -a sel=()
    for i in "${!tools[@]}"; do sel+=("0"); done
    local cursor=0
    local debug_info=""

    # Disable 'exit on error' for the interactive loop to prevent unexpected crashes
    set +e
    while true; do
        # Use a simple clear; if it fails, we just continue
        clear || true
        echo ""
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  Select tools (↑/↓: move, Space: toggle, Enter: confirm, q: quit) ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""

        local prev_group=""
        for i in "${!tools[@]}"; do
            local g="${groups[$i]}"
            local mark
            if [ "${sel[$i]}" = "1" ]; then mark="[x]"; else mark="[ ]"; fi

            if [ "$g" != "$prev_group" ]; then
                echo ""
                echo "  ── $g ──"
                prev_group="$g"
            fi

            if [ $i -eq $cursor ]; then
                printf "  > %s %s\n" "$mark" "${descs[$i]}"
            else
                printf "    %s %s\n" "$mark" "${descs[$i]}"
            fi
        done

        echo ""
        echo "────────────────────────────────────────────────────────────────"

        # Use stty raw to capture keys precisely and avoid Bash 'read' quirks on macOS.
        # Save terminal state, set to raw, read 1 byte, then restore.
        local term_state
        term_state=$(stty -g)
        stty raw -echo

        # Read one character
        key=$(dd bs=1 count=1 2>/dev/null)

        stty "$term_state"

        case "$key" in
            " "|$'\x20')
                if [ "${sel[$cursor]}" = "0" ]; then
                    sel[$cursor]="1"
                else
                    sel[$cursor]="0"
                fi
                ;;
            $'\e')
                # Handle escape sequences (arrows)
                # We need to read the next 2 bytes for the arrow sequence
                stty raw -echo
                local sequence
                sequence=$(dd bs=1 count=2 2>/dev/null)
                stty "$term_state"

                case "$sequence" in
                    "[A") # Up
                        cursor=$((cursor - 1))
                        [ $cursor -lt 0 ] && cursor=$((${#tools[@]} - 1))
                        ;;
                    "[B") # Down
                        cursor=$((cursor + 1))
                        [ $cursor -ge ${#tools[@]} ] && cursor=0
                        ;;
                esac
                ;;
            "q") # Quit
                return
                ;;
            $'\x0a'|$'\x0d') # Newline or Carriage Return
                break
                ;;
            *)
                # Ignore all other keys
                ;;
        esac
    done

    local chosen=()
    for i in "${!tools[@]}"; do
        if [ "${sel[$i]}" = "1" ]; then
            chosen+=("${tools[$i]}")
        fi
    done

    set -e

    if [ ${#chosen[@]} -eq 0 ]; then
        log_warning "No tools selected."
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
        *) log_error "Invalid action"; return 1 ;;
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
        aider)
            setup_aider
        ;;
        continue)
            setup_continue
        ;;
        cursor)
            setup_cursor
        ;;
        kilocode)
            setup_kilocode
        ;;
        open-hands)
            setup_openhands
        ;;
        opencode)
            setup_opencode
        ;;
        roocode)
            setup_roocode
        ;;
        tabby)
            setup_tabby
        ;;
        zed)
            setup_zed
        ;;
        crush)
            setup_crush
        ;;
        claude)
            setup_claude
        ;;
        cline)
            setup_cline
        ;;
        setup)
            setup_continue
            setup_opencode
            setup_crush
            setup_claude
            setup_github_copilot
            log_status "All tool configurations applied"
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
        lmstudio)
            setup_lmstudio
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
            echo "Usage: $0 {backup|restore|deploy|vscode|windsurf|continue|opencode|crush|claude|cline|aider|cursor|roocode|kilocode|zed|tabby|open-hands|setup|ollama|grok|olol|exo|codex|gemini|litellm|anythingllm|lmstudio|copilot|check|verify|install|models}"
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
            echo "  cline       - Install Cline VS Code extension + CLI"
            echo "  codex       - Install Codex CLI"
            echo "  crush       - Install Crush + deploy config"
            echo "  gemini      - Install Gemini CLI"
            echo "  grok        - Setup Grok CLI (offline AI via Ollama)"
            echo "  groq        - Deploy Groq config + API key instructions"
            echo "  opencode    - Setup OpenCode + deploy config"
            echo "  anythingllm - Install AnythingLLM + configure Ollama provider"
            echo "  aider       - Install Aider coding agent + deploy config"
            echo "  open-hands  - Install Open Hands (Docker) + deploy config"
            echo "  lmstudio    - Install LM Studio"
            echo ""
            echo "=== EDITORS ==="
            echo "  vscode      - Install VS Code + Continue + Cline extensions"
            echo "  windsurf    - Install Windsurf IDE + deploy configs"
            echo "  cursor      - Install Cursor IDE + show LiteLLM config"
            echo "  zed         - Install Zed editor + deploy config"
            echo ""
            echo "=== EXTENSIONS ==="
            echo "  continue    - Deploy Continue.dev config"
            echo "  copilot     - Install gh-copilot extension + VS Code Copilot extensions"
            echo "  roocode     - Install RooCode VS Code extension + show config"
            echo "  kilocode    - Install Kilo Code VS Code extension + show config"
            echo "  tabby       - Install Tabby autocomplete server"
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
    echo "Backup directory: ${BACKUP_DIR:-Not defined}"
}

# Run the script with provided argument only if it's being executed, not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "${1:-}"
fi
