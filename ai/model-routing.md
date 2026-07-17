# Model Routing Policy

**Created:** 2026-07-16
**Last updated:** 2026-07-16 (initial)
**Rule:** Any config change to an AI tool must check this file for the recommended default model/provider before proceeding.

---

## Quick Reference

| Tool                   | Config Location                                  | Current Provider                               | Recommended Model                                                               | Notes                                                                    |
| ---------------------- | ------------------------------------------------ | ---------------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| Hermes CLI (discovery) | `homelab/profiles/discovery/hermes/config.yaml`  | LM Studio → Ollama fallback                    | `hermes-qwen3.5-35b-a3b-Q6_K.gguf` via LM Studio (primary), Ornith as secondary | Pin Hermes 4, disable Ollama for now                                     |
| Crush                  | `settings/ai/config/crush.json`                  | Ollama → OpenRouter fallback                   | LM Studio primary + Ollama as tiered fallback                                   | Hybrid: switch to LM Studio but keep Ollama tiers commented-out/inactive |
| OpenCode               | `settings/ai/config/opencode.jsonc`              | Ollama (primary) + OpenRouter (cloud)          | Add LM Studio provider, route select agents there                               | Hybrid: add lmstudio provider alongside ollama, selectively route agents |
| Continue               | `editors/continue.sh`, `~/.continue/config.json` | TBD (not actively configured in settings repo) | LM Studio when active                                                           | Separate setup task — not part of current routing pass                   |
| Devin Desktop          | `editors/devin.sh`, `~/Applications/Devin.app`   | Ollama (autocomplete via localhost:11434)      | LM Studio for autocomplete                                                      | Point IDE AI settings to LM Studio; disable Ollama autocomplete          |

---

## Provider Endpoints

### LM Studio

- **Discovery:** `http://127.0.0.1:1234/v1` (local) — also accessible via Tailscale on ds9
- **ds9:** `http://127.0.0.1:1234/v1` (local to that machine, separate LM Studio installation)

### Ollama (currently disabled — preserved in comments/fallbacks)

- Default: `http://127.0.0.1:11434/v1`

### OpenRouter (cloud fallback)

- `https://openrouter.ai/api/v1`
- API key via `$OPENROUTER_API_KEY` env var

---

## Installed Models on Discovery (LM Studio)

| Model                        | Source                               | Quant  | Size     | Role                                                         |
| ---------------------------- | ------------------------------------ | ------ | -------- | ------------------------------------------------------------ |
| hermes-qwen3.5-35b-a3b-Q6_K  | DJLougen/hermes-qwen3.5-35b-a3b-GGUF | Q6_K   | ~28.5 GB | **Primary** — Hermes 4 agentic tool-use                      |
| ornith-1.0-35b (Q6_K)        | LM Studio remote pull                | Q6_K   | ~28.5 GB | Secondary/comparison — stays installed, JIT-loaded on demand |
| codestral:22b (Q4_K_M)       | bartowski                            | Q4_K_M | ~12 GB   | General/coder (Ollama tier)                                  |
| deepseek-r1:32b (Q4_K_M)     | bartowski                            | Q4_K_M | ~18 GB   | Reasoning tools                                              |
| qwen3-coder-30b-a3b:q6       | unsloth                              | Q6_K   | ~19 GB   | Ollama coding tier                                           |
| qwen3.6-35b-a3b:opus4.7-128k | —                                    | —      | —        | Instruct distill (Ollama)                                    |
| gemma-4-e4b (Q8_0)           | bartowski                            | Q8_0   | ~27 GB   | General                                                      |
| nomic-embed-text (F16)       | nomic-ai                             | F16    | ~5.3 GB  | Embedding                                                    |

**Memory note:** Hermes 4 (~28.5GB) + Ornith (~28.5GB) = ~57GB of model weights alone on a 64GB machine. They will NOT co-resident simultaneously as steady state. Pin Hermes 4 with idle-timeout=0 (always warm), leave Ornith JIT-load-on-request with normal eviction.

---

## Installed Models on ds9 (LM Studio)

| Model                     | Source    | Quant      | Size    | Role            |
| ------------------------- | --------- | ---------- | ------- | --------------- |
| codestral:22b (Q4_K_M)    | bartowski | Q4_K_M     | ~12 GB  | Coder           |
| deepseek-r1:7b (Q4_K_M)   | bartowski | Q4_K_M     | ~5.3 GB | Reasoning tools |
| gemma-4-e4b (Q8_0)        | bartowski | Q8_0       | ~27 GB  | General         |
| gpt-oss-20b               | —         | —          | —       | General         |
| nomic-embed-text (F16)    | nomic-ai  | F16        | ~5.3 GB | Embedding       |
| qwen2.5-coder:7b (Q4_K_M) | unsloth   | Q4_K_M     | ~4.8 GB | Coder           |
| qwen3:4b (Q4_K_M)         | Qwen      | Q4_K_M     | ~2.6 GB | Instruct/fast   |
| qwen3.5:4b (UD-Q4_K_XL)   | unsloth   | UD-Q4_K_XL | ~2.8 GB | Instruct/fast   |

**Note:** ds9 is a lighter setup — does not currently have Hermes 4 or Ornith loaded. The new model should be downloaded to ds9's LM Studio as well if it will serve as the shared endpoint for tools running on that machine.

---

## Routing Rules

1. **Agentic tasks (multi-step, tool-calling, file editing/infra):** Default to Hermes 4 via LM Studio.
2. **Fast/planning tasks:** Can use smaller models (qwen3:4b, qwen3.5:4b) on Ollama if needed — but only as fallback since Ollama is disabled for now.
3. **Reasoning-heavy tasks:** DeepSeek R1 or Hermes 4 (Hermes 4 handles reasoning well enough; use R1 only when you want a different reasoning style).
4. **Cloud fallback:** When local models are unavailable, OpenRouter is the fallback.

**Rule of thumb:** If a tool's job is agentic, default to LM Studio with Hermes 4. Only reach for Ollama (when re-enabled) or cloud when you have a specific tested reason — and that reason should be documented here.

---

## Change History

| Date       | Change           | Reason                                                          |
| ---------- | ---------------- | --------------------------------------------------------------- |
| 2026-07-16 | Initial creation | Establish model routing policy; add Hermes 4 35B-A3B as primary |
