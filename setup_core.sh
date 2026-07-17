#!/bin/bash

if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  echo "setup_core.sh must be executed, not sourced. Run: bash setup_core.sh" >&2
  return 1 2>/dev/null || exit 1
fi

if [ -z "${SETTINGS_BASE:-}" ]; then
  SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

. "${SETTINGS_BASE}/helpers.sh"

# ============================================================================
# DISPATCH — finds <tool>.sh across all category directories
# ============================================================================

_run_one() {
  local name="$1"
  local script
  for dir in "$SETTINGS_BASE"/*/; do
    [ -f "${dir}${name}.sh" ] && script="${dir}${name}.sh" && break
  done
  if [ -f "$script" ]; then
    print_info "Running ${name}.sh..."
    bash "$script"
    print_status "Finished ${name}.sh"
  else
    log_warning "Script not found: ${name}.sh in any category directory"
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
    # base
    "homebrew|base|Install Homebrew package manager"
    "installations|base|Install core CLI tools and apps"
    "bash|base|Update Bash to Homebrew version"
    "zsh|base|Install Zsh + Oh My Zsh"
    "fonts|base|Install developer fonts (Nerd Fonts etc.)"
    "tweaks|base|Apply macOS system preferences"
    # connectivity
    "internet|connectivity|Configure network settings"
    "ssh|connectivity|Generate SSH keys + configure ssh-agent"
    "autossh|connectivity|Install autossh for persistent tunnels"
    "vpn|connectivity|Install VPN client"
    "vnc|connectivity|Install VNC client"
    "transfer|connectivity|Install file transfer tools"
    "wget|connectivity|Install wget"
    # terminal
    "ghostty|terminal|Install Ghostty terminal + deploy config"
    "iterm|terminal|Install iTerm2"
    # browsers
    "arc|browsers|Install Arc browser"
    "brave|browsers|Install Brave browser"
    "chrome|browsers|Install Google Chrome"
    "chromium|browsers|Install Chromium"
    "edge|browsers|Install Microsoft Edge"
    "firefox|browsers|Install Firefox"
    # communication
    "slack|communication|Install Slack"
    "teams|communication|Install Microsoft Teams"
    "telegram|communication|Install Telegram"
    "discord|communication|Install Discord"
    "comet|communication|Install Comet"
    # languages & runtimes
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
    # frontend
    "angular|frontend|Install Angular CLI"
    "npm_globals|frontend|Install global npm packages"
    # data
    "jupyterlab|data|Install JupyterLab"
    "pytest|data|Install pytest"
    # databases
    "dbeaver|databases|Install DBeaver database tool"
    "mongodb|databases|Install MongoDB"
    "navicat|databases|Install Navicat"
    "postgresql|databases|Install PostgreSQL"
    "studio-3t|databases|Install Studio 3T"
    # containers & orchestration
    "colima|containers|Install Colima container runtime"
    "docker|containers|Install Docker"
    "orbstack|containers|Install OrbStack"
    "podman|containers|Install Podman"
    "rancher-desktop|containers|Install Rancher Desktop"
    "rancher-cli|containers|Install Rancher CLI"
    # infrastructure
    "aws|infra|Install AWS CLI and tools"
    "eks|infra|Install eksctl"
    "helm|infra|Install Helm"
    "kubernetes|infra|Install Kubernetes tools"
    "k9s|infra|Install K9s Kubernetes TUI"
    "sops|infra|Install SOPS secrets manager"
    "terraform|infra|Install Terraform"
    "ansible|infra|Install Ansible"
    "grafana|infra|Install Grafana"
    "prometheus|infra|Install Prometheus"
    # devtools
    "editors|devtools|Install editors (VS Code, Helix, Cursor, etc.)"
    "vscode|devtools|Install VS Code + extensions"
    "cursor|devtools|Install Cursor editor"
    "windsurf|devtools|Install Devin Desktop (formerly Windsurf)"
    "zed|devtools|Install Zed editor"
    "helix|devtools|Install Helix editor"
    "git|devtools|Install Git and GitHub CLI"
    "gitkraken-cli|devtools|Install GitKraken CLI (gk) + link GitHub account"
    "gradle|devtools|Install Gradle"
    "just|devtools|Install Just command runner"
    "sdk|devtools|Install Android Studio / SDK"
    "xcode|devtools|Install Xcode Command Line Tools"
    "sass|devtools|Set up Sass"
    # security
    "auth|security|Configure authentication"
    "1password|security|Install 1Password"
    "2fas|security|Install 2FAS authenticator"
    "encryption|security|Set up disk encryption"
    "keepassxc|security|Install KeePassXC"
    "proton_pass|security|Install Proton Pass"
    # productivity
    "fantastical|productivity|Install Fantastical calendar"
    "itsycal|productivity|Install Itsycal menu bar calendar"
    "task_managers|productivity|Install task manager apps"
    "pdf|productivity|Install PDF tools"
    "multimedia|productivity|Install media players"
    "deluge|productivity|Install Deluge torrent client"
    "folx|productivity|Install Folx download manager"
    "filezilla|productivity|Install FileZilla FTP client"
    # storage
    "dropbox|storage|Install Dropbox"
    "google_drive|storage|Install Google Drive sync tools"
    "insync|storage|Install Insync"
    "synology|storage|Install Synology tools"
    # services
    "apache|services|Install Apache HTTP Server"
    # vm
    "vm|vm|Install virtualization tools (UTM, Parallels, etc.)"
  )

  local max_name=0 max_group=0
  for entry in "${tools_info[@]}"; do
    IFS='|' read -r _n _g _d <<<"$entry"
    (( ${#_n} > max_name )) && max_name=${#_n}
    (( ${#_g} > max_group )) && max_group=${#_g}
  done

  local entries=()
  local seen_groups=()
  local prev_group=""
  for entry in "${tools_info[@]}"; do
    IFS='|' read -r name group desc <<<"$entry"
    # Add group header as non-selectable separator
    if [ "$group" != "$prev_group" ]; then
      entries+=("__separator__"$'\t'"$(printf '\033[1;33m── %s ──\033[0m' "$group")")
      prev_group="$group"
    fi
    entries+=("${name}"$'\t'"$(printf '  %-*s  %s' "$max_name" "$name" "$desc")")
  done

  if ! command -v fzf >/dev/null 2>&1; then
    log_error "fzf is not installed. Run: brew install fzf"
    return 1
  fi

  local selected
  selected=$(printf "%s\n" "${entries[@]}" | \
    fzf --multi \
        --header "Select tools to install (Tab/Space=toggle, Enter=confirm)" \
        --layout=reverse -d $'\t' --with-nth=2 --bind 'space:toggle' \
        --ansi --nth 2.. --cycle)

  local chosen=()
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local tool
    tool="$(cut -f1 <<<"$line")"
    [ "$tool" = "__separator__" ] && continue
    chosen+=("$tool")
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
  log_status "Core setup complete."
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
