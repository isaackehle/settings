#!/bin/bash
set -e

# Setup script for Isaac's dotfiles and Claude Code config
# Usage: ./setup.sh

SETTINGS_REPO="$(cd "$(dirname "$0")" && pwd)"
SYNC_DIR="$SETTINGS_REPO"

# ---------------------------------------------------------------------------
# Detect Mac model
# ---------------------------------------------------------------------------
HW_MODEL=$(sysctl -n hw.model)
HW_MEM_BYTES=$(sysctl -n hw.memsize)
HW_MEM_GB=$((HW_MEM_BYTES / 1024 / 1024 / 1024))

if [[ "$HW_MODEL" == Mac17* || "$HW_MEM_GB" -ge 32 ]]; then
    MAC_MODEL="macbook-m5"                              # Mac17,6 (M5) / 64GB
elif [[ "$HW_MODEL" == Macmini* || "$HW_MODEL" == Mac14* ]]; then
    MAC_MODEL="macmini-m2"
elif [[ "$HW_MODEL" == MacBookPro* ]]; then
    MAC_MODEL="macbook-m1"
else
    MAC_MODEL="default"
fi

echo "Detected: $MAC_MODEL ($HW_MODEL, ${HW_MEM_GB}GB)"
echo ""

if [ ! -d "$SETTINGS_REPO" ]; then
    echo "Error: Settings repo not found at $SETTINGS_REPO"
    exit 1
fi

# ---------------------------------------------------------------------------
# Source ~/.env.local for pre-seeding credentials
# ---------------------------------------------------------------------------
if [ -f "$HOME/.env.local" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.env.local"
    echo "Sourced ~/.env.local"
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Find the best source file: model-specific takes precedence over default.
# Usage: find_source <relative-path-within-settings-repo>
# Prints the resolved path, or empty string if not found.
find_source() {
    local rel="$1"
    local model_path="$SETTINGS_REPO/$MAC_MODEL/$rel"
    local default_path="$SETTINGS_REPO/$rel"
    if [ -f "$model_path" ]; then
        echo "$model_path"
    elif [ -f "$default_path" ]; then
        echo "$default_path"
    else
        echo ""
    fi
}

# Copy src to dest, backing up any existing non-symlink file first.
copy_file() {
    local src="$1"
    local dest="$2"

    if [ -z "$src" ] || [ ! -f "$src" ]; then
        echo "  (skip) source not found for $dest"
        return
    fi

    # Remove stale symlink
    if [ -L "$dest" ]; then
        rm "$dest"
    # Back up a real file that is different from what we'd copy
    elif [ -f "$dest" ]; then
        if ! cmp -s "$src" "$dest"; then
            mv "$dest" "${dest}.backup-$(date +%s)"
            echo "  backed up existing $(basename "$dest")"
        fi
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo "  copied $src -> $dest"
}

# Same as copy_file but looks up the source via find_source.
# Usage: install_file <rel-path-in-settings> <dest>
install_file() {
    local rel="$1"
    local dest="$2"
    local src
    src=$(find_source "$rel")
    copy_file "$src" "$dest"
}

# ---------------------------------------------------------------------------
# Create iCloud sync folder
# ---------------------------------------------------------------------------
mkdir -p "$SYNC_DIR"

# ---------------------------------------------------------------------------
# Shell config files  (sync dir -> home)
# ---------------------------------------------------------------------------
echo "Copying shell config files..."

for file in zshrc zprofile bash_profile bashrc brew; do
    src=$(find_source "$file")
    copy_file "$src" "$HOME/.$file"
done

# shellrc — installed to ~/.shellrc (sourced by bashrc + zshrc)
install_file "shellrc" "$HOME/.shellrc"

# profile.d — mirror to ~/.profile.d/ (sourced by shellrc)
PROFILED_SRC="$SETTINGS_REPO/$MAC_MODEL/profile.d"
[ ! -d "$PROFILED_SRC" ] && PROFILED_SRC="$SETTINGS_REPO/profile.d"
if [ -d "$PROFILED_SRC" ]; then
    [ -L "$HOME/.profile.d" ] && rm "$HOME/.profile.d"
    mkdir -p "$HOME/.profile.d"
    cp -R "$PROFILED_SRC/." "$HOME/.profile.d/"
    echo "  copied profile.d/ -> $HOME/.profile.d/"

    # Patch Home Assistant credentials in _home_assistant if present
    HA_PROFILED="$HOME/.profile.d/_home_assistant"
    if [ -f "$HA_PROFILED" ] && grep -q "YOUR_HOMEASSISTANT_URL\|YOUR_LONG_LIVED_TOKEN" "$HA_PROFILED"; then
        echo ""
        echo "  Home Assistant credentials needed for profile.d/_home_assistant."

        read -p "    URL (enter = ${HOMEASSISTANT_URL:-keep placeholder}): " HA_URL
        HA_URL="${HA_URL:-$HOMEASSISTANT_URL}"
        if [ -n "$HA_URL" ]; then
            sed -i '' "s|YOUR_HOMEASSISTANT_URL|$HA_URL|g" "$HA_PROFILED"
            echo "    Set HOMEASSISTANT_URL."
        fi

        read -p "    Long-lived token (enter = ${HOMEASSISTANT_TOKEN:+use from .env.local --> }${HOMEASSISTANT_TOKEN:-keep placeholder}): " HA_TOKEN
        HA_TOKEN="${HA_TOKEN:-$HOMEASSISTANT_TOKEN}"
        if [ -n "$HA_TOKEN" ]; then
            sed -i '' "s|YOUR_LONG_LIVED_TOKEN|$HA_TOKEN|g" "$HA_PROFILED"
            echo "    Set HOMEASSISTANT_TOKEN."
        fi

        chmod 600 "$HA_PROFILED"
    fi
fi

# zshrc.d — mirror to ~/.zshrc.d/ (sourced by zshrc)
ZSHRCD_SRC="$SETTINGS_REPO/$MAC_MODEL/zshrc.d"
[ ! -d "$ZSHRCD_SRC" ] && ZSHRCD_SRC="$SETTINGS_REPO/zshrc.d"
if [ -d "$ZSHRCD_SRC" ]; then
    [ -L "$HOME/.zshrc.d" ] && rm "$HOME/.zshrc.d"
    mkdir -p "$HOME/.zshrc.d"
    cp -R "$ZSHRCD_SRC/." "$HOME/.zshrc.d/"
    echo "  copied zshrc.d/ -> $HOME/.zshrc.d/"
fi

# ---------------------------------------------------------------------------
# Claude Code config  (~/.claude/)
# ---------------------------------------------------------------------------
echo ""
echo "Copying Claude config files..."

[ -L "$HOME/.claude" ] && rm "$HOME/.claude"
mkdir -p "$HOME/.claude"
install_file "claude/settings.json"      "$HOME/.claude/settings.json"
install_file "claude/keybindings.json"   "$HOME/.claude/keybindings.json"
install_file "claude/CLAUDE.md"          "$HOME/.claude/CLAUDE.md"

# skills directory — copy the whole tree
SKILLS_SRC="$SETTINGS_REPO/$MAC_MODEL/claude/skills"
[ ! -d "$SKILLS_SRC" ] && SKILLS_SRC="$SETTINGS_REPO/claude/skills"

OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/primary}"
[ ! -d "$SKILLS_SRC" ] && SKILLS_SRC="$OBSIDIAN_VAULT/.claude/skills"

if [ -d "$SKILLS_SRC" ]; then
    [ -L "$HOME/.claude/skills" ] && rm "$HOME/.claude/skills"
    mkdir -p "$HOME/.claude/skills"
    cp -R "$SKILLS_SRC/." "$HOME/.claude/skills/"
    echo "  copied skills/ -> $HOME/.claude/skills/"
fi

# ---------------------------------------------------------------------------
# MCP config  (interactive)
# ---------------------------------------------------------------------------
echo ""
echo "MCP Servers"
echo "-----------"

read -p "Install Claude MCP servers? (y/n) " -n 1 -r; echo
if [[ $REPLY =~ ^[Yy]$ ]]; then

    MCP_DEST="$HOME/.mcp.json"
    MCP_SRC=$(find_source "mcp.json")
    [ -z "$MCP_SRC" ] && MCP_SRC="$SYNC_DIR/mcp.json"

    _do_install_mcp=true
    if [ -f "$MCP_DEST" ]; then
        read -p "  ~/.mcp.json already exists. Overwrite? (y/n) " -n 1 -r; echo
        [[ ! $REPLY =~ ^[Yy]$ ]] && _do_install_mcp=false
    fi

    if [ "$_do_install_mcp" = true ] && [ -f "$MCP_SRC" ]; then
        [ -L "$MCP_DEST" ] && rm "$MCP_DEST"
        cp "$MCP_SRC" "$MCP_DEST"
        echo "  copied $MCP_SRC -> $MCP_DEST"

        # ---- Home Assistant server ----
        if grep -q "home-assistant" "$MCP_DEST"; then
            echo ""
            echo "  Home Assistant server detected."

            read -p "    URL (enter = ${HOMEASSISTANT_URL:-keep placeholder}): " HA_URL
            HA_URL="${HA_URL:-$HOMEASSISTANT_URL}"
            if [ -n "$HA_URL" ]; then
                sed -i '' "s|YOUR_HOMEASSISTANT_URL|$HA_URL|g" "$MCP_DEST"
                echo "    Set HOMEASSISTANT_URL."
            fi

            read -p "    Long-lived token (enter = ${HOMEASSISTANT_TOKEN:+use from .env.local --> }${HOMEASSISTANT_TOKEN:-keep placeholder}): " HA_TOKEN
            HA_TOKEN="${HA_TOKEN:-$HOMEASSISTANT_TOKEN}"
            if [ -n "$HA_TOKEN" ]; then
                sed -i '' "s|YOUR_LONG_LIVED_TOKEN|$HA_TOKEN|g" "$MCP_DEST"
                echo "    Set HOMEASSISTANT_TOKEN."
            fi
        fi

        chmod 600 "$MCP_DEST"
    else
        [ "$_do_install_mcp" = false ] && echo "  Skipped."
        [ ! -f "$MCP_SRC" ] && echo "  (skip) source not found: $MCP_SRC"
    fi
fi

# ---------------------------------------------------------------------------
# Tool configs
# ---------------------------------------------------------------------------
echo ""
echo "Copying tool configs..."

[ -L "$HOME/.groq" ] && rm "$HOME/.groq"
mkdir -p "$HOME/.groq"
install_file "groq/local-settings.json"          "$HOME/.groq/local-settings.json"

[ -L "$HOME/.gemini" ] && rm "$HOME/.gemini"
mkdir -p "$HOME/.gemini"
install_file "gemini/settings.json"              "$HOME/.gemini/settings.json"
install_file "gemini/GEMINI.md"                  "$HOME/.gemini/GEMINI.md"
install_file "gemini/projects.json"              "$HOME/.gemini/projects.json"

[ -L "$HOME/.continue" ] && rm "$HOME/.continue"
mkdir -p "$HOME/.continue"
src=$(find_source "continue/config.yaml")
[ -z "$src" ] && src="$SYNC_DIR/continue/config.yaml"
copy_file "$src" "$HOME/.continue/config.yaml"

[ -L "$HOME/.codeium" ] && rm "$HOME/.codeium"
mkdir -p "$HOME/.codeium"
install_file "codeium/config.json"               "$HOME/.codeium/config.json"

[ -L "$HOME/.windsurf" ] && rm "$HOME/.windsurf"
mkdir -p "$HOME/.windsurf"
install_file "windsurf/argv.json"                "$HOME/.windsurf/argv.json"

[ -L "$HOME/.config/opencode" ] && rm "$HOME/.config/opencode"
mkdir -p "$HOME/.config/opencode"
install_file "opencode/opencode.jsonc"           "$HOME/.config/opencode/opencode.jsonc"

[ -L "$HOME/.ollama" ] && rm "$HOME/.ollama"
mkdir -p "$HOME/.ollama"
install_file "ollama/config.json"                "$HOME/.ollama/config.json"

[ -L "$HOME/.config/ghostty" ] && rm "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/ghostty"
src=$(find_source "ghostty/config")
[ -z "$src" ] && src="$SYNC_DIR/ghostty/config"
copy_file "$src" "$HOME/.config/ghostty/config"

# ---------------------------------------------------------------------------
# .env.local  (model-specific first, then shared sync copy)
# ---------------------------------------------------------------------------
echo ""
echo "Copying .env.local..."

ENV_DEST="$HOME/.env.local"
ENV_SRC=$(find_source "env.local")
[ -z "$ENV_SRC" ] && ENV_SRC="$SYNC_DIR/$MAC_MODEL/env.local"
[ ! -f "$ENV_SRC" ] && ENV_SRC="$SYNC_DIR/env.local"

if [ ! -f "$ENV_SRC" ]; then
    if [ -f "$SETTINGS_REPO/.env.local.example" ]; then
        cp "$SETTINGS_REPO/.env.local.example" "$ENV_DEST"
        chmod 600 "$ENV_DEST"
        echo "  Created $ENV_DEST from template — add your API keys"
    else
        echo "  (skip) .env.local.example not found — create $ENV_DEST manually"
    fi
else
    copy_file "$ENV_SRC" "$ENV_DEST"
    chmod 600 "$ENV_DEST"
fi

# ---------------------------------------------------------------------------
# ProtonDrive detection (informational)
# ---------------------------------------------------------------------------
if [ -z "$PROTON_DRIVE" ]; then
    CLOUD_STORAGE="$HOME/Library/CloudStorage"
    DETECTED=$(find "$CLOUD_STORAGE" -maxdepth 1 -type d -name "ProtonDrive-*@*-folder" 2>/dev/null | head -1)
    if [ -n "$DETECTED" ]; then
        echo ""
        echo "Detected ProtonDrive at: $DETECTED"
    fi
fi

# ---------------------------------------------------------------------------
echo ""
echo "Setup complete! ($MAC_MODEL)"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.env.local and verify your API keys"
echo "  2. Reload your shell: source ~/.zshrc"
echo ""
echo "Model-specific overrides live in: $SETTINGS_REPO/$MAC_MODEL/"
echo ""
