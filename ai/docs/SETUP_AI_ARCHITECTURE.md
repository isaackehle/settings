# AI Setup Pipeline — Architecture Reference

## Two-Repo Layout

The AI pipeline is split across two repositories. `setup_ai.sh` orchestrates
both.

```
~/code/isaackehle/
├── settings/                      "settings" repo
│   ├── helpers.sh                 ← Shared functions (logging, brew, wizard, etc.)
│   ├── setup_core.sh              ← macOS base (Homebrew, shell, system tools)
│   ├── setup_config.sh            ← Dotfiles & Claude config deployment
│   ├── editors/                   ← Editor install functions (continue, cursor,
│   │                                  vscode, zed, devin, kilocode, etc.)
│   └── ai/
│       ├── setup_ai.sh            ← MAIN ENTRYPOINT — orchestrates everything
│       ├── config/                ← Config files deployed to ~/
│       └── docs/                  ← Operational docs (this folder)
│
└── homelab/                       "homelab" repo (separate git repo)
    ├── agents/                    ← Agent install functions (aider, claude, codex,
    │                                  crush, fabric, gemini, goose, grok, hermes,
    │                                  ironclaw, llm, opencode, pi, plandex, …)
    ├── cloud/                     ← Cloud providers (groq, openrouter)
    ├── other/                     ← Auxiliary tools (anythingllm, exo, olol,
    │                                  openwebui, tabby)
    ├── runtimes/                  ← Runtime scripts (ollama, lmstudio, omlx,
    │                                  llama-server, install-models, paths, etc.)
    └── profiles/                  ← Machine-specific model configs
        ├── macbook-m5-64gb/
        ├── macmini-m2-16gb/
        └── …
```

## Key Path Resolution

Every sourced script starts with this guard:

```bash
if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"
```

**What `SETTINGS_BASE` resolves to:**

| Script location | `SETTINGS_BASE` |
|---|---|
| `settings/editors/vscode.sh` | `settings/` |
| `settings/ai/setup_ai.sh` | `settings/` (explicitly set before sourcing) |
| `homelab/agents/aider.sh` | `homelab/` |
| `homelab/runtimes/ollama.sh` | `homelab/` |

**Rule:** `SETTINGS_BASE` = root of the repo the script lives in.

## Environment Variables

Set in `~/.env.local`, `~/.profile`, or export before running.

| Variable | Used by | Purpose | Default |
|---|---|---|---|
| `HOMELAB` | `setup_ai.sh` | Path to homelab repo | `$HOME/code/isaackehle/homelab` |
| `SETTINGS_BASE` | All scripts | Auto-detected (don't export manually) | — |
| `MACHINE_PROFILE` | Most install funcs | Force a profile (e.g. `macbook-m5-64gb`) | Auto-detected |
| `OPENROUTER_API_KEY` | `openrouter.sh` | OpenRouter API key | — |
| `GEMINI_API_KEY` | `gemini.sh` | Gemini API key | — |
| `GROK_API_KEY` | `grok.sh` | xAI Grok key | — |
| `HOMEASSISTANT_URL` | `deploy_mcp` | HA server URL for MCP templating | — |
| `HOMEASSISTANT_TOKEN` | `deploy_mcp` | HA long-lived token | — |

## New-Machine Setup

```bash
# 1. Clone both repos
git clone git@github.com:isaackehle/settings.git ~/code/isaackehle/settings
git clone git@github.com:isaackehle/homelab.git  ~/code/isaackehle/homelab

# 2. Pre-seed secrets (optional — avoids interactive prompts later)
cat > ~/.env.local <<EOF
OPENROUTER_API_KEY=sk-...
GEMINI_API_KEY=AI...
GROK_API_KEY=xai-...
HOMEASSISTANT_URL=http://homeassistant:8123
HOMEASSISTANT_TOKEN=ey...
EOF

# 3. Core macOS setup (Homebrew, shell, system tools)
bash ~/code/isaackehle/settings/setup_core.sh

# 4. Dotfiles & Claude Code config
bash ~/code/isaackehle/settings/setup_config.sh

# 5. AI pipeline (interactive wizard)
bash ~/code/isaackehle/settings/ai/setup_ai.sh
```

## Migration Guide (old → new paths)

The homelab scripts were originally written assuming all files lived under
`settings/ai/...`. They've since been moved to a separate repo. Any path
starting with `${SETTINGS_BASE}/ai/...` is now broken.

```bash
# Verify no broken references remain
grep -rn '${SETTINGS_BASE}/ai/' ~/code/isaackehle/homelab --include="*.sh"
grep -rn '${SETTINGS_BASE}/ai/' ~/code/isaackehle/settings --include="*.sh"
```

**Translation table:**

| Old (broken) | New (correct) |
|---|---|
| `${SETTINGS_BASE}/ai/profiles/<profile>/aider/…` | `${SETTINGS_BASE}/profiles/<profile>/aider/…` |
| `${SETTINGS_BASE}/ai/runtimes/ollama.sh` | `${SETTINGS_BASE}/runtimes/ollama.sh` |
| `${SETTINGS_BASE}/ai/other/exo.sh` | `${SETTINGS_BASE}/other/exo.sh` |
| `${SETTINGS_BASE}/ai/cloud/openrouter.sh` | `${SETTINGS_BASE}/cloud/openrouter.sh` |
| `${SETTINGS_BASE}/ai/agents/hermes.sh` | `${SETTINGS_BASE}/agents/hermes.sh` |
| `bash ai/profiles/prune_models.sh` | `bash profiles/prune_models.sh` |

## Writing a New Install Script

```bash
#!/usr/bin/env bash

if [ -z "${SETTINGS_BASE:-}" ]; then
    SETTINGS_BASE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
fi
. "${SETTINGS_BASE}/helpers.sh"

install_my_tool() {
    print_step "My Tool"
    if ! command_exists my-tool; then
        brew install my-tool
        print_status "Installed my-tool"
    fi
    local cfg="${SETTINGS_BASE}/profiles/${MACHINE_PROFILE}/my-tool/config.yaml"
    if [ -f "$cfg" ]; then
        mkdir -p "$HOME/.config/my-tool"
        cp "$cfg" "$HOME/.config/my-tool/config.yaml"
        print_status "Deployed my-tool config"
    fi
}
```

- Use `command_exists` for idempotent tool checks
- Use `print_step/status/info/warning/error` for formatting
- Functions should be side-effect-free when sourced; the wizard calls them
- Use `${SETTINGS_BASE}/profiles/...` — never `${SETTINGS_BASE}/ai/profiles/...`
