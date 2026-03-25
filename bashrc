# ~/.bashrc: executed by non-login interactive shells

# User configuration
# FNM (Fast Node Manager)
eval "$(fnm env --use-on-cd)"

alias pn=pnpm

export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# pyenv
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
fi

# PHP 7.4
export PATH="/opt/homebrew/opt/php@7.4/bin:$PATH"
export PATH="/opt/homebrew/opt/php@7.4/sbin:$PATH"

# Docker CLI completions
fpath=(~/.docker/completions $fpath)
export PATH="$HOME/.local/bin:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "~/.bun/_bun" ] && source "~/.bun/_bun"

# Rancher Desktop
export PATH="~/.rd/bin:$PATH"

# ProtonDrive — auto-detect by email folder name
export PROTON_DRIVE
PROTON_DRIVE=$(find "$HOME/Library/CloudStorage" -maxdepth 1 -type d -name "ProtonDrive-*@*-folder" 2>/dev/null | head -1)

# Obsidian Vault
export OBSIDIAN_ROOT="~/Library/Mobile Documents/iCloud~md~obsidian"
export OBSIDIAN_VAULT="$OBSIDIAN_ROOT/Documents/primary"

# Ollama
export OLLAMA_KEEP_ALIVE="30m"

# LM Studio
export PATH="$PATH:~/.lmstudio/bin"

# Load sensitive environment variables from local file (not in git)
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="~/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
