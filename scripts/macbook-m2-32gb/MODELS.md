# MacBook Pro M2 32GB Models

## Installed Models

| Model                    | Modelfile                 | RAM loaded | Context | Purpose                                   |
| ------------------------ | ------------------------- | ---------- | ------- | ----------------------------------------- |
| `qwen3.5:27b`            | —                         | ~20 GB     | 262K    | Writing, general coding (#1 on IndexNow)  |
| `qwen3-coder-30b-32k:q5` | qwen3-coder-30b-32k.txt   | ~25 GB     | 32K     | Primary coding (32k context)              |
| `qwen3.6-35b-32k:q4`     | qwen3.6-35b-32k.txt       | ~22 GB     | 32K     | Alternative coder (Q4 — memory-efficient) |
| `deepseek-r1:32b`        | —                         | ~21 GB     | 128K    | Deep reasoning — solo only                |
| `deepseek-r1-tools:14b`  | deepseek-r1-tools-14b.txt | ~10 GB     | 131K    | Reasoning + tools                         |
| `deepseek-r1-tools:8b`   | deepseek-r1-tools-8b.txt  | ~5 GB      | 131K    | Reasoning + tools (lighter)               |
| `qwen3-14b:q5`           | qwen3-14b.txt             | ~12 GB     | 40K     | Research                                  |
| `qwen3-4b:q4`            | qwen3-4b.txt              | ~3 GB      | 262K    | Planning                                  |
| `qwen2.5-coder:7b`       | —                         | ~5 GB      | 32K     | Fast code                                 |
| `qwen2.5-coder:1.5b`     | —                         | ~1 GB      | 32K     | Autocomplete                              |
| `nomic-embed-text`       | —                         | ~0.3 GB    | 2K      | Embeddings                                |

## Alias Chain

```
hf.co/bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q4_K_M
  └── qwen3.6-35b-a3b:q4   (HF base)
        └── qwen3.6-35b-32k:q4   (num_ctx 32768 — daily driver alt coder)

hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL
  └── qwen3-coder-30b-a3b:q5   (HF base)
        └── qwen3-coder-30b-32k:q5   (num_ctx 32768 — primary coder)

hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M
  └── qwen3-4b-2507:q4   (HF base)
        └── qwen3-4b:q4  (compat alias used by configs)

mfdoom/deepseek-r1-tool-calling:8b   →  deepseek-r1-tools:8b
mfdoom/deepseek-r1-tool-calling:14b  →  deepseek-r1-tools:14b
dengcao/Qwen3-14B:Q5_K_M             →  qwen3-14b:q5
deepseek-r1:32b                       →  direct pull (~21 GB Q4 distill)
```

## Memory Notes

- Code (25 GB) + think/research (10–12 GB) = ~35 GB — tight, Ollama swap evicts idle model
- Code (25 GB) + write (20 GB) = ~45 GB — swap-intensive, avoid sustained dual load
- `deepseek-r1:32b` is solo-only (~21 GB); nothing else large loads alongside it
- qwen3.6-35b at Q4 (~22 GB) vs Q5 (~28 GB) — Q4 chosen here to leave headroom for concurrent models
- Ollama evicts after 5 min idle

---

## Tool Quick Reference

### Claude Code `~/.claude/config.json`

| Tier             | Model                    | Notes                   |
| ---------------- | ------------------------ | ----------------------- |
| Sonnet (default) | `qwen3-coder-30b-32k:q5` | 32k ctx, ~25 GB         |
| Haiku (fast)     | `qwen3-4b:q4`            | ~3 GB, planning/routing |
| Opus (large)     | `qwen3-coder-30b-32k:q5` | same as sonnet          |

Routes through LiteLLM `:4000`.

### Continue `~/.continue/config.yaml`

| Role                    | Model                    |
| ----------------------- | ------------------------ |
| chat / edit / summarize | `qwen3-coder-30b-32k:q5` |
| chat (alt)              | `qwen3.5:27b`            |
| chat (reasoning)        | `deepseek-r1-tools:14b`  |
| autocomplete (fast)     | `qwen2.5-coder:1.5b`     |
| autocomplete (quality)  | `qwen2.5-coder:7b`       |
| embed                   | `nomic-embed-text`       |
| chat (planning)         | `qwen3-4b:q4`            |

### Cline

Primary model: `qwen3-coder-30b-32k:q5`
Set in sidebar → gear → API Provider: Ollama, Base URL: `http://localhost:11434`

### GitHub Copilot

Chat model: `qwen3-coder-30b-32k:q5` (`coding` alias)
Copilot Chat → Add Models → Ollama → select `qwen3-coder-30b-32k:q5`

### OpenCode `~/.config/opencode/opencode.jsonc`

| Agent      | Model                   | Purpose                            |
| ---------- | ----------------------- | ---------------------------------- |
| `code`     | `qwen3.5:27b`           | Implementation, editing, debugging |
| `think`    | `deepseek-r1-tools:14b` | Reasoning, read-only               |
| `write`    | `qwen3.5:27b`           | Docs, resumes, prose               |
| `research` | `qwen3-14b:q5`          | Discovery, saves to Obsidian       |
| `plan`     | `qwen3-4b:q4`           | Next steps, breakdowns             |

Default model: `qwen3.5:27b` · Small model: `qwen3-4b:q4`

### LiteLLM `~/.config/litellm/config.yaml`

Gemini model aliases (router_settings):
- `gemini-2.5-pro / flash / flash-preview` → `qwen3.5:27b`
- `gemini-2.5-flash-lite` → `qwen3-4b:q4`
- `gemini-3.1-pro-preview` → `qwen3-coder-30b-32k:q5`

### Ollama convenience aliases

| Tag         | Model                    |
| ----------- | ------------------------ |
| `coding`    | `qwen3-coder-30b-32k:q5` |
| `primary`   | `qwen3.5:27b`            |
| `fast`      | `qwen3-4b:q4`            |
| `reasoning` | `deepseek-r1-tools:14b`  |
| `research`  | `qwen3-14b:q5`           |

---

## Install

```shell
bash scripts/install_models.sh   # select option 4 (M2 32GB)
```

Pulls direct models, then builds alias chain from CUSTOM_MODELS_32GB in `models.sh`.
