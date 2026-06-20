# Homelab Repo Structure

How this repo is organized, how decisions are recorded, and how config flows from here to machines.

---

## Directory Layout

```
homelab/
├── AGENTS.md                    ← AI agent instructions (conventions, fleet, sensitive vars)
├── CLAUDE.md                    ← Delegates to AGENTS.md; sets editor to Helix
├── STRUCTURE.md                 ← This file
│
├── config/                      ← Files that get deployed to ~ on each machine
│   ├── ssh_config               → ~/.ssh/config       (fleet SSH aliases + TERM fix)
│   └── profile.d/               → ~/.profile.d/       (sourced by shell on login)
│       ├── _ai                  ← AI workspace paths
│       ├── _claude_code         ← Claude Code env
│       ├── _devin               ← Devin agent env
│       ├── _fabric              ← Fabric CLI env
│       ├── _gemini              ← Gemini CLI → local proxy routing
│       ├── _grok                ← Grok CLI → Ollama routing
│       ├── _home_assistant      ← HA URL + token env vars
│       ├── _lmstudio            ← LM Studio PATH
│       ├── _ollama              ← Ollama aliases (model-scout, suggest-models)
│       ├── _tty                 ← SSH TERM fix (xterm-256color when SSH_CONNECTION set)
│       └── _windsurf            ← Windsurf env
│
├── docs/                        ← Reference and operational documentation
│   ├── MODELS.md                ← Model roster: what's loaded where and why
│   ├── TOOLS.md                 ← All AI tools in the setup, roles, install locations
│   ├── SOURCES.md               ← Where model decisions came from; re-check URLs
│   ├── SUGGESTIONS.md           ← Ideas to evaluate (not yet decided)
│   ├── Tailscale.md             ← Tailscale setup and fleet IP reference
│   ├── network-wakeup.md        ← Wake on LAN, pmset, keeping machines responsive
│   ├── github-ssh-setup.md      ← SSH key gen → GitHub; ssh-copy-id fleet
│   ├── terminal-sync.md         ← SSH TERM/STTY fix; doubled-char debugging
│   ├── agent-memory-setup.md    ← AI agent memory configuration
│   ├── AI_SETUP_REPEATABLE_WORKFLOW.md  ← Full setup walkthrough
│   ├── llama-router-testing.md  ← Historical: llama-server router testing notes
│   ├── llama-server-three-backend-workflow.md  ← Historical: 3-backend llama.cpp setup
│   ├── local-llm-quality-diagnosis.md   ← Diagnosing local LLM output quality issues
│   ├── local-llm-quality-fixes.md       ← Fixes applied
│   ├── local-llm-agent-comparison-june-2026.md  ← Agent comparison study
│   ├── ollama-model-registration.md     ← Ollama model naming + registration
│   ├── ollama-multimodel-cheatsheet.md  ← Ollama multi-model quick reference
│   ├── opencode-learnings-june-2026.md  ← OpenCode operational learnings
│   ├── openrouter-optimization-guide.md ← OpenRouter cost/latency optimization
│   └── openrouter-output.md             ← OpenRouter output reference
│
├── docs/decisions/              ← Why the setup is the way it is
│   ├── ai-tool-comparison-june-2026.md   ← Head-to-head tool comparison
│   ├── ai-tool-paid-tiers-june-2026.md   ← Cost analysis across paid services
│   ├── opencode-go-vs-zen-vs-openrouter.md  ← Routing strategy decision
│   └── deprecated-tools.md      ← Tools removed from setup + reasons
│
├── profiles/                    ← Machine-specific configs (one dir per hardware profile)
│   ├── macbook-m5-64gb/         ← discovery: M5 Max 64GB
│   ├── macmini-m2-16gb/         ← DS9: M2 Pro 32GB (profile named for 16GB min RAM)
│   ├── macbook-m1-16gb/         ← enterprise: M1 Pro 16GB
│   └── macbook-m2-32gb/         ← (future: amethyst or similar 32GB MacBook)
│
│   Each profile contains:
│   ├── llama-swap.yaml          ← Model roster: local cmd: or proxy: entries, TTL
│   ├── opencode/opencode.jsonc  ← OpenCode model assignments per role
│   ├── continue/config.yaml     ← Continue extension model roles
│   ├── ollama/                  ← Ollama model list, config.json
│   ├── claude/settings.json     ← Claude Code model settings
│   └── ...                      ← Other tool configs
│
├── runtimes/                    ← Install and management scripts
│   ├── install-llama-swap.sh    ← Install llama-swap + copy profile yaml + load plist
│   ├── update-all-profiles.sh   ← Sync profile configs to all machines
│   ├── llama-status.sh          ← Check llama-swap health across fleet
│   ├── model-scout.sh/.py       ← Discover available models on Ollama/HuggingFace
│   ├── agent-scout.sh/.py       ← Discover available AI agents
│   └── tool-scout.sh/.py        ← Catalog installed AI tools
│
├── router/                      ← LaunchAgent plists
│   └── com.kehle.llama-swap.plist  ← Runs llama-swap on port 10000 at login
│
└── setup_ai.sh                  ← Top-level setup entrypoint (orchestrates runtimes/)
```

---

## How Config Flows to Machines

```
homelab repo
    │
    ├── config/ssh_config
    │       └─ cp config/ssh_config ~/.ssh/config && chmod 600 ~/.ssh/config
    │
    ├── config/profile.d/*
    │       └─ cp config/profile.d/* ~/.profile.d/
    │          (or symlink: ln -sf $PWD/config/profile.d/* ~/.profile.d/)
    │
    ├── profiles/<hardware>/llama-swap.yaml
    │       └─ install-llama-swap.sh auto-detects hardware profile,
    │          copies yaml → /usr/local/lib/llama-models/llama-swap.yaml
    │
    ├── profiles/<hardware>/<tool>/config
    │       └─ each tool's install script or update-all-profiles.sh
    │          copies to the tool's expected config location
    │
    └── router/com.kehle.llama-swap.plist
            └─ install-llama-swap.sh patches username + binary path,
               loads via: launchctl load ~/Library/LaunchAgents/com.kehle.llama-swap.plist
```

### Quick deploy on a new machine

```bash
# 1. Clone
git clone git@github.com:isaackehle/homelab.git ~/code/isaackehle/homelab
cd ~/code/isaackehle/homelab

# 2. SSH config
cp config/ssh_config ~/.ssh/config && chmod 600 ~/.ssh/config

# 3. Shell profile entries
cp config/profile.d/* ~/.profile.d/
source ~/.profile.d/_ollama   # or open new shell

# 4. llama-swap (discovery, DS9, enterprise only — not DX1)
./runtimes/install-llama-swap.sh

# 5. Tool configs
./setup_ai.sh
```

---

## How Decisions Are Made and Saved

### Decision flow

```
Idea / problem
    ↓
Research → docs/decisions/<topic>-<date>.md   (comparison, cost analysis, etc.)
    ↓
Decision made → MODELS.md updated (what's running where)
              → profiles/<hw>/llama-swap.yaml updated (model cmd + ttl)
              → profiles/<hw>/<tool>/ updated (which model per role)
    ↓
Old approach retired → docs/decisions/deprecated-tools.md (what, why, when)
```

### Where things are recorded

| What | Where |
|------|-------|
| What models run on which machine | `docs/MODELS.md` + `profiles/*/llama-swap.yaml` |
| Why a model was chosen for a role | `docs/decisions/ai-tool-comparison-*.md` |
| Why the routing architecture is as it is | `docs/decisions/opencode-go-vs-zen-vs-openrouter.md` |
| Source of truth for model names/tags | `docs/SOURCES.md` |
| Ideas not yet acted on | `docs/SUGGESTIONS.md` |
| Tools removed and why | `docs/decisions/deprecated-tools.md` |
| Fleet hardware + Tailscale IPs | `docs/Tailscale.md` (and OneDrive: Smart Home/machines.md) |

### Updating a model

1. Edit `profiles/<hardware>/llama-swap.yaml` — update `cmd:` line with new model path/flags
2. Update `docs/MODELS.md` — role assignment table
3. Add a row to `docs/SOURCES.md` — where you confirmed the model tag
4. On the machine: `./runtimes/install-llama-swap.sh` to pick up the new yaml
5. Commit: `git commit -m "feat(models): replace X with Y on <profile> — <reason>"`

### Adding a new tool

1. Create `profiles/<hardware>/<tool>/` with tool config
2. Add install step to `setup_ai.sh` or create `runtimes/install-<tool>.sh`
3. Add profile.d entry in `config/profile.d/_<tool>` if env vars needed
4. Document in `docs/TOOLS.md`
5. If it replaces something, add entry to `docs/decisions/deprecated-tools.md`

---

## Port and Address Conventions

| Thing | Value |
|-------|-------|
| llama-swap port | `10000` (same on all machines) |
| discovery Tailscale IP | `100.64.0.1` (gateway; machines proxy to this) |
| Tailscale domain | `tail303fda.ts.net` |
| SSH user | `isaac` |
| Models dir | `/usr/local/lib/llama-models/` |
| llama-swap config | `/usr/local/lib/llama-models/llama-swap.yaml` |
| LaunchAgents | `~/Library/LaunchAgents/com.kehle.llama-swap.plist` |

---

## Sensitive Values

Never committed to the repo. Set via shell environment or 1Password:

| Variable | Used by |
|----------|---------|
| `OPENROUTER_API_KEY` | OpenCode, Continue, Gemini CLI cloud fallback |
| `HOMEASSISTANT_TOKEN` | HA API calls from shell / agents |
| `HOMEASSISTANT_URL` | HA base URL |

Set in `~/.env.local` (sourced by shell) or via 1Password CLI:
```bash
export OPENROUTER_API_KEY=$(op read "op://Personal/OpenRouter/credential")
```
