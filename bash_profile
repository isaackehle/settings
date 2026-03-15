# ~/.bash_profile: executed by login shells

# Load ~/.bashrc if it exists
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc"
fi

# Add Homebrew to PATH (Apple Silicon Macs)
if [ -d "/opt/homebrew/bin" ]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi

# FNM (Fast Node Manager) - must be in login shell
eval "$(fnm env)"

# Load sensitive environment variables from local file (not in git)
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"
