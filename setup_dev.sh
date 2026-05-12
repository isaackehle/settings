#!/bin/bash

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "setup_dev.sh must be executed, not sourced. Run: bash setup_dev.sh" >&2
  return 1 2>/dev/null || exit 1
fi

if [ -z "${SETTINGS_BASE:-}" ]; then
  SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

# ============================================================================
# DISPATCH
# ============================================================================

_run_one() {
  local name="$1"
  local script_name="setup_${name//-/_}.sh"
  local script="$SETTINGS_BASE/1-dev/$name/$script_name"
  if [ -f "$script" ]; then
    print_info "Running $script_name..."
    bash "$script"
    print_status "Finished $script_name"
  else
    log_warning "Script not found: $script"
  fi
}

_run_for_tools() {
  for tool in "$@"; do
    _run_one "$tool"
  done
}

# ============================================================================
# INTERACTIVE MENU
# ============================================================================

interactive_menu() {
  local tools_info=(
    "bun|languages|Install Bun JS runtime"
    "corepack|languages|Enable Corepack (pnpm/yarn via Node)"
    "elixir|languages|Install Elixir"
    "flutter|languages|Install Flutter SDK"
    "fnm|languages|Install FNM Node version manager"
    "go|languages|Install Go"
    "java|languages|Install SDKMAN + Java"
    "julia|languages|Install Julia"
    "kotlin|languages|Install Kotlin"
    "nvm|languages|Install NVM Node version manager"
    "pipenv|languages|Install pipenv"
    "pnpm|languages|Install pnpm"
    "python|languages|Install pyenv + Python"
    "ruby|languages|Install Ruby via RVM"
    "rust|languages|Install Rust via rustup"
    "sass|languages|Set up Sass"
    "typescript|languages|Set up TypeScript"
    "volta|languages|Install Volta JS toolchain manager"
    "angular|frontend|Install Angular CLI"
    "npm-globals|frontend|Install global npm packages"
    "jupyterlab|data|Install JupyterLab"
    "pytest|data|Install pytest"
    "databases|databases|Install database GUI tools"
    "mongodb|databases|Install MongoDB"
    "postgresql|databases|Install PostgreSQL"
    "aws|infra|Install AWS CLI and tools"
    "container-platforms|infra|Install Docker Desktop"
    "eks|infra|Install eksctl"
    "helm|infra|Install Helm"
    "kubernetes|infra|Install Kubernetes tools"
    "rancher-desktop|infra|Install Rancher Desktop"
    "terraform|infra|Install Terraform"
    "editors|devtools|Install editors (VS Code etc.)"
    "git|devtools|Install Git and GitHub CLI"
    "gradle|devtools|Install Gradle"
    "just|devtools|Install Just command runner"
    "k9s|devtools|Install K9s Kubernetes TUI"
    "sdk|devtools|Install Android Studio / SDK"
    "sops|devtools|Install SOPS secrets manager"
    "xcode|devtools|Install Xcode Command Line Tools"
    "apache|services|Install Apache HTTP Server"
    "dropbox|storage|Install Dropbox"
    "google_drive|storage|Install Google Drive sync tools"
    "insync|storage|Install Insync"
    "synology|storage|Install Synology tools"
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
     fzf --multi --header "Select tools to install (Tab/Space=toggle, Enter=confirm, q=quit)" \
         --layout=reverse -d $'\t' --with-nth=2 --bind 'space:toggle')

  local chosen=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    chosen+=("$(cut -f1 <<<"$line")")
  done <<< "$selected"

  if [ ${#chosen[@]} -eq 0 ]; then
    log_warning "No tools selected."
    return
  fi

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  Starting installation                                         ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
  _run_for_tools "${chosen[@]}"
  echo ""
  log_status "Dev environment setup complete."
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  case "${1:-}" in
  "")
    interactive_menu
    ;;
  *)
    _run_for_tools "$@"
    ;;
  esac
}

main "$@"
