# Work Stream: oMLX Onboarding — macmini-m2-16gb

Created: 2026-05-28
Scope: macmini-m2-16gb profile, MLX model research, oMLX as Ollama alternative

---

## Overview

This workstream explores replacing Ollama with [oMLX](https://github.com/jundot/omlx) on the macmini-m2-16gb. oMLX is an MLX-native LLM inference server with continuous batching and tiered KV caching (RAM hot + SSD cold), managed from a macOS menu bar. It exposes an OpenAI-compatible API on `:8000` and supports the Anthropic Messages API on `/v1/messages`.

**Why the Mac Mini is the right first target:** At 16 GB, the tiered KV cache provides the most benefit — models that would OOM under Ollama can partially reside on SSD, and context reuse across turns avoids recomputation. On larger machines (48 GB+), Ollama's simplicity likely wins.

---

## Research

### Model Scout: Ollama → MLX Equivalents

Seven agents searched HuggingFace and the web for MLX-format equivalents of every model in the macmini-16gb `models.sh`. Results by model:

#### Primary Coding — `qwen2.5-coder:7b` (~5 GB)

| MLX Model                                      | Size    | Source                                       |
| ---------------------------------------------- | ------- | -------------------------------------------- |
| `mlx-community/Qwen2.5-Coder-7B-Instruct-4bit` | 4.28 GB | `mlx-community`, instruct-tuned, 32K context |
| `mlx-community/Qwen2.5-Coder-7B-Instruct-3bit` | 3.33 GB | Smaller, slightly weaker                     |
| `mlx-community/Qwen2.5-Coder-7B-bf16`          | 15.2 GB | Full precision — too large for 16 GB         |

#### Solo / Heavy Coding — `qwen3:14b` (~11 GB)

| MLX Model                      | Size    | Source                                           |
| ------------------------------ | ------- | ------------------------------------------------ |
| `Qwen/Qwen3-14B-MLX-4bit`      | 7.75 GB | Official Qwen org, 4-bit, 32K native / 128K YaRN |
| `mlx-community/Qwen3-14B-3bit` | 6.46 GB | Even smaller, 3-bit                              |
| `Qwen/Qwen3-14B-MLX-6bit`      | 11.5 GB | Better quality, tight on 16 GB                   |
| `mlx-community/Qwen3-14B-8bit` | 15.7 GB | Too large for solo on 16 GB                      |

#### Reasoning — `deepseek-r1-tools:8b` (~5 GB)

| MLX Model                                         | Size    | Source                      |
| ------------------------------------------------- | ------- | --------------------------- |
| `mlx-community/DeepSeek-R1-Distill-Qwen-7B-4bit`  | 4.28 GB | Standard R1 distill, 4-bit  |
| `mlx-community/DeepSeek-R1-Distill-Qwen-7B-8bit`  | 8.09 GB | Higher quality, larger      |
| `mlx-community/DeepSeek-R1-Distill-Qwen-14B-4bit` | 8.6 GB  | 14B variant, on-demand only |

**Tool calling note:** oMLX supports DeepSeek's `<tool_call>` XML format via mlx-lm's built-in parser. The standard distill handles function calling — no special "tools" fine-tune needed.

#### Planning / Fast — `qwen3:4b` (~5 GB)

| MLX Model                                   | Size    | Source                             |
| ------------------------------------------- | ------- | ---------------------------------- |
| `Qwen/Qwen3-4B-MLX-4bit`                    | 2.14 GB | Official Qwen, smallest 4-bit      |
| `Qwen/Qwen3-4B-MLX-6bit`                    | 3.14 GB | Better quality, unique 6-bit quant |
| `mlx-community/Qwen3-4B-Instruct-2507-5bit` | 2.77 GB | Newer instruct checkpoint          |
| `mlx-community/Qwen3-4B-4bit`               | 2.26 GB | mlx-community variant              |

#### Autocomplete — `qwen2.5-coder:1.5b` (~1 GB)

| MLX Model                                        | Size    | Source                          |
| ------------------------------------------------ | ------- | ------------------------------- |
| `mlx-community/Qwen2.5-Coder-1.5B-Instruct-4bit` | 869 MB  | Native FIM support, 32K context |
| `mlx-community/Qwen2.5-Coder-1.5B-Instruct-8bit` | 1.64 GB | Higher quality                  |

#### Embeddings — `nomic-embed-text` (~0.3 GB)

| MLX Model                                          | Size   | Type      | MTEB  |
| -------------------------------------------------- | ------ | --------- | ----- |
| `mlx-community/nomicai-modernbert-embed-base-8bit` | 160 MB | embedding | 62.62 |
| `mlx-community/nomicai-modernbert-embed-base-4bit` | 90 MB  | embedding | ~62   |
| `mlx-community/bge-m3-mlx-4bit`                    | 321 MB | embedding | ~63   |
| `mlx-community/bge-m3-mlx-fp16`                    | 1.1 GB | embedding | 63.0  |

**Recommendation:** `mlx-community/nomicai-modernbert-embed-base-8bit` — same team (Nomic AI), same `search_query:` / `search_document:` prefix scheme, better MTEB score than nomic-embed-text, and only 160 MB.

#### Code Apply — `codestral:22b` (~14 GB, on-demand)

| MLX Model                               | Size    | Source                                     |
| --------------------------------------- | ------- | ------------------------------------------ |
| `mlx-community/Codestral-22B-v0.1-4bit` | 12.5 GB | Only MLX variant. On-demand only on 16 GB. |

---

## Memory Budget Analysis

**Hardware:** Mac mini M2 16 GB (~10 GB usable after macOS)

### Multi-Mode (primary set, co-resident with SSD tiering)

| Model                                | RAM         | SSD Cache | Role                       |
| ------------------------------------ | ----------- | --------- | -------------------------- |
| `Qwen2.5-Coder-7B-Instruct-4bit`     | 4.28 GB     | —         | Always-loaded primary      |
| `Qwen3-4B-MLX-4bit`                  | 2.14 GB     | —         | Always-loaded planning     |
| `Qwen2.5-Coder-1.5B-Instruct-4bit`   | 0.87 GB     | —         | Always-loaded autocomplete |
| `nomicai-modernbert-embed-base-8bit` | 0.16 GB     | —         | Always-loaded embeddings   |
| `DeepSeek-R1-Distill-Qwen-7B-4bit`   | —           | 4.28 GB   | Swapped in for reasoning   |
| **Total RAM**                        | **7.45 GB** |           | ✓ Fits in ~10 GB budget    |

### Solo Mode (one model, full capacity)

| Model                | RAM     | Notes                              |
| -------------------- | ------- | ---------------------------------- |
| `Qwen3-14B-MLX-4bit` | 7.75 GB | Solo coding, fits with ~2 GB spare |

### On-Demand Only

| Model                     | Size    | When Used                                            |
| ------------------------- | ------- | ---------------------------------------------------- |
| `Codestral-22B-v0.1-4bit` | 12.5 GB | Diff apply — too big to co-reside, swap in as needed |

The tiered KV cache is the difference-maker: with Ollama, loading the 7B reasoning model means evicting the 7B coding model. With oMLX, the reasoning model's KV cache lives on SSD and reloads nearly instantly when needed.

---

## Implementation Plan

### Stage 1 — Model Config

**`models.sh`** — Replace `OLLAMA_MODELS` with `OMLX_MODELS`. Drop `MODEL_CONTEXTS` (oMLX handles context per-request, no alias variants needed), `MODEL_REMOTES` (no `ollama pull`), and `MODEL_QUANTS` (download MLX quant directly via HuggingFace). Update all tool assignment variables to use MLX HuggingFace paths as model names.

### Stage 2 — Tool Configs

10 config files need `:11434` → `:8000` port changes, provider swaps, and new model names:

| File                      | Change                                                                   | Model Count                              |
| ------------------------- | ------------------------------------------------------------------------ | ---------------------------------------- |
| `opencode/opencode.jsonc` | Provider: `ollama` → `omlx` (`@ai-sdk/openai-compatible`), baseURL :8000 | ~7 models (was 17 with context variants) |
| `continue/config.yaml`    | baseURL :8000, `provider: ollama` → `openai` for autocomplete/embed      | ~5 models (was 9)                        |
| `claude/settings.json`    | `ANTHROPIC_BASE_URL` :8000, new model names                              | 3 models                                 |
| `crush/crush.json`        | baseURL :8000                                                            | 3 models                                 |
| `grok/grok.json`          | baseURL :8000                                                            | 2 models                                 |
| `gemini/settings.json`    | baseURL :8000                                                            | 3 models                                 |
| `aider/aider.conf.yml`    | `openai-api-base` :8000                                                  | 2 models                                 |
| `kilocode/kilo.jsonc`     | Provider swap, :8000, collapsed model list                               | ~7 models (was 50+)                      |
| `zed/settings.json`       | `api_url` :8000                                                          | 3 models                                 |
| `cursor/settings.jsonc`   | Update comments                                                          | —                                        |

### Stage 3 — Pipeline Updates

**`2-ai/omlx.sh`** — Already created. Installs via `brew tap jundot/omlx && brew install omlx`, starts via `brew services start omlx`.

**`setup_ai.sh`** changes:

- Source `2-ai/omlx.sh`
- Add `omlx` to `TOOL_GROUPS["infrastructure"]`
- Add `GROUP_SETUP_FUNCS["omlx"]` / `GROUP_VERIFY_FUNCS["omlx"]`
- Update `select_infrastructure()` menu
- Update `deploy_configs()`: skip `ollama/config.json`, write `omlx` models list instead
- Update required-models generation: read `OMLX_MODELS` not `OLLAMA_MODELS`

**`install-models.sh`** — Replace Ollama-specific pipeline (ollama pull, ollama create, context variants, remotes, quants) with HuggingFace download. oMLX has a built-in model downloader in the admin dashboard; CLI equivalent is `huggingface-cli download <model>` or direct `git lfs` clone.

**`config/profile.d/_ollama`** — Rename to `_omlx` or update env vars (oMLX doesn't use `OLLAMA_KEEP_ALIVE`).

### Stage 4 — Removal

- `ollama/config.json` — Remove from profile (oMLX doesn't use this format)
- `prune_models.sh` — Update to scan MLX model directories instead of `ollama list`
- `generate-model-map.sh` — Update to read `OMLX_MODELS`

---

## Files to Touch

| File                                                    | Action                                                             |
| ------------------------------------------------------- | ------------------------------------------------------------------ |
| `2-ai/profiles/macmini-m2-16gb/models.sh`               | Rewrite: OLLAMA_MODELS → OMLX_MODELS, drop CONTEXTS/REMOTES/QUANTS |
| `2-ai/profiles/macmini-m2-16gb/opencode/opencode.jsonc` | Provider swap, :8000, model names                                  |
| `2-ai/profiles/macmini-m2-16gb/continue/config.yaml`    | :8000, provider: ollama → openai                                   |
| `2-ai/profiles/macmini-m2-16gb/claude/settings.json`    | :8000, new model names                                             |
| `2-ai/profiles/macmini-m2-16gb/crush/crush.json`        | :8000, new model names                                             |
| `2-ai/profiles/macmini-m2-16gb/grok/grok.json`          | :8000, new model names                                             |
| `2-ai/profiles/macmini-m2-16gb/gemini/settings.json`    | :8000, new model names                                             |
| `2-ai/profiles/macmini-m2-16gb/aider/aider.conf.yml`    | :8000, new model names                                             |
| `2-ai/profiles/macmini-m2-16gb/kilocode/kilo.jsonc`     | Provider swap, :8000, collapsed model list                         |
| `2-ai/profiles/macmini-m2-16gb/zed/settings.json`       | :8000, new model names                                             |
| `2-ai/profiles/macmini-m2-16gb/cursor/settings.jsonc`   | Update comments                                                    |
| `2-ai/profiles/macmini-m2-16gb/cline/settings.jsonc`    | Update comments                                                    |
| `2-ai/profiles/macmini-m2-16gb/ollama/config.json`      | Remove                                                             |
| `2-ai/profiles/macmini-m2-16gb/model-map-ollama.md`     | Regenerate                                                         |
| `2-ai/profiles/macmini-m2-16gb/PROFILE`                 | Update description                                                 |
| `setup_ai.sh`                                           | Add omlx to groups, setup, verify, deploy                          |
| `2-ai/install-models.sh`                                | Add oMLX model install path                                        |
| `2-ai/TOOLS.md`                                         | Already has oMLX section (from prior commit)                       |
| `config/profile.d/_ollama`                              | Update or create `_omlx` equivalent                                |

---

## Open Questions

1. **Model download approach** — Use oMLX's admin dashboard UI (simpler) or script `huggingface-cli download` for reproducibility? The dashboard is nicer for one-off setups; the CLI is better for the install pipeline.
2. **Embedding model** — `nomicai-modernbert-embed-base-8bit` (160 MB, same-prefix compatibility) vs `bge-m3-mlx-4bit` (321 MB, multilingual, higher MTEB)? Quality vs simplicity tradeoff.
3. **3-bit coding model** — Should the 7B 3-bit variant (3.33 GB) be the primary if it leaves more headroom for the reasoning model? Or stick with 4-bit and let SSD tiering handle it?
4. **Codestral alternative** — At 12.5 GB the MLX Codestral barely loads on 16 GB. Is there a smaller diff-apply model? Qwen3-Coder-Next (80B-A3B) is bigger. Maybe skip codestral and use the 14B Qwen for apply too?
5. **Continue autocomplete** — oMLX serves OpenAI-compatible API, but Continue's autocomplete provider is specifically `provider: ollama`. Does Continue's `provider: openai` work for autocomplete with oMLX, or is the latency too high? Need to test.
6. **Profile.d env vars** — `OLLAMA_KEEP_ALIVE` is meaningless for oMLX. What env vars (if any) should replace it? oMLX uses `OMLX_MODEL_DIR`, `OMLX_PORT`, etc.

---

## Success Criteria

- [ ] `brew services start omlx` runs with zero-config defaults
- [ ] `curl http://localhost:8000/v1/models` lists all downloaded MLX models
- [ ] OpenCode connects to oMLX on :8000 and all 5 agents use correct models
- [ ] Claude Code routes through oMLX (`ANTHROPIC_BASE_URL`) and tool calling works
- [ ] Continue chat + autocomplete + embeddings all work via oMLX
- [ ] KiloCode agent models all resolve correctly
- [ ] No Ollama processes running; no port 11434 in use
- [ ] Memory stays under 10 GB with the multi-mode set loaded
- [ ] oMLX SSD cache stores reasoning model KV blocks, reloads on demand

---

## Future Scope

- **macbook-m1-16gb** — Same 16 GB constraint, same model mapping. Profile is shared with macmini.
- **32 GB profiles** — oMLX is less critical here (RAM is comfortable for Ollama), but tiered KV cache still improves multi-model switching.
- **48 GB / 64 GB profiles** — Lower priority. Ollama's simplicity and ecosystem breadth are the better fit when RAM isn't tight.
