#!/bin/bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

# Zsh - Default shell on macOS with Oh My Zsh for themes and plugins.

_install_zsh_core() {
    print_info "Installing Zsh and Oh My Zsh..."

    brew install zsh

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        print_info "Oh My Zsh is already installed."
    fi
}

_install_zsh_plugins() {
    print_info "Installing Zsh plugins..."
    brew install zsh-autosuggestions zsh-syntax-highlighting
}

_install_zsh_theme() {
    print_info "Installing Powerlevel10k theme..."
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [ ! -d "$p10k_dir" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    else
        print_info "Powerlevel10k already installed at $p10k_dir"
    fi
}

# ============================================================================
# DISPATCH
# ============================================================================

_run_one() {
  local action="$1" tool="$2"
  case "$action:$tool" in
  install:core)    _install_zsh_core ;;
  install:plugins) _install_zsh_plugins ;;
  install:theme)   _install_zsh_theme ;;
  install:*)       log_info "No install handler for $tool — skipping" ;;
  esac
}

_run_for_tools() {
  local action="$1"
  shift
  for tool in "$@"; do
    _run_one "$action" "$tool"
  done
}

# ============================================================================
# INTERACTIVE MENU
# ============================================================================

interactive_menu() {
  local tools_info=(
    "core|base|Install Zsh via Homebrew + Oh My Zsh"
    "plugins|base|Install zsh-autosuggestions + zsh-syntax-highlighting"
    "theme|base|Clone Powerlevel10k into OMZ custom themes"
  )

  local max_name=0 max_group=0
  for entry in "${tools_info[@]}"; do
    IFS='|' read -r _n _g _d <<<"$entry"
    (( ${#_n} > max_name )) && max_name=${#_n}
    (( ${#_g} > max_group )) && max_group=${#_g}
  done

  local tools=() entries=()
  for entry in "${tools_info[@]}"; do
    IFS='|' read -r name group desc <<<"$entry"
    tools+=("$name")
    entries+=("${name}"$'\t'"$(printf '[%-*s]  %-*s  %s' "$max_group" "$group" "$max_name" "$name" "$desc")")
  done

  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is not installed. Run: brew install fzf"
    return 1
  fi

  local selected
  selected=$(printf "%s\n" "${entries[@]}" | \
    fzf --multi --header "Select components (Tab/Space=toggle, Enter=confirm, q=quit)" \
        --layout=reverse -d $'\t' --with-nth=2)

  local chosen=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    chosen+=("$(cut -f1 <<<"$line")")
  done <<< "$selected"

  if [ ${#chosen[@]} -eq 0 ]; then
    log_warning "No components selected."
    return
  fi

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  Select action                                                 ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo "  1) install - install selected components"
  echo ""
  printf "Action [1]: "
  read -r act
  act="${act:-1}"

  case "$act" in
  1 | install) _run_for_tools install "${chosen[@]}" ;;
  *)
    log_error "Invalid action"
    return 1
    ;;
  esac
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  case "${1:-}" in
  core)    _install_zsh_core ;;
  plugins) _install_zsh_plugins ;;
  theme)   _install_zsh_theme ;;
  install)
    _install_zsh_core
    _install_zsh_plugins
    _install_zsh_theme
    log_status "Zsh setup complete."
    ;;
  "")
    interactive_menu
    ;;
  *)
    log_error "Unknown command: $1"
    echo "Usage: $0 [core|plugins|theme|install]"
    exit 1
    ;;
  esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
