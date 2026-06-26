1|# ~/.bashrc — bash interactive shell config
2|_sourcing_debug && echo "Sourcing: ${(%):-%N}"
3|[ -n "$BASHRC_LOADED" ] && return 0
4|export BASHRC_LOADED=true
5|
6|# Load ~/.homeassistant if it exists
7|if [ -f "$HOME/.homeassistant" ]; then
8|    if [ "$HOMEASSISTANT_LOADED" != "true" ]; then
9|        source "$HOME/.homeassistant"
10|    fi
11|fi
12|
13|# Load shared tool configs
14|for _f in "$HOME/.profile.d/"_*; do
15|    [ -s "$_f" ] && source "$_f"
16|done
17|unset _f
18|
19|# Home Assistant integration
20|if [ -f "$HOME/.homeassistant" ]; then
21|    source "$HOME/.homeassistant"
22|fi
23|
24|### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
25|export PATH="/Users/isaac/.rd/bin:$PATH"
26|### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)