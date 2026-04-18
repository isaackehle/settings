# MacBook Pro M1 — Model Matrix

**Hardware:** M1 · 16 GB unified memory · Q4 stack

---

## Model Roster

One row per property, one column per model. The alias chain shows how each model is built.

| Property | `qwen3-4b-2507:q4` | `deepseek-r1-tools:8b` | `qwen3-4b-q4` | `qwen3:14b` | `deepseek-r1:8b` | `qwen2.5-coder:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
|---|---|---|---|---|---|---|---|---|
| **Source** | `hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M` | `mfdoom/deepseek-r1-tool-calling:8b` | ← `qwen3-4b-2507:q4` | (direct pull) | (direct pull) | (direct pull) | (direct pull) | (direct pull) |
| **Modelfile params** | — | — | — | — | — | — | — | — |
| **RAM loaded** | ~3 GB | ~5 GB | ~3 GB | ~10 GB | ~5 GB | ~5 GB | ~1 GB | ~0.3 GB |
| **Capabilities** | base weight | reasoning + tools | planning, fast | general, coding | reasoning, chat-only | fast code | autocomplete | embeddings |
| **Continue: role** | — | reasoning | plan | chat, apply | — | autocomplete (quality) | autocomplete | embed |
| **Cline: role** | — | — | — | primary | — | — | — | — |
| **Claude Code: tier** | — | — | haiku | sonnet, opus | — | — | — | — |
| **OpenCode: agent** | — | think | plan | code, write, research | — | — | — | — |
| **LiteLLM model_name** | — | `deepseek-r1-tools:8b` | `qwen3-4b-q4` | `qwen3:14b` | `deepseek-r1:8b` | `qwen2.5-coder:7b` | `qwen2.5-coder:1.5b` | `nomic-embed-text` |
| **Ollama alias type** | HF base | community | compat | direct | direct | direct | direct | direct |

> **Memory note:** 16 GB is tight. qwen3:14b (~10 GB) + deepseek-r1-tools:8b (~5 GB) = 15 GB — just fits with nothing else running. Avoid loading both simultaneously under sustained workloads. qwen3:14b alone is the safest daily driver.

---

## Alias Chain

```
hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M
  └── qwen3-4b-2507:q4   (HF base)
        └── qwen3-4b-q4  (compat alias used by configs)

mfdoom/deepseek-r1-tool-calling:8b  →  deepseek-r1-tools:8b
```

Build order matters — `install_custom_models` in `install_models.sh` processes CUSTOM_MODELS_16GB top-to-bottom, so HF base aliases are created before derived aliases.

---

## Tool Quick Reference

### Claude Code `~/.claude/config.json`

| Tier | Model | Notes |
|------|-------|-------|
| Sonnet (default) | `qwen3:14b` | ~10 GB, general coding |
| Haiku (fast) | `qwen3-4b-q4` | ~3 GB, planning/routing |
| Opus (large) | `qwen3:14b` | same as sonnet |

Routes through LiteLLM `:4000`.

### Continue `~/.continue/config.yaml`

| Role | Model |
|------|-------|
| chat / edit / apply | `qwen3:14b` |
| chat (reasoning) | `deepseek-r1-tools:8b` |
| autocomplete (fast) | `qwen2.5-coder:1.5b` |
| autocomplete (quality) | `qwen2.5-coder:7b` |
| embed | `nomic-embed-text` |
| chat (planning) | `qwen3-4b-q4` |

### Cline

Primary model: `qwen3:14b`
Set in sidebar → gear → API Provider: Ollama, Base URL: `http://localhost:11434`

### OpenCode `~/.config/opencode/opencode.jsonc`

| Agent | Model | Purpose |
|-------|-------|---------|
| `code` | `qwen2.5-coder:7b` | Implementation, editing, debugging |
| `think` | `deepseek-r1-tools:8b` | Reasoning, read-only |
| `write` | `qwen2.5-coder:7b` | Docs, resumes, prose |
| `research` | `qwen3:14b` | Discovery, saves to Obsidian |
| `plan` | `qwen3-4b-q4` | Next steps, breakdowns |

Default model: `qwen2.5-coder:7b` · Small model: `qwen2.5-coder:1.5b`

### LiteLLM `~/.config/litellm/config.yaml`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3:14b`
- `gemini-2.5-flash-lite` → `qwen3-4b-q4`
- `gemini-3.1-pro-preview` → `qwen3:14b`

### Ollama convenience aliases

| Tag | Model |
|-----|-------|
| `primary` | `qwen3:14b` |
| `coding` | `qwen2.5-coder:7b` |
| `fast` | `qwen3-4b-q4` |
| `reasoning` | `deepseek-r1-tools:8b` |

---

## Install

```shell
bash config/install_models.sh   # select option 3 (16GB)
```

Pulls direct models, then builds alias chain from CUSTOM_MODELS_16GB in `models.sh`.
