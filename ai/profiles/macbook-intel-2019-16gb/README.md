# macbook-intel-2019-16gb

Profile for the **2019 16" MacBook Pro (Intel Core i7/i9, AMD Radeon Pro dGPU)**
parked in the garage as a secondary/utility inference node.

## Hardware

| Spec | Value |
| --- | --- |
| CPU | Intel Core i7-9750H or i9-9880H (9th gen Coffee Lake, 6c/8c) |
| RAM | 16 GB DDR4 (discrete — **no** unified memory) |
| dGPU | AMD Radeon Pro 4 GB (560X) or 8 GB (5500M / 555X) |
| iGPU | Intel UHD 630 (not used for LLM) |
| macOS | macOS 26.6 (Tahoe) — still supported but EOL in 2027 |

## Why this profile exists

Same 16 GB budget as `macbook-m1-16gb`, but the execution substrate is very
different:

- **No Apple Silicon → no unified memory.** Ollama cannot spill model state
  into GPU memory; everything competes for the 16 GB DDR4 pool.
- **dGPU has 4-8 GB VRAM.** Too small for any model at a useful context
  window, and Metal/ROCm support in Ollama on Intel macs is partial.
- **Reliable path: CPU-only.** Set `OLLAMA_NUM_GPU=0` in the LaunchAgent.

This box is meant to be a **secondary inference node** reached over Tailscale
from the main M5 Max when the primary is busy or off. It is **not** a
workhorse. Heavier jobs should go to the main machine.

## Model stack

Inherits the lightweight 16 GB stack from `macbook-m1-16gb` (see that
profile for the full model map). Highlights:

| Role | Model | Size |
| --- | --- | --- |
| Primary coder | `qwen2.5-coder:7b` | ~5 GB |
| Reasoning | `deepseek-r1:7b` | ~5 GB |
| General | `qwen3:14b` | ~11 GB (solo) |
| Fast / planning | `qwen3:4b` | ~2.5 GB |
| Autocomplete | `qwen2.5-coder:1.5b` | ~1 GB |
| Embeddings | `nomic-embed-text` | ~0.3 GB |

Solo mode budget: ~10 GB usable after macOS overhead.

## Networking

The garage box should bind Ollama to all interfaces so the main M5 Max can
reach it over Tailscale:

```bash
# /etc/hostname (or in ollama LaunchAgent EnvironmentVariables)
OLLAMA_HOST=0.0.0.0:11434
```

On the main M5 Max, hit it as a normal Tailscale node:

```bash
# main M5 Max side
curl http://<tailscale-ip-of-garage-box>:11434/api/tags
```

If you want a transparent Tailscale-routed model alias on the main box,
add an entry to `~/.ollama/config.json`:

```json
{
  "models": {
    "garage-deepseek-r1": "http://<tailscale-ip>:11434"
  }
}
```

## Files in this profile

| File | Purpose |
| --- | --- |
| `PROFILE` | Machine descriptor (memory range, computer types). |
| `models.sh` | Model definitions, tool assignments, ollama cloud manifest. Inherits the m1-16gb stack with Intel-specific CPU-first notes. |
| `models.json` | Per-model GGUF/HF source/quant metadata. |
| `model-map.md` | Human-readable model assignment matrix and materialization graph. Regenerate with `generate-model-map.sh`. |
| `ollama/config.json` | Tool integration aliases and "last model" state. Has Intel-specific `_ollama_env_notes`. |
| `com.kehle.ollama.intel-2019.plist` | **LaunchAgent override for the Intel box** — CPU-only, single resident model, Tailscale-friendly host binding. Copy to `~/Library/LaunchAgents/com.kehle.ollama.plist` on the garage machine. |
| `claude/settings.json` | Claude Code → Ollama aliases. |
| `continue/config.yaml` | Continue (VS Code) → Ollama/OpenRouter models. |
| `opencode/opencode.jsonc` | OpenCode agents (build/code/plan/think/...). |
| `crush/crush.json` | Crush. |
| `cursor/settings.jsonc` | Cursor. |
| `gemini/settings.json` | Gemini CLI. |
| `grok/grok.json` | Grok CLI. |
| `groq/local-settings.json` | Groq (whisper, etc.). |
| `kilocode/{kilo,settings}.jsonc` | Kilo Code (VS Code). |
| `zed/settings.json` | Zed editor assistant. |
| `aider/aider.conf.yml` | Aider CLI. |
| `README.md` | This file. |

## First-time setup on the garage box

```bash
# 1. Install Ollama
brew install ollama

# 2. Copy the Intel-tuned LaunchAgent and load it
cp com.kehle.ollama.intel-2019.plist ~/Library/LaunchAgents/com.kehle.ollama.plist
launchctl unload ~/Library/LaunchAgents/com.kehle.ollama.plist 2>/dev/null
launchctl load -w ~/Library/LaunchAgents/com.kehle.ollama.plist

# 3. Install Tailscale and bring it up
brew install --cask tailscale
tailscale up

# 4. Pull the 16GB stack
ollama pull qwen2.5-coder:7b
ollama pull qwen3:4b
ollama pull qwen3:14b
ollama pull deepseek-r1:7b
ollama pull qwen2.5-coder:1.5b
ollama pull nomic-embed-text
ollama pull deepseek-r1-tools:8b
ollama pull qwen3-8b:sonnet4.5
ollama pull qwen3.5:4b
ollama pull qwen2.5-7b:multi

# 5. Verify
curl http://localhost:11434/api/tags
```

## Tailscale reach from the main M5 Max

```bash
# Find the Intel box's Tailscale IP
tailscale status | grep <garage-box-name>

# Test inference
curl -X POST http://<tailscale-ip>:11434/api/generate \
  -d '{"model":"qwen2.5-coder:7b","prompt":"hello","stream":false}'
```

---

Created 2026-06-13. Mirrors `macbook-m1-16gb` for the Intel 2019 MBP with
CPU-first execution and Tailscale-friendly network mode.
