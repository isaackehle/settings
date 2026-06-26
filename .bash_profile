1|# ~/.bash_profile: executed by login shells
2|_sourcing_debug && echo "Sourcing: ${(%):-%N}"
3|[ -n "$BASH_PROFILE_LOADED" ] && return 0
4|export BASH_PROFILE_LOADED=true
5|
6|# Load ~/.bashrc if it exists
7|if [ -f "$HOME/.bashrc" ]; then
8|    if [ "$BASHRC_LOADED" != "true" ]; then
9|        source "$HOME/.bashrc"
10|    fi
11|fi
12|
13|# Load Homebrew setup
14|[[ -f "$HOME/.brew" ]] && source "$HOME/.brew"
15|
16|# FNM (Fast Node Manager) - must be in login shell
17|eval "$(fnm env)"
18|
19|# Load environment variables (sourced from /Users/isaac/.env)
20|
21|if [ -s "$HOME/.env" ]; then
22|  [ "$SOURCING_DEBUG" ] && echo "Sourcing: $HOME/.env"
23|  source "$HOME/.env"
24|elif [ -s "$HOME/.env.local" ]; then
25|  [ "$SOURCING_DEBUG" ] && echo "Sourcing: $HOME/.env.local"
26|  source "$HOME/.env.local"
27|fi
28|
29|### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
30|export PATH="/Users/isaac/.rd/bin:$PATH"
31|### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)
32|