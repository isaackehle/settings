# MacBook Pro M5 Max 64 GB — Model Matrix

**Hardware:** M5 Max · 64 GB unified memory · Q6 stack
**Models last updated:** 2026-04-19

---

## Model Roster

One row per property, one column per model. The alias chain shows how each model is built.

| Model                       | Source                                                     | Modelfile                    | RAM loaded | Context | Thinking | Capabilities           | Continue: role        | Cline: role | Claude Code: tier | OpenCode: agent | LiteLLM model_name      | Ollama alias type |
| --------------------------- | ---------------------------------------------------------- | ---------------------------- | ---------- | ------- | -------- | ---------------------- | --------------------- | ----------- | ----------------- | --------------- | ----------------------- | ----------------- |
| qwen3-coder-30b-a3b:q6      | hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL | qwen3-coder-30b-a3b.txt      | ~26 GB     | 262K    | -        | base weight            | —                     | —           | —                 | —               | —                       | HF base           |
| qwen3.6-35b-a3b:q6          | hf.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q6_K             | qwen3.6-35b-a3b.txt          | ~30 GB     | 262K    | -        | base weight            | —                     | —           | —                 | —               | —                       | HF base           |
| qwen3-4b-2507:q8            | hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL       | qwen3-4b-2507.txt            | ~5 GB      | 262K    | -        | base weight            | —                     | —           | —                 | —               | —                       | HF base           |
| qwen3-coder-30b-32k:q6      | ← qwen3-coder-30b-a3b:q6                                   | qwen3-coder-30b-32k.txt      | ~28 GB     | 32K     | -        | code, tools            | chat, edit, summarize | primary     | sonnet            | code            | qwen3-coder-30b-32k:q6  | derived (ctx)     |
| qwen3-coder-30b-220k:q6     | ← qwen3-coder-30b-a3b:q6                                   | qwen3-coder-30b-220k.txt     | ~42 GB     | 220K    | -        | code, tools, large ctx | —                     | —           | opus              | —               | qwen3-coder-30b-220k:q6 | derived (ctx)     |
| qwen3.6-35b-32k:q6          | ← qwen3.6-35b-a3b:q6                                       | qwen3.6-35b-32k.txt          | ~30 GB     | 32K     | -        | code, tools            | chat, edit, summarize | primary     | sonnet            | code            | qwen3.6-35b-32k:q6      | derived (ctx)     |
| qwen3.6-35b-220k:q6         | ← qwen3.6-35b-a3b:q6                                       | qwen3.6-35b-220k.txt         | ~44 GB     | 220K    | -        | code, tools, large ctx | —                     | —           | opus              | —               | qwen3.6-35b-220k:q6     | derived (ctx)     |
| qwen3-4b:q8                 | ← qwen3-4b-2507:q8                                         | qwen3-4b.txt                 | ~5 GB      | 262K    | -        | planning, fast         | plan                  | —           | haiku             | plan            | qwen3-4b:q8             | compat            |
| qwen3-coder-next-80b:q4_K_M | qwen3-coder-next:q4_K_M                                    | —                            | ~51 GB     | 262K    |          |                        |                       |             |                   |                 |                         |                   |
| qwen3-coder-next-80b:q4     | qwen3-coder-next:q4_K_M                                    | qwen3-coder-next-80b.txt     | ~51 GB     | 262K    |          |                        |                       |             |                   |                 |                         |                   |
| qwen3-coder-next-80b:q4-16k | qwen3-coder-next-80b:q4                                    | qwen3-coder-next-80b-16k.txt | ~51 GB     | 16K     |          |                        |                       |             |                   |                 |                         |                   |
| deepseek-r1-tools:14b       | mfdoom/deepseek-r1-tool-calling:14b                        | deepseek-r1-tools-14b.txt    | ~10 GB     | 131K    | -        | reasoning + tools      | reasoning             | —           | —                 | think           | deepseek-r1-tools:14b   | community         |

> **Memory note:** code + think (~50 GB) is the outer limit — nothing else loads. code + write (~50 GB) same. 220k alias is solo-only (~44 GB alone). 70b is solo-only (43 GB alone). Pair code (28 GB) + research (22 GB) = 50 GB — swap Ollama evicts the idle one automatically after 5 min.

```shell
ollama create qwen3-coder-next-80b:q4 -f modelfiles/qwen3-coder-next-80b.txt
ollama create qwen3-coder-next-80b:q4-16k -f modelfiles/qwen3-coder-next-80b-16k.txt
```

---

## Alias Chain

```
hf.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q6_K
  └── qwen3.6-35b-a3b:q6   (HF base — use for ad-hoc or future derived aliases)
        ├── qwen3.6-35b-32k:q6   (num_ctx 32768 — daily driver)
        └── qwen3.6-35b-220k:q6  (num_ctx 220000 — solo, large context)

hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL
  └── qwen3-coder-30b-a3b:q6   (HF base — use for ad-hoc or future derived aliases)
        ├── qwen3-coder-30b-32k:q6   (num_ctx 32768 — daily driver)
        └── qwen3-coder-30b-220k:q6  (num_ctx 220000 — solo, large context)

hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL
  └── qwen3-4b-2507:q8   (HF base)
        └── qwen3-4b:q8  (compat alias used by configs)

mfdoom/deepseek-r1-tool-calling:14b  →  deepseek-r1-tools:14b
mfdoom/deepseek-r1-tool-calling:32b  →  deepseek-r1-tools:32b
dengcao/Qwen3-14B:Q8_0               →  qwen3-14b:q8
dengcao/Qwen3-32B:Q5_K_M             →  qwen3-32b:q5
```

Build order matters — `install_custom_models` in `install_models.sh` processes CUSTOM_MODELS_64GB top-to-bottom, so HF base aliases are created before derived aliases.

---

## Tool Quick Reference

### Claude Code `~/.claude/config.json`

| Tier             | Model                     | Notes                   |
| ---------------- | ------------------------- | ----------------------- |
| Sonnet (default) | `qwen3-coder-30b-32k:q6`  | 32k ctx, ~28 GB         |
| Haiku (fast)     | `qwen3-4b:q8`             | ~5 GB, planning/routing |
| Opus (large ctx) | `qwen3-coder-30b-220k:q6` | 220k ctx — solo only    |

Routes through LiteLLM `:4000`.

### Continue `~/.continue/config.yaml`

| Role                    | Model                              |
| ----------------------- | ---------------------------------- |
| chat / edit / summarize | `qwen3-coder-30b-32k:q6`           |
| chat / edit / summarize | `qwen3.6-35b-32k:q6`               |
| chat (alt)              | `qwen3.5:27b`                      |
| chat (reasoning)        | `deepseek-r1-tools:14b`            |
| apply / insert          | `codestral:22b-v0.1-q8_0`          |
| autocomplete (fast)     | `qwen2.5-coder:1.5b`               |
| autocomplete (quality)  | `qwen2.5-coder:7b`                 |
| embed                   | `nomic-embed-text`                 |
| rerank                  | `dengcao/Qwen3-Reranker-0.6B:Q8_0` |
| chat (planning)         | `qwen3-4b:q8`                      |
| large (solo)            | `llama3.3:70b`                     |

### Cline

Primary model: `qwen3-coder-30b-32k:q6`
Set in sidebar → gear → API Provider: Ollama, Base URL: `http://localhost:11434`

### GitHub Copilot

Chat model: `qwen3-coder-30b-32k:q6` (`coding` alias)
Copilot Chat → Add Models → Ollama → select `qwen3-coder-30b-32k:q6`

### OpenCode `~/.config/opencode/opencode.jsonc`

| Agent      | Model                    | Purpose                            |
| ---------- | ------------------------ | ---------------------------------- |
| `code`     | `qwen3-coder-30b-32k:q6` | Implementation, editing, debugging |
| `think`    | `deepseek-r1-tools:14b`  | Reasoning, read-only               |
| `write`    | `qwen3.5:27b`            | Docs, resumes, prose               |
| `research` | `qwen3-32b:q5`           | Discovery, saves to Obsidian       |
| `plan`     | `qwen3-4b:q8`            | Next steps, breakdowns             |

Default model: `qwen3.5:27b` · Small model: `qwen3-4b:q8`

### LiteLLM `~/.config/litellm/config.yaml`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3.5:27b`
- `gemini-2.5-flash-lite` → `qwen3-4b:q8`
- `gemini-3.0-pro` → `qwen3-coder-30b-32k:q6`
- `gemini-3.1-pro-preview` → `qwen3.6-35b-32k:q6`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3.5:27b`
- `gemini-2.5-flash-lite` → `qwen3-4b:q8`

### Ollama convenience aliases `~/.ollama/config.json`

| Tag         | Model                    |
| ----------- | ------------------------ |
| `coding`    | `qwen3-coder-30b-32k:q6` |
| `primary`   | `qwen3.5:27b`            |
| `fast`      | `qwen3-4b:q8`            |
| `reasoning` | `deepseek-r1-tools:14b`  |
| `research`  | `qwen3-32b:q5`           |

---

## Install

```shell
bash scripts/install_models.sh   # select option 2 (M5 64GB)
```

Pulls direct models, then builds alias chain from CUSTOM_MODELS_64GB in `models.sh`.

