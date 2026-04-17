#!/bin/bash
# AI Tool Configuration Backup and Restore Script with Ollama Provider

echo "=== AI TOOL CONFIGURATION BACKUP AND RESTORE SCRIPT ==="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib/helpers.sh"
. "$SCRIPT_DIR/lib/setup_ollama.sh"
. "$SCRIPT_DIR/lib/setup_grok.sh"
. "$SCRIPT_DIR/lib/setup_olol.sh"
. "$SCRIPT_DIR/lib/setup_exo.sh"
. "$SCRIPT_DIR/lib/setup_continue.sh"
. "$SCRIPT_DIR/lib/setup_opencode.sh"
. "$SCRIPT_DIR/lib/setup_crush.sh"
. "$SCRIPT_DIR/lib/setup_claude.sh"
. "$SCRIPT_DIR/lib/setup_all.sh"
. "$SCRIPT_DIR/lib/setup_codex.sh"
. "$SCRIPT_DIR/lib/setup_gemini.sh"
. "$SCRIPT_DIR/lib/setup_litellm.sh"
. "$SCRIPT_DIR/lib/check_system_requirements.sh"
. "$SCRIPT_DIR/lib/install_models.sh"

# Configuration directory
NEW_CFG_DIR="$SCRIPT_DIR/configs"
DATE="$(date +%Y-%m-%d)"
BACKUP_DIR="$HOME/ai_tool_backups"

# Create backup directory
mkdir -p "$BACKUP_DIR"

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
    for check in verify_claude_code verify_opencode verify_crush verify_codex verify_gemini verify_grok verify_litellm; do
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
    verify_litellm      || setup_litellm   || print_error "Failed to install LiteLLM"
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
        setup:gemini)     setup_gemini ;;
        setup:grok)       setup_grok ;;
        setup:models)     install_coding_assistants ;;
        setup:ollama)     setup_ollama ;;
        setup:olol)       setup_olol ;;
        setup:litellm)    setup_litellm ;;
        setup:opencode)   setup_opencode ;;
        restore:claude)   restore_claude ;;
        restore:continue) restore_continue ;;
        restore:crush)    restore_crush ;;
        restore:grok)     restore_grok ;;
        restore:litellm)  restore_litellm ;;
        restore:olol)     restore_olol ;;
        restore:opencode) restore_opencode ;;
        restore:*)        print_info "No restore available for $tool — skipping" ;;
        backup:claude)    backup_claude ;;
        backup:continue)  backup_continue ;;
        backup:crush)     backup_crush ;;
        backup:grok)      backup_grok ;;
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
        claude 
        codex 
        crush 
        gemini 
        grok 
        opencode
        continue 
        litellm 
        exo 
        olol 
        )
    local descs=(
        "ollama      - start server + pull base model"
        "models      - install Ollama models"
        "claude      - install CLI + deploy config"
        "codex       - install Codex CLI"
        "crush       - install + deploy config"
        "gemini      - install Gemini CLI"
        "grok        - install + deploy config"
        "opencode    - install + deploy config"
        "continue    - deploy Continue.dev config"
        "litellm     - install proxy + deploy config"
        "exo         - install exo distributed inference"
        "olol        - install Ollama load balancer"
    )
    # Default selections: claude(0), codex(1), continue(2), gemini(5), litellm(7), ollama(8), opencode(10)
    local sel=(0 0 0 0 0 0 0 0 0 0 0 0)

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
            setup_all
            ;;
        ollama)
            setup_ollama
            ;;
        grok)
            setup_grok
            ;;
        olol)
            setup_olol
            ;;
        exo)
            setup_exo
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
        "")
            interactive_menu
            ;;
        *)
            echo "Usage: $0 {backup|restore|continue|opencode|crush|claude|setup|ollama|grok|olol|exo|codex|gemini|litellm|check|verify|install|models}"
            echo "  (no args)   - Interactive tool picker"
            echo "  backup      - Backup all existing configurations"
            echo "  restore     - Restore all configurations from backup"
            echo "  continue    - Setup Continue.dev (backup + copy config)"
            echo "  opencode    - Setup OpenCode (backup + copy config)"
            echo "  crush       - Setup Crush (backup + copy config)"
            echo "  claude      - Setup Claude Code (install CLI + copy config)"
            echo "  setup       - Setup all tool configs at once"
            echo "  ollama      - Setup Ollama server"
            echo "  grok        - Setup Grok CLI (offline AI via Ollama)"
            echo "  olol        - Setup olol: Ollama load balancer across multiple machines"
            echo "  exo         - Setup exo: split inference across Apple Silicon devices"
            echo "  codex       - Install Codex CLI"
            echo "  gemini      - Install Gemini CLI"
            echo "  litellm     - Setup LiteLLM proxy (install + deploy config)"
            echo "  check       - Check system requirements"
            echo "  verify      - Verify all tool installations"
            echo "  install     - Install all tools (check + install-if-missing + verify)"
            echo "  models      - Install Ollama models"
            exit 1
            ;;
    esac

    echo ""
    echo "=== AI TOOL CONFIGURATION PROCESS COMPLETED ==="
    echo "Backup directory: $BACKUP_DIR"
}

# Run the script with provided argument
main "$1"
