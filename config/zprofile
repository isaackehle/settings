# ~/.zprofile: executed by login shells

# Load Homebrew setup
[[ -f "$HOME/.brew" ]] && source "$HOME/.brew"

# Load ~/.zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    source "$HOME/.zshrc"
fi

# Load sensitive environment variables from local file (not in git)
[[ -f "$HOME/.env.local" ]] && source "$HOME/.env.local"

eval "$(/opt/homebrew/bin/brew shellenv zsh)"
