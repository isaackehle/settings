---
tags: [ai, local, inference, distributed, apple-silicon]
---

# exo

Distributed inference engine that splits large models across multiple Apple Silicon Macs. Each device handles a slice of the model layers, enabling models that don't fit in a single machine's RAM.

- **GitHub:** [exo-explore/exo](https://github.com/exo-explore/exo)
- **API:** OpenAI-compatible at `http://0.0.0.0:52415/v1`

## How It Works

exo shards the model layer-by-layer across peers discovered via mDNS on the local network. Each Mac runs `exo` — no primary/secondary distinction. The node you send requests to aggregates the results.

> This is different from [[Olol]] (which load-balances between full-model instances) — exo actually splits one model across machines.

## Installation

```shell
pip install exo-inference
```

## Usage

```shell
# Run on each Mac (same command everywhere)
exo

# The node that receives requests handles routing
curl http://localhost:52415/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model": "llama-3.2-3b", "messages": [{"role": "user", "content": "Hello"}]}'
```

## Tradeoffs vs Single Machine

| | exo (distributed) | Single machine |
| --- | --- | --- |
| Max model size | Sum of all RAM | One machine's RAM |
| Token speed | Slower (network overhead) | Faster |
| Setup | All machines on same network | Just one machine |
| Wired vs WiFi | Wired strongly preferred | N/A |

## Tool Integration

Use `http://127.0.0.1:52415/v1` as the base URL wherever you'd normally point at Ollama:

- **OpenCode:** `baseURL` in provider config
- **Continue:** `apiBase` in model config
- **LiteLLM:** add as an OpenAI-compatible provider

## References

- [GitHub](https://github.com/exo-explore/exo)
- [exo Discord](https://discord.gg/exo-explore)
