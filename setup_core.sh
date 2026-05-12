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
# DISPATCH
# ============================================================================

_run_one() {
  local name="$1"
  local script="$SETTINGS_BASE/0-core/setup_${name}.sh"
  if [ -f "$script" ]; then
    print_info "Running setup_${name}.sh..."
    bash "$script"
    print_status "Finished setup_${name}.sh"
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
    "homebrew|base|Install Homebrew package manager"
    "installations|base|Install core CLI tools and apps"
    "bash|base|Update Bash to Homebrew version"
    "zsh|base|Install Zsh + Oh My Zsh"
    "fonts|base|Install developer fonts (Nerd Fonts etc.)"
    "tweaks|base|Apply macOS system preferences"
    "internet|connectivity|Configure network settings"
    "ssh|connectivity|Generate SSH keys + configure ssh-agent"
    "autossh|connectivity|Install autossh for persistent tunnels"
    "vpn|connectivity|Install VPN client"
    "vnc|connectivity|Install VNC client"
    "transfer|connectivity|Install file transfer tools"
    "wget|connectivity|Install wget"
    "ghostty|terminal|Install Ghostty terminal + deploy config"
    "iterm|terminal|Install iTerm2"
    "arc|browsers|Install Arc browser"
    "brave|browsers|Install Brave browser"
    "chrome|browsers|Install Google Chrome"
    "chromium|browsers|Install Chromium"
    "edge|browsers|Install Microsoft Edge"
    "firefox|browsers|Install Firefox"
    "slack|communication|Install Slack"
    "teams|communication|Install Microsoft Teams"
    "telegram|communication|Install Telegram"
    "discord|communication|Install Discord"
    "comet|communication|Install Comet"
    "auth|security|Configure authentication"
    "1password|security|Install 1Password"
    "2fas|security|Install 2FAS authenticator"
    "encryption|security|Set up disk encryption"
    "keepassxc|security|Install KeePassXC"
    "proton_pass|security|Install Proton Pass"
    "fantastical|productivity|Install Fantastical calendar"
    "itsycal|productivity|Install Itsycal menu bar calendar"
    "task_managers|productivity|Install task manager apps"
    "pdf|productivity|Install PDF tools"
    "multimedia|productivity|Install media players"
    "deluge|productivity|Install Deluge torrent client"
    "folx|productivity|Install Folx download manager"
    "filezilla|productivity|Install FileZilla FTP client"
    "kiwi_for_gmail|productivity|Install Kiwi for Gmail"
    "ansible|devops|Install Ansible"
    "grafana|devops|Install Grafana"
    "prometheus|devops|Install Prometheus"
    "vm|devops|Install virtualization tools"
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
     fzf --multi --header "Select tools (Tab/Space=toggle, Enter=confirm, q=quit)" \
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
