# Model Strategy — Distributed Local Fleet + Cloud Fallback

## Architecture

Each Apple Silicon machine runs **llama-swap** on port 10000. Tool configs point to
`localhost:10000` and never change regardless of which machine you're on. llama-swap
manages individual `llama-server` processes per model, swapping in/out on demand.

### Fallback chain

```
localhost:10000  (llama-swap — local models first)
  │
  ├─ local cmd models  →  served by this machine's llama-server
  ├─ proxy models      →  forwarded to discovery (100.64.0.1:10000)
  └─ unavailable       →  tool falls back to openrouter (cloud)
```

Tool configs also expose `llama-discovery` (100.64.0.1:10000) as an explicit second
provider — use it to target discovery directly when bypassing local llama-swap.

### Why llama-swap over llama-server --models-preset

The native router mode runs all models in one process with known swap instability.
llama-swap is an external Go proxy that starts a fresh `llama-server` per model —
more stable, same port, zero changes to tool configs.

---

## Fleet

| Hostname   | Hardware     | RAM  | Type        | llama-swap | Profile dir            |
|------------|--------------|------|-------------|------------|------------------------|
| discovery  | M5 Max       | 64GB | MacBook Pro | ✅ gateway | `macbook-m5-64gb`      |
| DS9        | M2 Pro       | 32GB | Mac mini    | ✅ server  | `macmini-m2-16gb`*     |
| enterprise | M1 Pro       | 16GB | MacBook Pro | ✅ laptop  | `macbook-m1-16gb`      |
| DX1        | Intel Core i9| 16GB | MacBook Pro | ❌ CPU-only| `macbook-intel-2019-16gb` |

*DS9 uses the `macmini-m2-16gb` profile dir but has 32GB — the llama-swap.yaml is
written for its actual 32GB capacity.

**Pending:** amethyst (M2 Max 36GB) — not in fleet yet.

---

## Model Ownership per Machine

### discovery — M5 Max 64GB (gateway)

Owns all 17 models. Other machines proxy here for anything too large to run locally.

| TTL | Models |
|-----|--------|
| always-warm | `qwen3-coder-30b`, `qwen3.5-4b`, `nomic-embed-text` |
| on-demand (5 min) | all 27–80B models, codestral, medium distills |

### DS9 — M2 Pro 32GB (headless always-on server)

Key role: always-warm embedding + fast models available 24/7 even when laptops sleep.

| TTL | Models |
|-----|--------|
| always-warm | `nomic-embed-text`, `qwen3.5-4b`, `qwen3-4b-it`, `qwen2.5-coder-1.5b` |
| on-demand | `codestral-22b`, `qwen3-coder-30b`, `qwen3-14b-sonnet4.5`, 7–8B models |
| proxy → discovery | `deepseek-r1-32b`, all 27B+, `qwen3-coder-next-80b` |

### enterprise — M1 Pro 16GB (laptop)

| TTL | Models |
|-----|--------|
| always-warm | `nomic-embed-text`, `qwen3.5-4b`, `qwen3-4b-it`, `qwen2.5-coder-1.5b` |
| on-demand | `qwen3-8b-sonnet4.5`, `qwen3-14b` (4K ctx, tight), `deepseek-r1-7b`, 7B models |
| proxy → discovery | `codestral-22b`, `qwen3-coder-30b`, all 27B+ |

### DX1 — Intel 16GB (cloud-only)

No llama-swap. Tool configs fall through directly to `openrouter`. CPU inference at
7B+ is too slow for practical use.

---

## TTL Guide

| Value | Meaning | Use for |
|-------|---------|---------|
| `86400` | Always-warm (24h) | Primary coder, embedding, fast planning |
| `300` | Session-warm (5 min) | Heavy models during active work |

---

## Install

```bash
# On discovery, DS9, enterprise:
cd ~/code/isaackehle/settings/ai/runtimes
./install-llama-swap.sh

# What it does:
#  1. brew tap mostlygeek/llama-swap && brew install llama-swap
#  2. Copies ai/profiles/<profile>/llama-swap.yaml → /usr/local/lib/llama-models/
#  3. Unloads org.kehle.llama-router (old llama-server router)
#  4. Installs + loads com.kehle.llama-swap on port 10000

# Verify:
curl -s http://localhost:10000/health
curl -s http://localhost:10000/running | jq .
open http://localhost:10000/ui
```

---

## Proxy Routing

Proxy entries forward requests by model name to the target machine's llama-swap.
The target must have that model registered (discovery has all of them).

If the proxy target (discovery) is unreachable → HTTP error → tool tries `openrouter`.

**discovery Tailscale IP:** `100.64.0.1` (hardcoded in all fleet configs)

---

## Provider Config in Tool Configs

```
llama-gp-router  →  localhost:10000        (this machine's llama-swap)
llama-discovery  →  100.64.0.1:10000      (discovery direct — bypass local swap)
openrouter       →  cloud fallback
ollama           →  localhost:11434        (embedding only, when Ollama is running)
```

## Future: amethyst (M2 Max 36GB)

When added: create `macbook-m2-36gb` profile, llama-swap.yaml similar to DS9 but
with slightly more headroom (36GB → can hold 27B models locally without proxying).
