# Work Stream: Restore Claw Ecosystem + Unified Tool Scout

Created: 2026-05-24
Scope: 2-ai tool scripts, setup_ai.sh registry, profile configs, tool-scout CLI

---

## Overview

We are expanding the settings repo's `2-ai/` scripts to cover the full "claw" ecosystem of AI personal assistant tools, and building a unified `tool-scout` for discovering and adding new tools across categories.

## Stage 1 — Restore & Add Claw Tools (HIGH PRIORITY)

### 1.1. Restore deleted claw scripts with real install methods

| Tool         | Install method                                     | Setup command                       | Category      |
| ------------ | -------------------------------------------------- | ----------------------------------- | ------------- |
| **OpenClaw** | `npm install -g openclaw@latest`                   | `openclaw onboard --install-daemon` | agent         |
| **ZeroClaw** | `curl \| bash` from gh releases                    | `zeroclaw onboard` (auto-runs)      | agent         |
| **IronClaw** | `brew install ironclaw` or `cargo build --release` | `ironclaw onboard`                  | agent         |
| **Hermes**   | `curl \| bash` from NousResearch                   | `hermes setup`                      | agent         |
| **PicoClaw** | `go install` or binary download                    | no setup wizard — config via TOML   | embedded/edge |

### 1.2. Add new claw script

| Tool         | Install method                                                                                  | Setup command                | Category |
| ------------ | ----------------------------------------------------------------------------------------------- | ---------------------------- | -------- |
| **ZeroClaw** | `curl -fsSL https://raw.githubusercontent.com/zeroclaw-labs/zeroclaw/master/install.sh \| bash` | auto-runs `zeroclaw onboard` | agent    |

### 1.3. Add zoocode.sh as VS Code extension setup

The original `zoocode.sh` was a VS Code extension config tool. Restore it but rebrand:

- Merge Cline-like settings.jsonc into VS Code user settings
- Handle `ZOO_CODE` model-specific configuration
- No separate binary — purely configuration deployment

### 1.4. Profile configs needed

```
2-ai/profiles/default/openclaw/.gitkeep     # config is JSON at ~/.openclaw/openclaw.json
2-ai/profiles/default/zeroclaw/.gitkeep      # config at ~/.zeroclaw/config.toml
2-ai/profiles/default/ironclaw/.gitkeep     # config at ~/.ironclaw/.env + ironclaw.yaml
2-ai/profiles/default/hermes/.gitkeep        # config at ~/.hermes/config.yaml
2-ai/profiles/default/picoclaw/.gitkeep    # config at ~/.config/picoclaw/config.toml
2-ai/profiles/default/zoocode/.gitkeep     # VS Code settings merge target
```

### 1.5. setup_ai.sh registration

Add `source` lines, `TOO_GROUPS` entries, `GROUP_SETUP_FUNCS`, `GROUP_VERIFY_FUNCS`, `DISPLAY_NAMES`, and backup/restore calls for:

- `openclaw` → `terminal-agents`
- `zeroclaw` → `terminal-agents`
- `ironclaw` → `terminal-agents`
- `hermes` → `terminal-agents`
- `picoclaw` → `terminal-agents`
- `zoocode` → `vscode-extensions`

---

## Stage 2 — Unified Tool Scout (MEDIUM PRIORITY)

Replace `agent-scout` and `model-scout` with one `tool-scout` CLI that covers:

### Categories

| Category            | What it finds                                          | Current source            |
| ------------------- | ------------------------------------------------------ | ------------------------- |
| `terminal-agents`   | AI CLI tools (claw family, llm, aichat, etc.)          | `agent-scout.py` CATALOG  |
| `vscode-extensions` | VS Code marketplace extensions (Continue, Cline, etc.) | Hardcoded list            |
| `mcp-servers`       | MCP servers from GitHub / npm                          | `mcp-builder` skill refs? |
| `cli-devtools`      | General dev CLI tools (ripgrep, fd, zoxide, etc.)      | Not yet covered           |
| `ollama-models`     | Local LLM models                                       | `model-scout.py`          |
| `brew-formulae`     | Homebrew packages related to AI/dev                    | Search `brew search`      |

### Commands

```bash
tool-scout list                          # Show all catalog entries not in repo
tool-scout list --category mcp-servers   # Filter by category
tool-scout search <query>                # Search catalog by name/description
tool-scout add <name>                    # Generate stub, config, register in setup_ai.sh
tool-scout update <name>               # Re-generate stub from latest catalog entry
tool-scout remove <name>                 # Delete script, config dir, remove from setup_ai.sh
tool-scout sync                          # Check all existing scripts against catalog for updates
tool-scout find-mcp <query>              # Search npm/github for MCP servers
tool-scout find-vscode <query>           # Search VS Code marketplace
tool-scout find-brew <query>             # Search Homebrew for AI/dev tools
```

### Catalog source

Build a `catalog.json` file (or `catalog/` directory with per-category JSON files) that is:

- Human-editable PR-friendly
- Versioned independently of scripts
- Sourced by `tool-scout.py`

```json
{
  "version": "2026-05-24",
  "terminal-agents": [
    {
      "name": "openclaw",
      "display_name": "OpenClaw",
      "description": "Personal AI assistant with 25+ messaging channels",
      "github": "openclaw/openclaw",
      "install_methods": [
        { "method": "npm", "command": "npm install -g openclaw@latest" },
        { "method": "pnpm", "command": "pnpm add -g openclaw@latest" }
      ],
      "binary": "openclaw",
      "setup_command": "openclaw onboard --install-daemon",
      "config_dir": "~/.openclaw",
      "config_file": "openclaw.json",
      "config_ext": "json"
    }
  ],
  "vscode-extensions": [
    {
      "name": "continue",
      "display_name": "Continue",
      "description": "Open-source AI code assistant",
      "marketplace_id": "Continue.continue",
      "install_command": "code --install-extension Continue.continue"
    }
  ]
}
```

---

## Stage 3 — Edge Device Tooling (FUTURE)

PicoClaw is the first step. Future additions:

- ESP-IDF toolchain (`brew install esp-idf`)
- `esptool.py` for flashing
- Cross-compilation awareness in profiles
- `rt-claw` (the actual embedded C project) as optional dev dependency

---

## Open Questions

1. Should `tool-scout` also manage `Home.md` index entries automatically?
2. Should `tool-scout add` prompt for profile-specific config or just create defaults?
3. Do we want a `tool-scout publish` that opens a PR template for new catalog entries?
4. Should `zoocode` keep the old name or be renamed to something more descriptive like `zoo-code-vscode`?
5. For PicoClaw: should the install script also set up Go ESP32 toolchain, or just document it?

---

## Tracking

| Task                         | Status    | Commit |
| ---------------------------- | --------- | ------ |
| Restore openclaw.sh          | COMPLETE  | 92f0dc4 |
| Restore ironclaw.sh          | COMPLETE  | 92f0dc4 |
| Restore picoclaw.sh          | COMPLETE  | 92f0dc4 |
| Restore hermes.sh            | COMPLETE  | 92f0dc4 |
| Add zeroclaw.sh              | COMPLETE  | 92f0dc4 |
| Add zoocode.sh               | COMPLETE  | 92f0dc4 |
| Update setup_ai.sh           | COMPLETE  | 92f0dc4 |
| Default profile configs      | COMPLETE  | 92f0dc4 |
| Create tool-scout.py catalog | COMPLETE  | f80f680 |
| Create tool-scout.sh CLI     | COMPLETE  | f80f680 |
| Syntax + commit              | COMPLETE  | f80f680 |
