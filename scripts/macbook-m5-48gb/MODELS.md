# MacBook Pro M5 Max 48 GB — Model Matrix

**Hardware:** M5 Max · 48 GB unified memory · Q5 stack
**Models last updated:** 2026-04-22

---

## Model Roster

One row per property, one column per model. The alias chain shows how each model is built.

| Model                   | Source                                                     | Modelfile                | RAM loaded | Context | Capabilities           | Continue: role        | Cline: role | Claude Code: tier | OpenCode: agent | LiteLLM model_name      | Ollama alias type |
| ----------------------- | ---------------------------------------------------------- | ------------------------ | ---------- | ------- | ---------------------- | --------------------- | ----------- | ----------------- | --------------- | ----------------------- | ----------------- |
| qwen3.6-35b-a3b:q5      | hf.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q5_K_M           | qwen3.6-35b-a3b.txt      | ~25 GB     | 262K    | base weight            | —                     | —           | —                 | —               | —                       | HF base           |
| qwen3.6-35b-32k:q5      | ← qwen3.6-35b-a3b:q5                                       | qwen3.6-35b-32k.txt      | ~25 GB     | 32K     | code, tools            | chat, edit, summarize | primary     | sonnet            | —               | qwen3.6-35b-32k:q5      | derived (ctx)     |
| qwen3.6-35b-220k:q5     | ← qwen3.6-35b-a3b:q5                                       | qwen3.6-35b-220k.txt     | ~38 GB     | 220K    | code, tools, large ctx | —                     | —           | opus              | —               | qwen3.6-35b-220k:q5     | derived (ctx)     |
| qwen3-coder-30b-a3b:q5  | hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL | qwen3-coder-30b-a3b.txt  | ~21 GB     | 262K    | base weight            | —                     | —           | —                 | —               | —                       | HF base           |
| qwen3-coder-30b-32k:q5  | ← qwen3-coder-30b-a3b:q5                                   | qwen3-coder-30b-32k.txt  | ~25 GB     | 32K     | code, tools            | chat, edit, summarize | primary     | sonnet            | —               | qwen3-coder-30b-32k:q5  | derived (ctx)     |
| qwen3-coder-30b-220k:q5 | ← qwen3-coder-30b-a3b:q5                                   | qwen3-coder-30b-220k.txt | ~38 GB     | 220K    | code, tools, large ctx | —                     | —           | opus              | —               | qwen3-coder-30b-220k:q5 | derived (ctx)     |
| qwen3-4b-2507:q4        | hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M        | qwen3-4b-2507.txt        | ~3 GB      | 262K    | base weight            | —                     | —           | —                 | —               | —                       | HF base           |
| qwen3-4b:q4             | ← qwen3-4b-2507:q4                                         | qwen3-4b.txt             | ~3 GB      | 262K    | planning, fast         | chat                  | —           | haiku             | plan            | qwen3-4b:q4             | compat            |
| deepseek-r1-tools:8b    | mfdoom/deepseek-r1-tool-calling:8b                         | deepseek-r1-tools-8b.txt | ~5 GB      | 131K    | reasoning + tools      | chat                  | —           | —                 | think           | deepseek-r1-tools:8b    | community         |
| deepseek-r1:8b          | (direct pull)                                              | —                        | ~5 GB      | 131K    | reasoning, chat-only   | —                     | —           | —                 | —               | deepseek-r1:8b          | direct            |
| qwen3-14b:q5            | dengcao/Qwen3-14B:Q5_K_M                                   | qwen3-14b.txt            | ~12 GB     | 40K     | analysis               | —                     | —           | —                 | —               | qwen3-14b:q5            | community         |
| gemma4:31b              | (direct pull)                                              | —                        | ~22 GB     | 128K    | research, writing      | chat (alt)            | —           | —                 | research        | gemma4:31b              | direct            |
| qwen3.5:27b             | (direct pull)                                              | —                        | ~20 GB     | 262K    | writing, general       | chat                  | —           | —                 | write, code     | qwen3.5:27b             | direct            |
| codestral:22b           | (direct pull)                                              | —                        | ~14 GB     | 32K     | code apply/insert      | apply                 | —           | —                 | —               | codestral:22b           | direct            |
| qwen2.5-coder:7b        | (direct pull)                                              | —                        | ~5 GB      | 32K     | fast code              | autocomplete          | —           | —                 | —               | qwen2.5-coder:7b        | direct            |
| qwen2.5-coder:1.5b      | (direct pull)                                              | —                        | ~1 GB      | 32K     | autocomplete           | autocomplete          | —           | —                 | —               | qwen2.5-coder:1.5b      | direct            |
| nomic-embed-text        | (direct pull)                                              | —                        | ~0.3 GB    | 2K      | embeddings             | embed                 | —           | —                 | —               | nomic-embed-text        | direct            |


> **Memory note:** code + think (~30 GB) fits comfortably. code + gemma4 research (~47 GB) is tight — Ollama swap evicts idle model. 220k alias is solo-only (38 GB alone). Ollama evicts after 5 min idle by default.

---

## Alias Chain

```
hf.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q5_K_M
  └── qwen3.6-35b-a3b:q5   (HF base — use for ad-hoc or future derived aliases)
        ├── qwen3.6-35b-32k:q5   (num_ctx 32768 — daily driver)
        └── qwen3.6-35b-220k:q5  (num_ctx 220000 — solo, large context)

hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL
  └── qwen3-coder-30b-a3b:q5   (HF base — use for ad-hoc or future derived aliases)
        ├── qwen3-coder-30b-32k:q5   (num_ctx 32768 — daily driver)
        └── qwen3-coder-30b-220k:q5  (num_ctx 220000 — solo, large context)

hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M
  └── qwen3-4b-2507:q4   (HF base)
        └── qwen3-4b:q4  (compat alias used by configs)

mfdoom/deepseek-r1-tool-calling:8b  →  deepseek-r1-tools:8b
dengcao/Qwen3-14B:Q5_K_M           →  qwen3-14b:q5
gemma4:31b                          →  direct pull
```

Build order matters — `install_custom_models` in `install_models.sh` processes CUSTOM_MODELS_48GB top-to-bottom, so HF base aliases are created before derived aliases.

---

## Tool Quick Reference

### Claude Code `~/.claude/config.json`

| Tier             | Model                     | Notes                   |
| ---------------- | ------------------------- | ----------------------- |
| Sonnet (default) | `qwen3-coder-30b-32k:q5`  | 32k ctx, ~25 GB         |
| Haiku (fast)     | `qwen3-4b:q4`             | ~3 GB, planning/routing |
| Opus (large ctx) | `qwen3-coder-30b-220k:q5` | 220k ctx — solo only    |

Routes through LiteLLM `:4000`.

### Continue `~/.continue/config.yaml`

| Role                    | Model                              |
| ----------------------- | ---------------------------------- |
| chat / edit / summarize | `qwen3-coder-30b-32k:q5`           |
| chat (alt)              | `qwen3.5:27b`                      |
| chat (reasoning)        | `deepseek-r1-tools:8b`             |
| apply / insert          | `codestral:22b`                    |
| autocomplete (fast)     | `qwen2.5-coder:1.5b`               |
| autocomplete (quality)  | `qwen2.5-coder:7b`                 |
| embed                   | `nomic-embed-text`                 |
| rerank                  | `dengcao/Qwen3-Reranker-0.6B:Q8_0` |
| chat (planning)         | `qwen3-4b:q4`                      |

### Cline

Primary model: `qwen3-coder-30b-32k:q5`
Set in sidebar → gear → API Provider: Ollama, Base URL: `http://localhost:11434`

### GitHub Copilot

Chat model: `qwen3-coder-30b-32k:q5` (`coding` alias)
Copilot Chat → Add Models → Ollama → select `qwen3-coder-30b-32k:q5`

### OpenCode `~/.config/opencode/opencode.jsonc`

| Agent      | Model                  | Purpose                            |
| ---------- | ---------------------- | ---------------------------------- |
| `code`     | `qwen3.5:27b`          | Implementation, editing, debugging |
| `think`    | `deepseek-r1-tools:8b` | Reasoning, read-only               |
| `write`    | `qwen3.5:27b`          | Docs, resumes, prose               |
| `research` | `gemma4:31b`           | Discovery, saves to Obsidian       |
| `plan`     | `qwen3-4b:q4`          | Next steps, breakdowns             |

Default model: `qwen3.5:27b` · Small model: `qwen3-4b:q4`

### LiteLLM `~/.config/litellm/config.yaml`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3.5:27b`
- `gemini-2.5-flash-lite` → `qwen3-4b:q4`
- `gemini-3.1-pro-preview` → `qwen3-coder-30b-32k:q5`

### Ollama convenience aliases `~/.ollama/config.json`

| Tag         | Model                    |
| ----------- | ------------------------ |
| `coding`    | `qwen3-coder-30b-32k:q5` |
| `primary`   | `qwen3.5:27b`            |
| `fast`      | `qwen3-4b:q4`            |
| `reasoning` | `deepseek-r1-tools:8b`   |
| `research`  | `gemma4:31b`             |

---

## Install

```shell
bash scripts/install_models.sh   # select option 1 (M5 48GB)
```

Pulls direct models, then builds alias chain from CUSTOM_MODELS_48GB in `models.sh`.
