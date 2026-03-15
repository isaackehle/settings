# Settings

Dotfiles and Claude Code configuration synced across machines.

## What's Synced

### Public (in this repo)

- `zshrc` — shell configuration, PATH setup, aliases
- `claude/settings.json` — Claude Code model settings
- `claude/keybindings.json` — Claude Code keybindings
- Setup script and instructions

### Private (local only)

- `~/.env.local` — API keys and sensitive environment variables
- `~/.claude/hooks/` — custom Claude Code hooks (if any)
- `~/.claude/projects/` — project-specific memory

## Setup on a New Machine

### One-time setup:

```bash
cd ~/code/isaackehle/settings
chmod +x setup.sh
./setup.sh
```

This will:

1. Create symlinks from `~` to the settings repo
2. Generate `~/.env.local` from the template
3. Back up any existing config files

### Then:

1. Edit `~/.env.local` and add your API keys
2. Reload your shell: `source ~/.zshrc`

## Updating Configuration

### On either machine:

1. **For public changes** (zshrc, keybindings, etc.):
   - Edit the file in `~/code/isaackehle/settings/`
   - Commit and push
   - Pull on the other machine
   - Reload shell: `source ~/.zshrc`

2. **For private changes** (API keys, local overrides):
   - Edit `~/.env.local` directly (not tracked)
   - No need to sync

3. **For new API keys or private vars**:
   - Update `~/.env.local`
   - (Optional) Update `.env.local.example` template for documentation

## File Structure

```
settings/
├── zshrc                          # Zsh interactive shell (symlinked to ~/.zshrc)
├── zprofile                       # Zsh login shell (symlinked to ~/.zprofile)
├── bash_profile                   # Bash login shell (symlinked to ~/.bash_profile)
├── bashrc                         # Bash interactive shell (symlinked to ~/.bashrc)
├── .env.local.example             # Template for API keys
├── claude/
│   ├── settings.json              # Claude Code model (symlinked to ~/.claude/)
│   └── keybindings.json           # Claude Code keybindings
├── groq/
│   └── local-settings.json        # Groq CLI config (symlinked to ~/.groq/)
├── gemini/
│   ├── settings.json              # Gemini CLI config (symlinked to ~/.gemini/)
│   └── GEMINI.md                  # Gemini default instructions
├── codeium/
│   └── config.json                # Codeium config (symlinked to ~/.codeium/)
├── windsurf/
│   └── argv.json                  # Windsurf editor CLI args (symlinked to ~/.windsurf/)
├── setup.sh                       # Setup script for new machines
├── SETTINGS.md                    # This file
└── README.md                      # Vault overview
```

## Syncing Between Machines

1. **Make changes** on machine A
2. **Commit and push**: `git push`
3. **On machine B**: `git pull`
4. **Reload shell**: `source ~/.zshrc`

No manual syncing needed — git handles it.

## Supported Tools

### FNM (Fast Node Manager)
- Faster Rust-based Node.js version manager (replacement for Volta/NVM)
- Install: `brew install fnm`
- Per-project versions via `.node-version` files
- Automatic version switching with `--use-on-cd`

### Claude Code (Anthropic)
- `~/.claude/settings.json` — model preference
- `~/.claude/keybindings.json` — custom keybindings
- API key: `ANTHROPIC_API_KEY` in `~/.env.local`

### Groq CLI
- `~/.groq/local-settings.json` — model defaults, preferences
- API key: `GROQ_API_KEY` in `~/.env.local`

### Google Gemini CLI
- `~/.gemini/settings.json` — model defaults, MCP server config
- `~/.gemini/GEMINI.md` — default instructions for projects
- API key: `GEMINI_API_KEY` in `~/.env.local`

### Ollama
- Local models stored in `~/.ollama/models/` (NOT synced — large files)
- Configuration via environment variables: `OLLAMA_KEEP_ALIVE`, `OLLAMA_HOST`, etc.
- Already configured in `zshrc`
- **Sync manually**: Document which models to pull on each machine

### Codeium
- `~/.codeium/config.json` — telemetry and settings
- API key: Stored securely by Codeium (not in `~/.env.local`)
- Note: Most Codeium config lives in your editor (VS Code, Vim, Neovim) settings

### Windsurf Editor
- `~/.windsurf/argv.json` — CLI arguments and rendering settings
- Extensions: NOT synced (`~/.windsurf/extensions/` — install per machine)
- Settings: Via VS Code Settings Sync (GitHub/Microsoft account) or stored locally
- Note: `crash-reporter-id` is auto-generated per machine, not synced

### Other Tools
- DeepSeek: `DEEPSEEK_API_KEY` in `~/.env.local`
- OpenAI: `OPENAI_API_KEY` in `~/.env.local`

## Managing Secrets

Never commit API keys to git. Secrets are stored in `~/.env.local`, which can be:

1. **Synced via ProtonDrive** (recommended):
   - File: `$OBSIDIAN_VAULT/sync/env.local`
   - Automatically symlinked by `setup.sh`
   - Syncs across machines via ProtonDrive

2. **Local only** (fallback):
   - File: `~/.env.local`
   - Not tracked in git
   - Must be manually synced between machines

The `zshrc` automatically sources `~/.env.local` at the end:

```bash
# Content of ~/.env.local (or ProtonDrive sync/env.local)
export ANTHROPIC_API_KEY="sk-ant-..."
export DEEPSEEK_API_KEY="sk-..."
export GROQ_API_KEY="gsk_..."
```

### First-time setup:
If the ProtonDrive sync folder doesn't exist yet:
1. Run `setup.sh` to create the folder structure
2. Create `$OBSIDIAN_VAULT/sync/env.local` on your first machine
3. Add your API keys
4. On the second machine, run `setup.sh` — it will detect and symlink the ProtonDrive version

## Restoring from Backup

If `setup.sh` detected an existing config file, it created a backup:

```bash
# Restore from backup if needed
mv ~/.zshrc.backup-<timestamp> ~/.zshrc
```

## Notes

- Symlinks are used to keep configs in sync. If a symlink breaks, re-run `setup.sh`.
- `~/.claude/projects/` contains per-project memory and should be synced via ProtonDrive separately if needed.
- Ollama models are NOT synced — install and pull models on each machine as needed.
