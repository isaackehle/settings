# MacBook Pro M5 Max 48 GB — Model Matrix

**Hardware:** M5 Max · 48 GB unified memory · Q5 stack

---

## Model Roster

One row per property, one column per model. The alias chain shows how each model is built.

| Property | `qwen3-coder-30b-a3b:q5` | `qwen3-coder-30b-32k-q5` | `qwen3-coder-30b-220k-q5` | `qwen3-4b-2507:q4` | `qwen3-4b-q4` | `deepseek-r1-tools:8b` | `deepseek-r1:8b` | `qwen3-14b-q5` | `qwen3.5:27b` | `codestral:22b` | `qwen2.5-coder:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Source** | `hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL` | ← `qwen3-coder-30b-a3b:q5` | ← `qwen3-coder-30b-a3b:q5` | `hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M` | ← `qwen3-4b-2507:q4` | `mfdoom/deepseek-r1-tool-calling:8b` | (direct pull) | `dengcao/Qwen3-14B:Q5_K_M` | (direct pull) | (direct pull) | (direct pull) | (direct pull) | (direct pull) |
| **Modelfile params** | — | `num_ctx 32768` | `num_ctx 220000` | — | — | — | — | — | — | — | — | — | — |
| **RAM loaded** | ~21 GB | ~25 GB | ~38 GB | ~3 GB | ~3 GB | ~5 GB | ~5 GB | ~12 GB | ~20 GB | ~14 GB | ~5 GB | ~1 GB | ~0.3 GB |
| **Capabilities** | base weight | code, tools | code, tools, large ctx | base weight | planning, fast | reasoning + tools | reasoning, chat-only | research, analysis | writing, general | code apply/insert | fast code | autocomplete | embeddings |
| **Continue: role** | — | chat, edit, summarize | — | — | chat | chat | — | — | chat | apply | autocomplete | autocomplete | embed |
| **Cline: role** | — | primary | — | — | — | — | — | — | — | — | — | — | — |
| **Claude Code: tier** | — | sonnet | opus | — | haiku | — | — | — | — | — | — | — | — |
| **OpenCode: agent** | — | — | — | — | plan | think | — | research | write, code | — | — | — | — |
| **LiteLLM model_name** | — | `qwen3-coder-30b-32k-q5` | `qwen3-coder-30b-220k-q5` | — | `qwen3-4b-q4` | `deepseek-r1-tools:8b` | `deepseek-r1:8b` | `qwen3-14b-q5` | `qwen3.5:27b` | `codestral:22b` | `qwen2.5-coder:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **Ollama alias type** | HF base | derived (ctx) | derived (ctx) | HF base | compat | community | direct | community | direct | direct | direct | direct | direct |

> **Memory note:** code + think (~30 GB) fits comfortably. code + write pushes ~45 GB — fine, nothing else loads. 220k alias is solo-only (38 GB alone). Ollama evicts after 5 min idle by default.

---

## Alias Chain

```
hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL
  └── qwen3-coder-30b-a3b:q5   (HF base — use for ad-hoc or future derived aliases)
        ├── qwen3-coder-30b-32k-q5   (num_ctx 32768 — daily driver)
        └── qwen3-coder-30b-220k-q5  (num_ctx 220000 — solo, large context)

hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M
  └── qwen3-4b-2507:q4   (HF base)
        └── qwen3-4b-q4  (compat alias used by configs)

mfdoom/deepseek-r1-tool-calling:8b  →  deepseek-r1-tools:8b
dengcao/Qwen3-14B:Q5_K_M           →  qwen3-14b-q5
```

Build order matters — `install_custom_models` in `install_models.sh` processes CUSTOM_MODELS_48GB top-to-bottom, so HF base aliases are created before derived aliases.

---

## Tool Quick Reference

### Claude Code `~/.claude/config.json`

| Tier | Model | Notes |
|------|-------|-------|
| Sonnet (default) | `qwen3-coder-30b-32k-q5` | 32k ctx, ~25 GB |
| Haiku (fast) | `qwen3-4b-q4` | ~3 GB, planning/routing |
| Opus (large ctx) | `qwen3-coder-30b-220k-q5` | 220k ctx — solo only |

Routes through LiteLLM `:4000`.

### Continue `~/.continue/config.yaml`

| Role | Model |
|------|-------|
| chat / edit / summarize | `qwen3-coder-30b-32k-q5` |
| chat (alt) | `qwen3.5:27b` |
| chat (reasoning) | `deepseek-r1-tools:8b` |
| apply / insert | `codestral:22b` |
| autocomplete (fast) | `qwen2.5-coder:1.5b` |
| autocomplete (quality) | `qwen2.5-coder:7b` |
| embed | `nomic-embed-text` |
| rerank | `dengcao/Qwen3-Reranker-0.6B:Q8_0` |
| chat (planning) | `qwen3-4b-q4` |

### Cline

Primary model: `qwen3-coder-30b-32k-q5`
Set in sidebar → gear → API Provider: Ollama, Base URL: `http://localhost:11434`

### OpenCode `~/.config/opencode/opencode.jsonc`

| Agent | Model | Purpose |
|-------|-------|---------|
| `code` | `qwen3.5:27b` | Implementation, editing, debugging |
| `think` | `deepseek-r1-tools:8b` | Reasoning, read-only |
| `write` | `qwen3.5:27b` | Docs, resumes, prose |
| `research` | `qwen3-14b-q5` | Discovery, saves to Obsidian |
| `plan` | `qwen3-4b-q4` | Next steps, breakdowns |

Default model: `qwen3.5:27b` · Small model: `qwen3-4b-q4`

### LiteLLM `~/.config/litellm/config.yaml`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3.5:27b`
- `gemini-2.5-flash-lite` → `qwen3-4b-q4`
- `gemini-3.1-pro-preview` → `qwen3-coder-30b-32k-q5`

### Ollama convenience aliases `~/.ollama/config.json`

| Tag | Model |
|-----|-------|
| `coding` | `qwen3-coder-30b-32k-q5` |
| `primary` | `qwen3.5:27b` |
| `fast` | `qwen3-4b-q4` |
| `reasoning` | `deepseek-r1-tools:8b` |
| `research` | `qwen3-14b-q5` |

---

## Install

```shell
bash config/install_models.sh   # select option 1 (M5 48GB)
```

Pulls direct models, then builds alias chain from CUSTOM_MODELS_48GB in `models.sh`.
