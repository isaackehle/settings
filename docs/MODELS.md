---
tags: [ai, models, reference]
---

# Model Registry

Canonical reference for model naming, decisions, and profile assignments.
This file is the single source of truth for model identity questions.

## Naming Decisions

Decisions about model identity, naming, and which variant to use. When a
decision is superseded, log the date and reason.

| Date       | Model                  | Decision                                                                                                                                                                        | Source                                     |
| ---------- | ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| 2026-05-27 | `deepseek-r1`          | Official DeepSeek reasoning model. No tool-calling. Variants: `8b`, `14b`, `32b`, `70b`, `671b`.                                                                                | ollama.com/library/deepseek-r1             |
| 2026-05-27 | `deepseek-r1-tools`    | Community fine-tune (MFDoom) adding tool-calling. Qwen2-based, not a superset of `deepseek-r1`. Pullable as `MFDoom/deepseek-r1-tool-calling`. Local alias via `MODEL_REMOTES`. | ollama.com/MFDoom/deepseek-r1-tool-calling |
| 2026-05-27 | `deepseek-r1:8b`       | Valid Ollama tag. Official 8B distilled reasoning (no tool-calling).                                                                                                            | ollama.com/library/deepseek-r1             |
| 2026-05-27 | `deepseek-r1-tools:8b` | Valid via `MFDoom/deepseek-r1-tool-calling:8b`. Pulled and aliased by `MODEL_REMOTES`. Use for reasoning+tool-calling on 16/32GB.                                               | ollama.com/MFDoom/deepseek-r1-tool-calling |

## Display Names

Every config file MUST use names from this table. Capability codes go in
parentheses before quant info, comma-separated: `Qwen 3 4B (PLAN)`,
`Qwen3 Coder 30B A3B (CODE, Q5 32K)`.

### Capability Codes

| Code   | Meaning      | Use Case                                |
| ------ | ------------ | --------------------------------------- |
| `CODE` | Coding       | Code generation, refactoring, debugging |
| `REAS` | Reasoning    | Chain-of-thought, analysis, tradeoffs   |
| `TOOL` | Tools        | Function calling / tool use             |
| `WRIT` | Writing      | Prose, docs, resumes                    |
| `PLAN` | Planning     | Fast routing, task breakdown            |
| `FIND` | Research     | Investigation, evidence gathering       |
| `DIFF` | Apply        | Diff insertion, code patching           |
| `FILL` | Autocomplete | Fill-in-the-middle, inline completions  |
| `EMBD` | Embedding    | Semantic search embeddings              |
| `CHAT` | General chat | Multi-purpose conversation              |
| `CLD`  | Cloud        | Remote API model (not local)            |

### Naming Rules

1. **Base model names**: Space before version — `Qwen 3 4B`, `Qwen 3.5 27B`
2. **Product-line names**: No space — `Qwen3 Coder 30B A3B`
3. **Capability codes**: Before quant — `(CODE, Q5 32K)`, `(PLAN)`, `(REAS, TOOL)`
4. **Quant variants**: Uppercase Q + space + uppercase K — `(Q4 64K)`, `(Q8)`
5. **Context-only**: Uppercase K — `(8K)`, `(32K)`, `(128K)`
6. **Cloud**: Use `CLD` code, drop "Cloud" suffix — `Kimi K2.6 (REAS, CLD)`
7. **No role words**: No `(reasoning)`, `(fast)`, `(planning)` — use codes instead
8. **Vendor capitalization**: `K2.6` not `k2.6`

### DeepSeek R1 — Three Distinct Models

There are three different DeepSeek R1 models. The display name `DeepSeek R1` is
shared, with the capability code distinguishing them:

| Model ID                                | Display Name                                   | Notes                        |
| --------------------------------------- | ---------------------------------------------- | ---------------------------- |
| `deepseek-r1:8b`                        | DeepSeek R1 8B (REAS)                          | Official, no tool-calling    |
| `deepseek-r1-tools:8b`                  | DeepSeek R1 8B (REAS, TOOL)                    | Community, with tool-calling |
| `deepseek-r1-tools:32b`                 | DeepSeek R1 32B (REAS, TOOL)                   | Community, with tool-calling |
| `deepseek/deepseek-r1-tool-calling-32b` | DeepSeek R1 Tool Calling 32B (REAS, TOOL, CLD) | OpenRouter cloud version     |

### Local Models (Ollama)

| Model ID                       | Display Name                         |
| ------------------------------ | ------------------------------------ |
| `codestral:22b`                | Codestral 22B (DIFF)                 |
| `codestral:22b-32k`            | Codestral 22B (DIFF, 32K)            |
| `deepseek-r1:8b`               | DeepSeek R1 8B (REAS)                |
| `deepseek-r1-tools:8b`         | DeepSeek R1 8B (REAS, TOOL)          |
| `deepseek-r1-tools:8b-128k`    | DeepSeek R1 8B (REAS, TOOL, 128K)    |
| `deepseek-r1-tools:32b`        | DeepSeek R1 32B (REAS, TOOL)         |
| `deepseek-r1-tools:32b-128k`   | DeepSeek R1 32B (REAS, TOOL, 128K)   |
| `gemma4:31b`                   | Gemma 4 31B (REAS)                   |
| `gemma4:31b-8k`                | Gemma 4 31B (REAS, 8K)               |
| `gemma4:31b-32k`               | Gemma 4 31B (REAS, 32K)              |
| `gemma4:31b-128k`              | Gemma 4 31B (REAS, 128K)             |
| `gemma4:31b-256k`              | Gemma 4 31B (REAS, 256K)             |
| `nomic-embed-text`             | Nomic Embed Text (EMBD)              |
| `qwen2.5-coder:1.5b`           | Qwen 2.5 Coder 1.5B (FILL)           |
| `qwen2.5-coder:7b`             | Qwen 2.5 Coder 7B (FILL)             |
| `qwen2.5-coder:7b-8k`          | Qwen 2.5 Coder 7B (FILL, 8K)         |
| `qwen2.5-coder:7b-32k`         | Qwen 2.5 Coder 7B (FILL, 32K)        |
| `qwen3:4b`                     | Qwen 3 4B (PLAN)                     |
| `qwen3:4b-8k`                  | Qwen 3 4B (PLAN, 8K)                 |
| `qwen3:4b-128k`                | Qwen 3 4B (PLAN, 128K)               |
| `qwen3:14b`                    | Qwen 3 14B (CODE)                    |
| `qwen3:14b-8k`                 | Qwen 3 14B (CODE, 8K)                |
| `qwen3:14b-40k`                | Qwen 3 14B (CODE, 40K)               |
| `qwen3:14b-128k`               | Qwen 3 14B (CODE, 128K)              |
| `qwen3:14b-256k`               | Qwen 3 14B (CODE, 256K)              |
| `qwen3.5-27b:q5`               | Qwen 3.5 27B (WRIT, Q5)              |
| `qwen3.5-27b:q5-8k`            | Qwen 3.5 27B (WRIT, Q5 8K)           |
| `qwen3.5-27b:q5-32k`           | Qwen 3.5 27B (WRIT, Q5 32K)          |
| `qwen3.5-27b:q5-128k`          | Qwen 3.5 27B (WRIT, Q5 128K)         |
| `qwen3.5-27b:q5-256k`          | Qwen 3.5 27B (WRIT, Q5 256K)         |
| `qwen3.5-27b:q8`               | Qwen 3.5 27B (WRIT, Q8)              |
| `qwen3.6-35b:q4`               | Qwen 3.6 35B A3B (CODE, Q4)          |
| `qwen3.6-35b:q4-8k`            | Qwen 3.6 35B A3B (CODE, Q4 8K)       |
| `qwen3.6-35b:q4-128k`          | Qwen 3.6 35B A3B (CODE, Q4 128K)     |
| `qwen3.6-35b:q4-256k`          | Qwen 3.6 35B A3B (CODE, Q4 256K)     |
| `qwen3-coder-30b-a3b:q5`       | Qwen3 Coder 30B A3B (CODE, Q5)       |
| `qwen3-coder-30b-a3b:q5-8k`    | Qwen3 Coder 30B A3B (CODE, Q5 8K)    |
| `qwen3-coder-30b-a3b:q5-32k`   | Qwen3 Coder 30B A3B (CODE, Q5 32K)   |
| `qwen3-coder-30b-a3b:q5-128k`  | Qwen3 Coder 30B A3B (CODE, Q5 128K)  |
| `qwen3-coder-30b-a3b:q6`       | Qwen3 Coder 30B A3B (CODE, Q6)       |
| `qwen3-coder-30b-a3b:q6-8k`    | Qwen3 Coder 30B A3B (CODE, Q6 8K)    |
| `qwen3-coder-30b-a3b:q6-32k`   | Qwen3 Coder 30B A3B (CODE, Q6 32K)   |
| `qwen3-coder-30b-a3b:q6-128k`  | Qwen3 Coder 30B A3B (CODE, Q6 128K)  |
| `qwen3-coder-30b-a3b:q6-256k`  | Qwen3 Coder 30B A3B (CODE, Q6 256K)  |
| `qwen3-coder-next-80b:q4`      | Qwen3 Coder Next 80B (CODE, Q4)      |
| `qwen3-coder-next-80b:q4-16k`  | Qwen3 Coder Next 80B (CODE, Q4 16K)  |
| `qwen3-coder-next-80b:q4-64k`  | Qwen3 Coder Next 80B (CODE, Q4 64K)  |
| `qwen3-coder-next-80b:q4-256k` | Qwen3 Coder Next 80B (CODE, Q4 256K) |

### Cloud Models (OpenRouter)

| Model ID                                | Display Name                                   |
| --------------------------------------- | ---------------------------------------------- |
| `anthropic/claude-haiku-4-5`            | Claude Haiku 4.5 (CLD)                         |
| `anthropic/claude-opus-4-6`             | Claude Opus 4.6 (CLD)                          |
| `anthropic/claude-sonnet-4-6`           | Claude Sonnet 4.6 (CLD)                        |
| `deepseek/deepseek-r1-tool-calling-32b` | DeepSeek R1 Tool Calling 32B (REAS, TOOL, CLD) |
| `google/gemini-2.5-flash`               | Gemini 2.5 Flash (CLD)                         |
| `google/gemini-2.5-pro`                 | Gemini 2.5 Pro (REAS, CLD)                     |
| `mistralai/codestral`                   | Codestral (CODE, CLD)                          |
| `mistralai/mistral-large`               | Mistral Large (CLD)                            |
| `moonshot/kimi-k2.6`                    | Kimi K2.6 (REAS, CLD)                          |
| `openai/gpt-4o`                         | GPT-4o (CLD)                                   |
| `openai/o3`                             | OpenAI o3 (REAS, CLD)                          |
| `perplexity/sonar-pro`                  | Perplexity Sonar Pro (FIND, CLD)               |
| `qwen/qwen3-8b`                         | Qwen3 8B (PLAN, CLD)                           |
| `qwen/qwen3-coder-next-80b`             | Qwen3 Coder Next 80B (CODE, CLD)               |
| `thudm/glm-5.1`                         | GLM 5.1 (CLD)                                  |
| `x-ai/grok-3`                           | Grok 3 (REAS, CLD)                             |
| `x-ai/grok-3-mini`                      | Grok 3 Mini (CLD)                              |

### Ollama Cloud Models (zero-disk manifests)

These models route inference to remote servers through Ollama's cloud integration.
Only a tiny JSON manifest (~400 bytes) is downloaded — no local weights.

| Model ID                     | Display Name                         | Params | Context | Capabilities            |
| ---------------------------- | ------------------------------------ | ------ | ------- | ----------------------- |
| `qwen3.5:397b-cloud`         | Qwen 3.5 Cloud (WRIT, TOOL, CLD)     | 397B   | 262K    | thinking, tools, vision |
| `qwen3-coder:480b-cloud`     | Qwen3 Coder 480B Cloud (CODE, CLD)   | 480B   | 262K    | tools                   |
| `qwen3-coder-next:80b-cloud` | Qwen3 Coder Next Cloud (CODE, CLD)   | 80B    | 262K    | tools                   |
| `gemma4:31b-cloud`           | Gemma 4 31B Cloud (REAS, TOOL, CLD)  | 33B    | 262K    | thinking, tools, vision |
| `gpt-oss:120b-cloud`         | GPT-OSS 120B Cloud (REAS, TOOL, CLD) | 117B   | 131K    | thinking, tools         |

## Model Identity Notes

### DeepSeek R1 Family

- **`deepseek-r1`** — Official model from DeepSeek. Pure reasoning, no
  tool/function calling. Available sizes: `1.5b`, `8b`, `14b`, `32b`, `70b`,
  `671b`. All are Qwen-distilled except `671b` (full MoE).

- **`deepseek-r1-tools`** — Community fine-tune (by `MFDoom`) that adds
  function/tool-calling capability. Based on Qwen2 architecture, not the same
  as `deepseek-r1`. Pullable as `MFDoom/deepseek-r1-tool-calling` with tags
  `8b`, `14b`, `32b`, `70b`, `671b`. The install script creates a local alias
  (e.g., `deepseek-r1-tools:32b`) via `MODEL_REMOTES` so all tool configs
  use the short name.

- **When to use which**: Use `deepseek-r1-tools` for agent contexts (OpenCode,
  Continue, Claude Code) where tool-calling is needed. Use `deepseek-r1` for
  pure reasoning tasks or when RAM is too limited for the 32B tool-calling
  variant.

### Qwen Family

- **`qwen3-coder-next-80b`** — Largest coding model. Q4 quantization for 64GB+
  profiles only.
- **`qwen3-coder-30b-a3b`** — MoE coding model, 3B active parameters. Available
  in `q5` and `q6` quants.
- **`qwen3.6-35b`** — Agentic coding model. `q4` quantization.
- **`qwen3.5-27b`** — General/writing model. Available in `q5` and `q8` quants.
- **`qwen3:14b`** — Solo coding for 16/32GB profiles.
- **`qwen3:4b`** — Planning/routing/fast tasks.
- **`qwen2.5-coder:7b`** — Primary coding for 16GB profiles.
- **`qwen2.5-coder:1.5b`** — FIM autocomplete.

### Other Models

- **`gemma4:31b`** — Google general model.
- **`codestral:22b`** — Mistral code model for diff/apply operations.
- **`nomic-embed-text`** — Embedding model for RAG/semantic search.

## Profile Assignments

### 64GB (macbook-m5-64gb) — Maximum

| Role           | Model                     | Size    |
| -------------- | ------------------------- | ------- |
| Coding (max)   | `qwen3-coder-next-80b:q4` | ~48 GB  |
| Coding         | `qwen3-coder-30b-a3b:q6`  | ~26 GB  |
| Agentic coding | `qwen3.6-35b:q4`          | ~22 GB  |
| Writing        | `qwen3.5-27b:q5`          | ~19 GB  |
| Reasoning      | `deepseek-r1-tools:32b`   | ~20 GB  |
| General        | `gemma4:31b`              | ~20 GB  |
| Planning/fast  | `qwen3:4b`                | ~5 GB   |
| Apply/insert   | `codestral:22b`           | ~23 GB  |
| Autocomplete   | `qwen2.5-coder:7b`        | ~5 GB   |
| Autocomplete   | `qwen2.5-coder:1.5b`      | ~1 GB   |
| Embeddings     | `nomic-embed-text`        | ~0.3 GB |

### 48GB (macbook-m5-48gb) — Powerful

| Role           | Model                    | Size    |
| -------------- | ------------------------ | ------- |
| Coding         | `qwen3-coder-30b-a3b:q5` | ~21 GB  |
| Agentic coding | `qwen3.6-35b:q4`         | ~22 GB  |
| Writing        | `qwen3.5-27b:q5`         | ~19 GB  |
| Reasoning      | `deepseek-r1-tools:32b`  | ~20 GB  |
| General        | `gemma4:31b`             | ~20 GB  |
| Planning/fast  | `qwen3:4b`               | ~5 GB   |
| Apply/insert   | `codestral:22b`          | ~14 GB  |
| Autocomplete   | `qwen2.5-coder:7b`       | ~5 GB   |
| Autocomplete   | `qwen2.5-coder:1.5b`     | ~1 GB   |
| Embeddings     | `nomic-embed-text`       | ~0.3 GB |

### 32GB (macbook-m2-32gb) — Medium

| Role          | Model                    | Size    |
| ------------- | ------------------------ | ------- |
| Coding        | `qwen3-coder-30b-a3b:q5` | ~21 GB  |
| Writing       | `qwen3.5-27b:q5`         | ~19 GB  |
| Reasoning     | `deepseek-r1-tools:8b`   | ~5 GB   |
| Solo coding   | `qwen3:14b`              | ~11 GB  |
| Planning/fast | `qwen3:4b`               | ~5 GB   |
| Apply/insert  | `codestral:22b`          | ~14 GB  |
| Autocomplete  | `qwen2.5-coder:7b`       | ~5 GB   |
| Autocomplete  | `qwen2.5-coder:1.5b`     | ~1 GB   |
| Embeddings    | `nomic-embed-text`       | ~0.3 GB |

### 16GB (macbook-m1-16gb / macmini-m2-16gb) — Lightweight

| Role           | Model                  | Size    |
| -------------- | ---------------------- | ------- |
| Coding/general | `qwen2.5-coder:7b`     | ~5 GB   |
| Reasoning      | `deepseek-r1-tools:8b` | ~5 GB   |
| Solo coding    | `qwen3:14b`            | ~11 GB  |
| Planning/fast  | `qwen3:4b`             | ~5 GB   |
| Apply/insert   | `codestral:22b`        | ~14 GB  |
| Autocomplete   | `qwen2.5-coder:1.5b`   | ~1 GB   |
| Embeddings     | `nomic-embed-text`     | ~0.3 GB |

## Remote Models (MODEL_REMOTES)

Some models are not in the official Ollama library and must be pulled from a
community namespace. The `MODEL_REMOTES` associative array in each profile's
`models.sh` maps local alias names to their pullable remote names.

| Local Alias             | Remote Name (pullable)                | Profiles   |
| ----------------------- | ------------------------------------- | ---------- |
| `deepseek-r1-tools:32b` | `MFDoom/deepseek-r1-tool-calling:32b` | 64GB, 48GB |
| `deepseek-r1-tools:8b`  | `MFDoom/deepseek-r1-tool-calling:8b`  | 32GB, 16GB |

The install script (`ai/runtimes/install-models.sh`) handles this automatically:

1. Pulls the remote model: `ollama pull MFDoom/deepseek-r1-tool-calling:32b`
2. Creates a local alias: `ollama create deepseek-r1-tools:32b -f Modelfile`
3. All tool configs reference the short local alias name

## Context Window Variants

Context variants are auto-created during install via `ollama create` from
Modelfile templates. The base model is pulled first, then variants with
different `num_ctx` values are created. Variants share underlying weights —
zero additional disk space.

Every model used in a tool assignment must have a `MODEL_CONTEXTS` entry in
its profile's `models.sh`. This includes alternative quants listed in
`MODEL_QUANTS` — if `qwen3.5-27b:q8` is used as a write/chat_alt model, it
needs its own context variants, otherwise it runs at Ollama's default 4K
context (too small for writing tasks).

Small models used only for autocomplete (`qwen2.5-coder:1.5b`) and embeddings
(`nomic-embed-text`) intentionally omit context variants — their default 8K/4K
context is sufficient and expanding it wastes KV-cache memory.

| Suffix  | Context Window | Use Case                  |
| ------- | -------------- | ------------------------- |
| (none)  | Default (4k)   | Autocomplete, embeddings  |
| `-8k`   | 8,192          | Short conversations       |
| `-16k`  | 16,384         | Medium context            |
| `-32k`  | 32,768         | Code apply, standard work |
| `-40k`  | 40,960         | Extended context          |
| `-128k` | 131,072        | Large codebases           |
| `-256k` | 262,144        | Maximum context           |

## Quantization Reference

Ollama model tags use specific naming conventions. The shorthand in
`MODEL_QUANTS` values must use the **full pullable tag**, not a suffix.

| Shorthand | Full Ollama Tag    | Model                          |
| --------- | ------------------ | ------------------------------ |
| `:q4`     | `:q4` or `:q4_K_M` | Varies by model                |
| `:q5`     | `:q5` or `:q5_K_M` | Varies by model                |
| `:q6`     | `:q6` or `:q6_K_M` | Rare; check library page       |
| `:q8`     | `:q8_0`            | Most models use `-q8_0` suffix |
| `:q4_K_M` | `:q4_K_M`          | 4-bit K-medium                 |
| `:q8_0`   | `:q8_0`            | Same as q8                     |

### MODEL_QUANTS Tag Format

The `MODEL_QUANTS` associative array maps a base model name to its alternative
quant pull tag plus a description, separated by a colon:

```bash
["qwen3.5-27b"]="qwen3.5:27b-q8_0:29 GB (solo prose only)"
#                ^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^^^^^^^^^
#                full ollama tag     description
```

The install script splits on the first colon to extract the pull tag and passes
it directly to `ollama pull`. Always verify tags exist at
`https://ollama.com/library/<model>/tags` before adding entries.

| Base Model            | Alternative Tag            | Notes                    |
| --------------------- | -------------------------- | ------------------------ |
| `qwen3.5-27b`         | `qwen3.5:27b-q8_0`         | Tag includes size prefix |
| `qwen3-coder-30b-a3b` | `qwen3-coder:30b-a3b-q8_0` | Library name differs     |
| `gemma4:31b`          | _(none)_                   | Base model is Q6, ~20GB  |
| `qwen3.6-35b`         | `qwen3.6:35b-a3b-q8_0`     | MoE, `-a3b` suffix       |
| `qwen2.5-coder:7b`    | `qwen2.5-coder:7b-q8_0`    | Dash separator           |

## May 2026 Refresh — Change Justification

This section documents every model, config, and structural change in the May
2026 workstream and explains why each change was made.

### Primary Coding Model Upgrade: `qwen3:14b` → `qwen3-coder-30b-a3b` / `qwen2.5-coder:7b`

**All profiles** replaced `qwen3:14b` as the primary coding model.

| Profile | Before                 | After                                                | Why                                                                       |
| ------- | ---------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------- |
| 64GB    | `qwen3:14b` (resident) | `qwen3-coder-next-80b:q4` + `qwen3-coder-30b-a3b:q6` | 80B MoE is the flagship coding model; 30B-a3b co-resident for multi-model |
| 48GB    | `qwen3:14b` (resident) | `qwen3-coder-30b-a3b:q5`                             | 30B MoE (3.3B active) fits in 48GB budget alongside writing/reasoning     |
| 32GB    | `qwen3:14b` (resident) | `qwen3-coder-30b-a3b:q5`                             | Same MoE efficiency — only 3.3B active params, ~21GB memory, fits 32GB    |
| 16GB    | `qwen3:14b` (primary)  | `qwen2.5-coder:7b`                                   | 30Bcoder won't fit; 7B is proven for autocomplete+chat in constrained RAM |

**Justification**: Qwen3-Coder-30B-A3B is a Mixture-of-Experts model with 30B
total parameters but only 3.3B active per token ([Qwen3-Coder blog](https://qwenlm.github.io/blog/qwen3-coder/), [Ollama library](https://ollama.com/library/qwen3-coder)). This delivers near-32B-dense coding quality at MoE inference cost, making it the most efficient coding model per GB of RAM. Key advantages over `qwen3:14b`:

- **Agentic capabilities**: Trained with long-horizon reinforcement learning on SWE-Bench, supporting multi-turn tool use ([source](https://qwenlm.github.io/blog/qwen3-coder/))
- **256K native context** (vs 40K for `qwen3:14b`): enables repository-scale understanding
- **70% code ratio pretraining** on 7.5T tokens — far more code-specialized than general `qwen3:14b`
- **Execution-driven RL**: significantly boosts code execution success rates

On 16GB machines, `qwen2.5-coder:7b` at ~5GB is the only coding model that
leaves enough RAM for reasoning (`r1-tools:8b` at 5GB) and planning (`qwen3:4b`
at 5GB) to coexist. The 7B size is verified competitive with GPT-4o on code
repair (Aider benchmark: 73.7) and code generation ([Ollama](https://ollama.com/library/qwen2.5-coder)).

### Reasoning Model Upgrade: `deepseek-r1-tools:14b` → `deepseek-r1-tools:32b`

| Profile | Before                  | After                   | Why                                            |
| ------- | ----------------------- | ----------------------- | ---------------------------------------------- |
| 64GB    | (none)                  | `deepseek-r1-tools:32b` | New dedicated reasoning slot with 20GB budget  |
| 48GB    | `deepseek-r1-tools:14b` | `deepseek-r1-tools:32b` | 48GB budget supports 32B swap-in for reasoning |
| 32GB    | (same)                  | `deepseek-r1-tools:8b`  | Unchanged — 32B won't fit alongside 30Bcoder   |
| 16GB    | (same)                  | `deepseek-r1-tools:8b`  | Unchanged — 8B is the ceiling for 16GB         |

**Justification**: The 14B variant was a compromise — too small for complex
multi-step reasoning chains. The 32B variant (Qwen2-based, ~20GB Q4_K_M) provides
significantly better chain-of-thought accuracy and tool-calling reliability. On
48GB machines, unloading the 30Bcoder and swapping in 32B reasoning leaves
26.3GB for planning+autocomplete+embeddings ([MFDoom/deepseek-r1-tool-calling](https://ollama.com/MFDoom/deepseek-r1-tool-calling)). The 8B variant remains on 16/32GB profiles where 32B physically cannot coexist.

### Research Agent: `qwen3:14b` → `qwen3-coder-30b-a3b:q5`

| Profile | Before      | After                    |
| ------- | ----------- | ------------------------ |
| 48GB    | `qwen3:14b` | `qwen3-coder-30b-a3b:q5` |
| 32GB    | `qwen3:14b` | `qwen3-coder-30b-a3b:q5` |
| 16GB    | `qwen3:14b` | `qwen2.5-coder:7b`       |

**Justification**: Research agents need strong code understanding for codebase
investigation. The coding-specialized 30B MoE model is strictly better than the
general `qwen3:14b` at reading code, searching repositories, and producing
structured technical findings. On 16GB, `qwen2.5-coder:7b` serves the same role
within memory constraints.

### New Addition: `qwen3.6-35b:q4` — Agentic Architect

| Profile | Role                                              | Why                                                              |
| ------- | ------------------------------------------------- | ---------------------------------------------------------------- |
| 64GB    | `opus` in Claude Code, architect mode in Zoo Code | 35B MoE with thinking preservation across turns                  |
| 48GB    | `opus` in Claude Code                             | Swap-in for deep architect tasks (22GB, fits with 4B+1.5B+embed) |

**Justification**: `qwen3.6-35b` adds thinking/preservation across turns —
critical for architect-mode agents that need to maintain reasoning state over
multi-step planning. Not available on 32GB or below (35B even at Q4 is 22GB,
leaving no room for co-resident models).

### Default Model: `qwen3.2-coder:7b` → `qwen3.5:4b`

**File**: `ai/profiles/default/llm/default_model.txt`

**Justification**: `qwen3.5:4b` replaces the obsolete `qwen3.2-coder:7b` as
the lightweight default. Qwen 3.5 offers 201-language support, native
function calling, and 256K context at just 3.4GB ([Ollama](https://ollama.com/library/qwen3.5)). It's suitable as a routing/planning model that can also handle lightweight chat tasks.

### Context Window Variant Changes

| Model                    | Before        | After                                            | Why                                                                                         |
| ------------------------ | ------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `qwen3:14b`              | `40k`         | `8k 40k 128k 256k`                               | Qwen3 supports 256K context — exposing all variants allows right-sizing for task complexity |
| `qwen3-coder-30b-a3b:q5` | (new)         | `8k 32k 128k` (32GB) / `8k 32k 128k 256k` (64GB) | 256K reserved for 64GB only; 32GB uses conservative max                                     |
| `deepseek-r1-tools:14b`  | `128k`        | removed (14B dropped)                            | Model removed from lineup                                                                   |
| `deepseek-r1-tools:32b`  | (new)         | `128k`                                           | DeepSeek R1 Tools has native 128K context                                                   |
| `deepseek-r1-tools:8b`   | `128k`        | `128k` (unchanged)                               | N/A                                                                                         |
| `codestral:22b`          | (not in 16GB) | `32k` (added to 16GB)                            | Added to 16GB profiles for diff/apply support                                               |

**Justification**: Creating multiple context variants (8k, 32k, 128k, 256k)
via `ollama create` Modelfiles is zero-cost — they share underlying weights.
Smaller contexts reduce KV-cache memory, allowing more models to coexist in RAM
simultaneously. The 8K variant is ideal for autocomplete; 128K+ for
repository-scale code understanding.

### Aliasing: `MODEL_REMOTES` for Community Models

All profiles now include a `MODEL_REMOTES` associative array mapping local
alias names to their remote pull URLs:

```bash
declare -A MODEL_REMOTES=(
    ["deepseek-r1-tools:32b"]="MFDoom/deepseek-r1-tool-calling:32b"
    ["deepseek-r1-tools:8b"]="MFDoom/deepseek-r1-tool-calling:8b"
)
```

**Justification**: `deepseek-r1-tools` is not in the official Ollama library —
it must be pulled from `MFDoom/deepseek-r1-tool-calling` on Ollama. The
`install-models.sh` script now handles this automatically:

1. Pulls the remote model: `ollama pull MFDoom/deepseek-r1-tool-calling:32b`
2. Creates a local alias: `ollama create deepseek-r1-tools:32b -f Modelfile`
3. All tool configs reference the short local alias name

This ensures all config files (opencode.jsonc, continue/config.yaml,
ollama/config.json, etc.) use `deepseek-r1-tools:32b` rather than the
unwieldy `MFDoom/deepseek-r1-tool-calling:32b`.

### Tool Assignment Changes

#### OpenCode `think` agent: `deepseek-r1-tools:14b` → `deepseek-r1-tools:32b`

Reasoning quality scales with parameter count. The 32B variant produces
measurably better chain-of-thought reasoning for tradeoff analysis and debug
strategy. Available on 48GB+ profiles.

#### OpenCode `research` agent: `qwen3:14b` → `qwen3-coder-30b-a3b:q5`

Code research requires strong code understanding. The 30B MoE model was trained
with 70% code ratio and execution-driven RL — strictly superior at reading and
searching codebases compared to the general `qwen3:14b`.

#### Claude Code `opus`: `qwen3.5-27b:q5` → `qwen3.6-35b:q4` (48GB+ only)

The `opus` slot represents the "deep thinker" for code review and architect
tasks. `qwen3.6-35b` preserves thinking across turns, making it more effective
for multi-step agent workflows. 32GB and below retain `qwen3.5-27b:q5` since
`qwen3.6-35b` won't fit.

#### 16GB/32GB Claude Code: `reasoning` slot retained

The `deepseek-r1-tools:8b` reasoning assignment is kept on 16GB and 32GB
profiles. On 16GB, it runs as a swap-in model — when reasoning is needed, the
coding model is unloaded first (~5GB), the reasoning model loads (~5GB), and the
coding model reloads after. This avoids concurrent memory pressure while still
providing local reasoning capability without cloud reliance.

#### Continue `chat_alt`: `codestral:22b` → `qwen3.5-27b:q5` (32GB profile)

Codestral is specialized for FIM/apply, not chat. `qwen3.5-27b:q5` is a
general-purpose model with 201-language support — far better for conversational
chat alternatives.

### Structural Changes

#### Fancy section dividers removed (`╧╧╧╧`)

Replaced Unicode box-drawing section dividers with standard `# ======` comment
headers. Consistent with the rest of the codebase and better for diff
readability.

#### Typo fix: `OLlama` → `Ollama`

Direct usage comment corrected in all profiles.

#### `qwen3:14b` duplicate entry removed (32GB profile)

The 32GB profile previously listed `qwen3:14b` twice — once at Q5 (11GB,
resident) and once at Q8 (16GB, on-demand). Removed the Q8 duplicate since
`MODEL_QUANTS` handles alternative quantization separately.

#### Size estimate corrections

- `qwen3:4b` comment changed from `~3 GB` to `~5 GB` across all profiles — the
  Q4_K_M quantization with KV-cache overhead is closer to 5GB in practice
- Memory budget calculations updated to reflect accurate co-residency figures

#### `install-models.sh`: `install_remote_models()` function added

New function automates the pull-and-alias workflow for community models. Called
during model installation (steps 1 and 3) to ensure `deepseek-r1-tools` aliases
exist before context variants are created.

#### `test-models.sh`: complete rewrite

Replaced the static cloud-model catalog with a dynamic smoke test that:

- Checks each model is installed (`ollama list`)
- Sends a simple prompt and verifies a response is received
- Defaults to `OLLAMA_SMOKE_MODELS` from `~/.env.local`, falling back to the
  May 2026 model lineup
- Exits with code 1 if any installed model fails to respond

#### `helpers.sh`: model suggestions updated

Changed the "no models installed" fallback suggestions from legacy models
(`llama3.2`, `mistral-nemo`, `phi4`) to the current May 2026 lineup:
`qwen3.5:4b`, `qwen2.5-coder:1.5b`, `codestral:22b`, `qwen3-coder-30b-a3b:q5`.

### Continue Config Naming: `name` Must Match `model`

When models are upgraded (e.g., `qwen3:14b` → `qwen3-coder-30b-a3b:q5`), the
human-readable `name` field in `continue/config.yaml` must also be updated.
Stale names like `'Qwen3 14B'` pointing at `qwen3-coder-30b-a3b:q5` cause
confusion. Rule: **always update `name` when `model` changes**.

### Every Role Filled on Every Profile

No tool assignment may omit a role that exists on the 64GB profile. On
lower-memory machines, the same role is filled by the best-available model
within RAM constraints — it is never left empty. For example:

- 16GB `CLAUDE_CODE[reasoning]` = `deepseek-r1-tools:8b` (same role, smaller
  model)
- 16GB `OPENCODE_AGENTS[think]` = `deepseek-r1-tools:8b` (swap-in)
- 32GB `CONTINUE_ROLES[apply]` = `codestral:22b` (on-demand, same as 64GB)

Cloud models (e.g., `kimi-k2.6`) are not roles in `CONTINUE_ROLES` — they are
separate entries in `continue/config.yaml` with `roles: [chat]`. The
`CONTINUE_ROLES` dict only maps local-Ollama roles (`chat`, `chat_alt`,
`apply`, `autocomplete`, `autocomplete_heavy`, `embed`).

### 2026-05-29: Model Naming Standardization

All config files updated to use Ollama's colon-format model names instead of
dash-format. This aligns with `models.sh` which is the single source of truth.

| Old Format (dash)            | New Format (colon)           |
| ---------------------------- | ---------------------------- |
| `qwen3-14b-q5-40k`           | `qwen3:14b-40k`              |
| `qwen3-4b-q8-256k`           | `qwen3:4b-128k`              |
| `qwen3.5-27b-q5-256k`        | `qwen3.5-27b:q5-256k`        |
| `qwen3-coder-30b-q6-32k`     | `qwen3-coder-30b-a3b:q5-32k` |
| `qwen3-coder-next-80b-q4`    | `qwen3-coder-next-80b:q4`    |
| `deepseek-r1-tools-32b-128k` | `deepseek-r1-tools:32b-128k` |

**Key changes:**

- `qwen3.5-27b` variants use colon before quant: `qwen3.5-27b:q5`
- `qwen3-coder-30b-a3b` uses colon: `qwen3-coder-30b-a3b:q5`
- `qwen3-coder-next-80b` uses colon: `qwen3-coder-next-80b:q4`
- Context variants use dash: `qwen3.5-27b:q5-256k`

### 2026-05-29: 16GB Profile Model Constraints

`qwen3.5-27b` (~19GB at Q5) cannot fit in 16GB machines. Replaced with
`qwen3:4b` for writing/planning roles on 16GB profiles.

| Role      | 16GB Profile Model     | Reason                                       |
| --------- | ---------------------- | -------------------------------------------- |
| Writing   | `qwen3:4b`             | `qwen3.5-27b` requires ~19GB, exceeds budget |
| Planning  | `qwen3:4b`             | Same model, dual-purpose                     |
| Coding    | `qwen2.5-coder:7b`     | Primary; `qwen3:14b` available as swap-in    |
| Reasoning | `deepseek-r1-tools:8b` | 8B variant fits; 32B requires swap-out       |

### 2026-05-29: Removed Redundant Models

- `deepseek-r1-tools:14b` removed from all profiles (not in models.sh)
- `gemma4-26b` removed (31B variant is the correct model)
- `llama3.3-70b` removed (not used, too large)
- `qwen3-32b` removed (30B MoE is preferred for coding)
