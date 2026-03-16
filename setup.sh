#!/bin/bash
set -e

# Setup script for Isaac's dotfiles and Claude Code config
# Usage: ./setup.sh

SETTINGS_DIR="$HOME/code/isaackehle/settings"

if [ ! -d "$SETTINGS_DIR" ]; then
    echo "Error: Settings repo not found at $SETTINGS_DIR"
    exit 1
fi

echo "🔗 Setting up symlinks..."

# Function to safely create symlink
create_symlink() {
    local target="$1"
    local link="$2"

    if [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "⚠️  $link exists (not a symlink). Creating backup..."
        mv "$link" "${link}.backup-$(date +%s)"
    fi

    if [ -L "$link" ]; then
        rm "$link"
    fi

    ln -s "$target" "$link"
    echo "✓ $link → $target"
}

# Create shell config symlinks
create_symlink "$SETTINGS_DIR/zshrc" "$HOME/.zshrc"
create_symlink "$SETTINGS_DIR/zprofile" "$HOME/.zprofile"
create_symlink "$SETTINGS_DIR/bash_profile" "$HOME/.bash_profile"
create_symlink "$SETTINGS_DIR/bashrc" "$HOME/.bashrc"
create_symlink "$SETTINGS_DIR/brew" "$HOME/.brew"

# Create ~/.claude symlink (Claude Code config)
mkdir -p "$HOME/.claude"
create_symlink "$SETTINGS_DIR/claude/settings.json" "$HOME/.claude/settings.json"
create_symlink "$SETTINGS_DIR/claude/keybindings.json" "$HOME/.claude/keybindings.json"
create_symlink "$SETTINGS_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Create ~/.claude/skills symlink (link to Obsidian vault skills repo)
OBSIDIAN_VAULT="${OBSIDIAN_VAULT:-$HOME/Library/CloudStorage/ProtonDrive-master.icedog@pm.me-folder/Obsidian/vault}"
if [ -d "$OBSIDIAN_VAULT/.claude/skills" ]; then
    create_symlink "$OBSIDIAN_VAULT/.claude/skills" "$HOME/.claude/skills"

    # Check for collisions in skills repo
    if cd "$OBSIDIAN_VAULT/.claude/skills" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
        SKILLS_REPO="$OBSIDIAN_VAULT/.claude/skills"
        COLLISION_FOUND=0

        echo ""
        echo "🔍 Checking skills repo for collisions..."

        # 1. Check for uncommitted changes
        if ! git diff-index --quiet HEAD --; then
            echo ""
            echo "⚠️  COLLISION 1: Uncommitted changes"
            echo "    Files changed:"
            git status --short | sed 's/^/      /'
            echo ""
            echo "    HOW TO FIX:"
            echo "      Option A (keep local): git add . && git commit -m 'message' && git push"
            echo "      Option B (discard):    git restore ."
            COLLISION_FOUND=1
        fi

        # 2. Check for unmerged paths (merge conflicts)
        if git ls-files --unmerged | grep -q .; then
            echo ""
            echo "⚠️  COLLISION 2: Merge conflicts detected"
            echo "    Conflicted files:"
            git ls-files --unmerged | cut -f2 | sort -u | sed 's/^/      /'
            echo ""
            echo "    HOW TO FIX:"
            echo "      1. Open conflicted files and resolve (look for <<<<<<< and >>>>>>>)"
            echo "      2. git add <resolved-files>"
            echo "      3. git commit -m 'Resolve skill conflicts'"
            echo "      4. git push"
            COLLISION_FOUND=1
        fi

        # 3. Check for diverged branches (fetch remote changes and check)
        git fetch origin 2>/dev/null || true
        if ! git merge-base --is-ancestor HEAD origin/HEAD 2>/dev/null; then
            echo ""
            echo "⚠️  COLLISION 3: Local diverged from remote"
            echo "    Your machine has commits the other doesn't"
            echo ""
            echo "    HOW TO FIX:"
            echo "      Option A (merge): git pull origin && git push"
            echo "      Option B (rebase): git rebase origin && git push"
            COLLISION_FOUND=1
        fi

        if [ $COLLISION_FOUND -eq 1 ]; then
            echo ""
            echo "⏸️  Setup paused. Resolve collisions in: $SKILLS_REPO"
            echo ""
            return 1
        fi
    fi
fi

# Create ~/.groq symlink (Groq CLI config)
mkdir -p "$HOME/.groq"
if [ -f "$SETTINGS_DIR/groq/local-settings.json" ]; then
    create_symlink "$SETTINGS_DIR/groq/local-settings.json" "$HOME/.groq/local-settings.json"
fi

# Create ~/.gemini symlink (Google Gemini CLI config)
mkdir -p "$HOME/.gemini"
if [ -f "$SETTINGS_DIR/gemini/settings.json" ]; then
    create_symlink "$SETTINGS_DIR/gemini/settings.json" "$HOME/.gemini/settings.json"
fi
if [ -f "$SETTINGS_DIR/gemini/GEMINI.md" ]; then
    create_symlink "$SETTINGS_DIR/gemini/GEMINI.md" "$HOME/.gemini/GEMINI.md"
fi
if [ -f "$SETTINGS_DIR/gemini/projects.json" ]; then
    create_symlink "$SETTINGS_DIR/gemini/projects.json" "$HOME/.gemini/projects.json"
fi

# Create ~/.codeium symlink (Codeium config)
mkdir -p "$HOME/.codeium"
if [ -f "$SETTINGS_DIR/codeium/config.json" ]; then
    create_symlink "$SETTINGS_DIR/codeium/config.json" "$HOME/.codeium/config.json"
fi

# Create ~/.windsurf symlink (Windsurf editor config)
mkdir -p "$HOME/.windsurf"
if [ -f "$SETTINGS_DIR/windsurf/argv.json" ]; then
    create_symlink "$SETTINGS_DIR/windsurf/argv.json" "$HOME/.windsurf/argv.json"
fi

# Create ~/.config/opencode symlink (OpenCode config)
mkdir -p "$HOME/.config/opencode"
if [ -f "$SETTINGS_DIR/opencode/opencode.json" ]; then
    create_symlink "$SETTINGS_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
fi

# Create ~/.ollama symlink (Ollama config)
mkdir -p "$HOME/.ollama"
if [ -f "$SETTINGS_DIR/ollama/config.json" ]; then
    create_symlink "$SETTINGS_DIR/ollama/config.json" "$HOME/.ollama/config.json"
fi

# Setup .env.local (symlink to ProtonDrive or local)
PROTON_SYNC_DIR="$HOME/Library/CloudStorage/ProtonDrive-master.icedog@pm.me-folder/Obsidian/vault/sync"
ENV_LOCAL_FILE="$HOME/.env.local"

# Create ProtonDrive sync folder if it doesn't exist
mkdir -p "$PROTON_SYNC_DIR"

PROTON_ENV_EXISTS=$([ -f "$PROTON_SYNC_DIR/env.local" ] && echo "yes" || echo "no")
LOCAL_ENV_EXISTS=$([ -f "$ENV_LOCAL_FILE" ] && echo "yes" || echo "no")
LOCAL_ENV_IS_SYMLINK=$([ -L "$ENV_LOCAL_FILE" ] && echo "yes" || echo "no")

echo ""

# Case 1: Both ProtonDrive and local env.local exist
if [ "$PROTON_ENV_EXISTS" = "yes" ] && [ "$LOCAL_ENV_EXISTS" = "yes" ] && [ "$LOCAL_ENV_IS_SYMLINK" = "no" ]; then
    echo "⚠️  Found both local ~/.env.local and ProtonDrive sync/env.local"
    read -p "Override ProtonDrive version with local? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📝 Copying local ~/.env.local to ProtonDrive..."
        cp "$ENV_LOCAL_FILE" "$PROTON_SYNC_DIR/env.local"
        chmod 600 "$PROTON_SYNC_DIR/env.local"
        rm "$ENV_LOCAL_FILE"
        ln -s "$PROTON_SYNC_DIR/env.local" "$ENV_LOCAL_FILE"
        echo "✓ ~/.env.local → $PROTON_SYNC_DIR/env.local"
    else
        echo "📝 Keeping ProtonDrive version, backing up local..."
        mv "$ENV_LOCAL_FILE" "${ENV_LOCAL_FILE}.backup-$(date +%s)"
        ln -s "$PROTON_SYNC_DIR/env.local" "$ENV_LOCAL_FILE"
        chmod 600 "$PROTON_SYNC_DIR/env.local"
        echo "✓ ~/.env.local → $PROTON_SYNC_DIR/env.local"
    fi

# Case 2: Only ProtonDrive env.local exists
elif [ "$PROTON_ENV_EXISTS" = "yes" ]; then
    echo "📝 Linking ~/.env.local to ProtonDrive sync..."
    if [ -L "$ENV_LOCAL_FILE" ]; then
        rm "$ENV_LOCAL_FILE"
    elif [ -f "$ENV_LOCAL_FILE" ]; then
        # Back up existing local .env.local
        mv "$ENV_LOCAL_FILE" "${ENV_LOCAL_FILE}.backup-$(date +%s)"
        echo "⚠️  Backed up existing ~/.env.local"
    fi
    ln -s "$PROTON_SYNC_DIR/env.local" "$ENV_LOCAL_FILE"
    chmod 600 "$PROTON_SYNC_DIR/env.local"
    echo "✓ ~/.env.local → $PROTON_SYNC_DIR/env.local"

# Case 3: Only local env.local exists
elif [ "$LOCAL_ENV_EXISTS" = "yes" ]; then
    echo "📝 Found local ~/.env.local"
    read -p "Copy to ProtonDrive for syncing? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$ENV_LOCAL_FILE" "$PROTON_SYNC_DIR/env.local"
        chmod 600 "$PROTON_SYNC_DIR/env.local"
        rm "$ENV_LOCAL_FILE"
        ln -s "$PROTON_SYNC_DIR/env.local" "$ENV_LOCAL_FILE"
        echo "✓ ~/.env.local → $PROTON_SYNC_DIR/env.local"
    else
        echo "✓ Keeping local ~/.env.local (not synced)"
        chmod 600 "$ENV_LOCAL_FILE"
    fi

# Case 4: Neither exists
else
    echo "📝 Creating ~/.env.local from template..."
    cp "$SETTINGS_DIR/.env.local.example" "$ENV_LOCAL_FILE"
    chmod 600 "$ENV_LOCAL_FILE"
    echo "⚠️  Edit ~/.env.local and add your actual API keys"
    read -p "Copy to ProtonDrive for syncing? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cp "$ENV_LOCAL_FILE" "$PROTON_SYNC_DIR/env.local"
        chmod 600 "$PROTON_SYNC_DIR/env.local"
        rm "$ENV_LOCAL_FILE"
        ln -s "$PROTON_SYNC_DIR/env.local" "$ENV_LOCAL_FILE"
        echo "✓ ~/.env.local → $PROTON_SYNC_DIR/env.local"
    fi
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.env.local and add your API keys"
echo "2. Reload your shell: source ~/.zshrc"
echo ""
