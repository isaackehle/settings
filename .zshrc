1|# ~/.zshrc — zsh shell config
2|_sourcing_debug && echo "Sourcing: ${(%):-%N}"
3|
4|# Load shared shellrc
5|[ -f "$HOME/.shellrc" ] && source "$HOME/.shellrc"
6|
7|# Load zsh-specific configs (installed by setup.sh)
8|for _f in "$HOME/.zshrc.d/"_*; do
9|    [ -s "$_f" ] && source "$_f"
10|done
11|unset _f
12|
13|# Final keybinding overrides (run after all plugins/integration)
14|if [[ -o interactive ]]; then
15|    zle -N my-backward-delete-word 2>/dev/null
16|
17|    bindkey '^U' backward-kill-line
18|    bindkey '\ew' my-backward-delete-word   # ensure Esc+w uses Esc+w key
19|fi