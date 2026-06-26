1|# ~/.zprofile: executed by login shells
2|
3|# Guard
4|[ -n "$ZPROFILE_LOADED" ] && return 0
5|export ZPROFILE_LOADED=true
6|
7|# Load Homebrew setup
8|[[ -f "$HOME/.brew" ]] && source "$HOME/.brew"
9|
10|# Ollama configuration
11|export PATH="/Applications/Ollama.app/Contents/Resources:$PATH"
12|export OLLAMA_MAX_LOADED_MODELS=2
13|export OLLAMA_KEEP_ALIVE=30m
14|export OLLAMA_KV_CACHE_TYPE=q8_0
15|export OLLAMA_NUM_PARALLEL=1
16|export OLLAMA_FLASH_ATTENTION=1
17|export TERMINFO=~/.terminfo
18|stty erase "^?"