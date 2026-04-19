---
tags: [ai, local, inference, distributed, apple-silicon]
---

# exo

Distributed inference engine that splits large models across multiple Apple Silicon Macs. Each device handles a slice of the model layers, enabling models that don't fit in a single machine's RAM.

- **GitHub:** [exo-explore/exo](https://github.com/exo-explore/exo)
- **API:** OpenAI-compatible at `http://localhost:52415/`
- **Dashboard:** `http://localhost:52415/` (built-in chat + cluster management UI)

## How It Works

exo shards the model layer-by-layer across peers discovered automatically via mDNS on the local network. Each Mac runs the same `exo` command — no primary/secondary distinction. The node you send requests to aggregates results. Topology-aware auto-parallel distribution means no manual sharding config.

> This is different from [[Olol]] (which load-balances between full-model instances) — exo splits one model's layers across machines.

## Prerequisites

- **Xcode** — provides Metal toolchain required for MLX compilation
- **brew** — package manager
- **uv** — Python dependency management
- **node** — for building the dashboard
- **Rust nightly** — for Rust bindings
- **macmon** — hardware monitoring on Apple Silicon (use pinned fork on M5 to avoid crashes)

## Installation

```shell
# Install dependencies
brew install uv node

# Install Rust nightly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup toolchain install nightly

# Install macmon — use pinned fork for M5 compatibility
cargo install --git https://github.com/vladkels/macmon \
  --rev a1cd06b6cc0d5e61db24fd8832e74cd992097a7d \
  macmon \
  --force

# Clone and build
git clone https://github.com/exo-explore/exo
cd exo/dashboard && npm install && npm run build && cd ..
```

## Usage

```shell
# Run on each Mac (same command on every node)
uv run exo

# Coordinator-only node (no inference, just routing — useful for a machine with no GPU)
uv run exo --no-worker
```

Nodes discover each other automatically. Open `http://localhost:52415/` to see the cluster topology, load models, and chat.

## API

exo is drop-in compatible with multiple API formats:

- **OpenAI Chat Completions** — point any OpenAI client at `http://localhost:52415/v1`
- **Claude Messages API** — compatible endpoint for Anthropic-style requests
- **Ollama API** — compatible with Ollama clients

```shell
curl http://localhost:52415/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama-3.2-3b",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

Models are specified by HuggingFace ID. Custom model cards go in `~/.local/share/exo/custom_model_cards/`.

## Tool Integration

Use `http://localhost:52415/v1` as the base URL wherever you'd normally point at Ollama or LiteLLM:

- **LiteLLM:** add as an OpenAI-compatible provider in `litellm.yaml`
- **Continue:** `provider: openai`, `apiBase: http://localhost:52415/v1`
- **Claude Code:** `ANTHROPIC_BASE_URL=http://localhost:52415`
- **OpenCode:** `baseURL: http://localhost:52415/v1` in provider config

## Tradeoffs vs Single Machine

| | exo (distributed) | Single machine |
|---|---|---|
| Max model size | Sum of all RAM across nodes | One machine's RAM |
| Token speed | Slower (network overhead) | Faster |
| Thunderbolt RDMA | 99% latency reduction vs WiFi | N/A |
| Setup | All machines on same network | Just one machine |

Wired (Thunderbolt or Ethernet) is strongly preferred over WiFi. RDMA over Thunderbolt requires macOS ≥26.2.

## File Locations (macOS/Linux)

| Purpose | Path |
|---|---|
| Config | `~/.config/exo/` |
| Data / custom model cards | `~/.local/share/exo/` |
| Cache / logs | `~/.cache/exo/` |

Override with standard XDG environment variables (`$XDG_CONFIG_HOME`, etc.).

## References

- [GitHub](https://github.com/exo-explore/exo)
- [exo Discord](https://discord.gg/exo-explore)
- [[AI Setup Architecture]]
- [[Olol]]
