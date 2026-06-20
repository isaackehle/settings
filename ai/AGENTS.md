# Homelab — Agent Instructions

This is `isaackehle/homelab`, a private repo for local network and AI inference configuration.

## What's Here

```
profiles/          Per-machine tool configs (kilo, opencode, continue, aider, etc.)
  macbook-m5-64gb/ discovery — M5 Max 64GB, primary + llama-swap gateway
  macmini-m2-16gb/ DS9 — M2 Pro 32GB Mac mini, headless always-on server
  macbook-m1-16gb/ enterprise — M1 Pro 16GB laptop
  macbook-intel-2019-16gb/ DX1 — Intel, cloud-only

router/            llama-swap config, launchd plist, models.ini
runtimes/          Install scripts (install-llama-swap.sh, install-models.sh, paths.sh)
agents/            Agentic helper scripts
MODEL_STRATEGY.md  Distributed fleet architecture and model ownership
```

## Machine Fleet

| Hostname   | Hardware    | RAM  | Role                         |
|------------|-------------|------|------------------------------|
| discovery  | M5 Max      | 64GB | Primary + llama-swap gateway |
| DS9        | M2 Pro mini | 32GB | Headless always-on server    |
| enterprise | M1 Pro      | 16GB | Lightweight laptop           |
| DX1        | Intel       | 16GB | Cloud-only (no local LLM)    |

Tailscale: discovery is at `100.64.0.1`. All proxy entries point there.

## Key Conventions

- **Profile directories** are named by hardware spec, not hostname. The `PROFILE` file inside each declares `NAME`, `MEMORY`, `COMPUTER_TYPES` etc. for auto-detection.
- **llama-swap configs** live at `profiles/<profile>/llama-swap.yaml`. The install script copies the right one to `/usr/local/lib/llama-models/llama-swap.yaml`.
- **Model IDs** (e.g. `qwen3-coder-30b`) must match exactly between the llama-swap YAML and what tool configs send in API requests.
- **Port 10000** is the standard inference port across all machines (llama-swap).
- **100.64.0.1** is the discovery gateway — all smaller machines proxy heavy models here.

## Common Tasks

**Add a new model to the fleet:**
1. Add entry to `profiles/<profile>/models.json`
2. Add entry to `profiles/<profile>/llama-swap.yaml` (local cmd or proxy)
3. Run `ai/runtimes/install-models.sh` on the target machine
4. Run `ai/runtimes/install-llama-swap.sh` to reload the config

**Update a tool config (kilo/opencode):**
- Files are at `profiles/<profile>/kilocode/kilo.jsonc` and `profiles/<profile>/opencode/opencode.jsonc`
- Provider order: `llama-gp-router` (local) → `llama-discovery` (gateway direct) → `openrouter`

**Deploy llama-swap on a new machine:**
```bash
cd ~/code/isaackehle/homelab
./runtimes/install-llama-swap.sh
```

## Sensitive Values

- `OPENROUTER_API_KEY` — in shell env, never in repo
- `HOMEASSISTANT_TOKEN` — in shell env, never in repo
- Tailscale IPs for non-gateway machines — TBD, fill into llama-swap proxy entries after `tailscale status`

## Style

- YAML files use 2-space indent
- JSONC files allow comments; keep them
- Shell scripts: `set -euo pipefail`, functions for repeated logic
- Commit style: `feat(profiles): ...`, `fix(router): ...`, `chore(runtimes): ...`
