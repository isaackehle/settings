# MacBook Pro M1 — Model Matrix

**Hardware:** M1 · 16 GB unified memory · Q4 stack
**Models last updated:** 2026-04-19

---

## Model Roster

One row per property, one column per model. The alias chain shows how each model is built.

| Model                | Source                                              | Modelfile                | RAM loaded | Context | Capabilities         | Continue: role         | Cline: role | Claude Code: tier | OpenCode: agent       | LiteLLM model_name   | Ollama alias type |
| -------------------- | --------------------------------------------------- | ------------------------ | ---------- | ------- | -------------------- | ---------------------- | ----------- | ----------------- | --------------------- | -------------------- | ----------------- |
| qwen3-4b-2507:q4     | hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M | qwen3-4b-2507.txt        | ~3 GB      | 262K    | base weight          | —                      | —           | —                 | —                     | —                    | HF base           |
| deepseek-r1-tools:8b | mfdoom/deepseek-r1-tool-calling:8b                  | deepseek-r1-tools-8b.txt | ~5 GB      | 131K    | reasoning + tools    | reasoning              | —           | —                 | think                 | deepseek-r1-tools:8b | community         |
| qwen3-4b:q4          | ← qwen3-4b-2507:q4                                  | qwen3-4b.txt             | ~3 GB      | 262K    | planning, fast       | plan                   | —           | haiku             | plan                  | qwen3-4b:q4          | compat            |
| qwen3:14b            | (direct pull)                                       | —                        | ~10 GB     | 32K     | general, coding      | chat, apply            | primary     | sonnet, opus      | code, write, research | qwen3:14b            | direct            |
| deepseek-r1:8b       | (direct pull)                                       | —                        | ~5 GB      | 131K    | reasoning, chat-only | —                      | —           | —                 | —                     | deepseek-r1:8b       | direct            |
| qwen2.5-coder:7b     | (direct pull)                                       | —                        | ~5 GB      | 32K     | fast code            | autocomplete (quality) | —           | —                 | —                     | qwen2.5-coder:7b     | direct            |
| qwen2.5-coder:1.5b   | (direct pull)                                       | —                        | ~1 GB      | 32K     | autocomplete         | autocomplete           | —           | —                 | —                     | qwen2.5-coder:1.5b   | direct            |
| nomic-embed-text     | (direct pull)                                       | —                        | ~0.3 GB    | 2K      | embeddings           | embed                  | —           | —                 | —                     | nomic-embed-text     | direct            |

> **Memory note:** 16 GB is tight. qwen3:14b (~10 GB) + deepseek-r1-tools:8b (~5 GB) = 15 GB — just fits with nothing else running. Avoid loading both simultaneously under sustained workloads. qwen3:14b alone is the safest daily driver.

---

## Alias Chain

```
hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M
  └── qwen3-4b-2507:q4   (HF base)
        └── qwen3-4b:q4  (compat alias used by configs)

mfdoom/deepseek-r1-tool-calling:8b  →  deepseek-r1-tools:8b
```

Build order matters — `install_custom_models` in `install_models.sh` processes CUSTOM_MODELS_16GB top-to-bottom, so HF base aliases are created before derived aliases.

---

## Tool Quick Reference

### Claude Code `~/.claude/config.json`

| Tier             | Model         | Notes                   |
| ---------------- | ------------- | ----------------------- |
| Sonnet (default) | `qwen3:14b`   | ~10 GB, general coding  |
| Haiku (fast)     | `qwen3-4b:q4` | ~3 GB, planning/routing |
| Opus (large)     | `qwen3:14b`   | same as sonnet          |

Routes through LiteLLM `:4000`.

### Continue `~/.continue/config.yaml`

| Role                   | Model                  |
| ---------------------- | ---------------------- |
| chat / edit / apply    | `qwen3:14b`            |
| chat (reasoning)       | `deepseek-r1-tools:8b` |
| autocomplete (fast)    | `qwen2.5-coder:1.5b`   |
| autocomplete (quality) | `qwen2.5-coder:7b`     |
| embed                  | `nomic-embed-text`     |
| chat (planning)        | `qwen3-4b:q4`          |

### Cline

Primary model: `qwen3:14b`
Set in sidebar → gear → API Provider: Ollama, Base URL: `http://localhost:11434`

### GitHub Copilot

Chat model: `qwen3:14b` (`primary` alias)
Copilot Chat → Add Models → Ollama → select `qwen3:14b`

### OpenCode `~/.config/opencode/opencode.jsonc`

| Agent      | Model                  | Purpose                            |
| ---------- | ---------------------- | ---------------------------------- |
| `code`     | `qwen2.5-coder:7b`     | Implementation, editing, debugging |
| `think`    | `deepseek-r1-tools:8b` | Reasoning, read-only               |
| `write`    | `qwen2.5-coder:7b`     | Docs, resumes, prose               |
| `research` | `qwen3:14b`            | Discovery, saves to Obsidian       |
| `plan`     | `qwen3-4b:q4`          | Next steps, breakdowns             |

Default model: `qwen2.5-coder:7b` · Small model: `qwen2.5-coder:1.5b`

### LiteLLM `~/.config/litellm/config.yaml`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3:14b`
- `gemini-2.5-flash-lite` → `qwen3-4b:q4`
- `gemini-3.1-pro-preview` → `qwen3:14b`

### Ollama convenience aliases

| Tag         | Model                  |
| ----------- | ---------------------- |
| `primary`   | `qwen3:14b`            |
| `coding`    | `qwen2.5-coder:7b`     |
| `fast`      | `qwen3-4b:q4`          |
| `reasoning` | `deepseek-r1-tools:8b` |

---

## Install

```shell
bash scripts/install_models.sh   # select option 3 (16GB)
```

Pulls direct models, then builds alias chain from CUSTOM_MODELS_16GB in `models.sh`.
