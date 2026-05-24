# Profile Configuration Schema

Canonical reference for how `models.sh` definitions flow into downstream config files.

When `models.sh` changes, every file below must be updated to stay consistent.

**May 2026 update: LiteLLM proxy removed.** All tools connect to Ollama directly
via `http://localhost:11434/v1` (OpenAI-compatible endpoint). Cloud models via
OpenRouter provider blocks natively in each tool.

---

## Source of Truth: `models.sh`

Every profile has one `models.sh` that defines all model assignments.

### Architecture

```
                ┌──────────────┐
                │   Ollama     │
                │  :11434/v1   │
                └──────┬───────┘
         ┌─────────────┼──────────────┐
    ┌────▼────┐  ┌─────▼─────┐  ┌─────▼─────┐
    │ OpenCode│  │ Continue  │  │ ClaudeCode│  ...all tools
    └─────────┘  └───────────┘  └───────────┘

    OpenRouter ──► tools connect directly (no proxy needed)
```

### Variable Reference

| Variable               | Type        | Format                                   | Used By                                                         |
| ---------------------- | ----------- | ---------------------------------------- | --------------------------------------------------------------- |
| `OPENROUTER_MODELS`    | array       | `org/model`                              | continue, grok, opencode (openrouter provider blocks)            |
| `OLLAMA_MODELS`        | array       | `model:tag`                              | ollama/config, continue, crush, gemini, grok, opencode          |
| `OPENCODE_AGENTS`      | assoc array | key → `model:tag`                        | opencode                                                        |
| `CONTINUE_ROLES`       | assoc array | key → `model:tag`                        | continue                                                        |
| `CLAUDE_CODE`          | assoc array | key → `model:tag`                        | claude/settings.json, ollama/config.json                        |
| `CLINE_MODEL`          | scalar      | `model:tag`                              | cline/settings.jsonc (reference only)                           |
| `CLINE_MODEL_CLOUD`    | scalar      | `model:cloud`                            | cline/settings.jsonc (reference only)                           |
| `ZOOCODE_MODEL`        | scalar      | `model:tag`                              | zoocode/settings.jsonc (reference only)                         |
| `ROOCODE_MODEL_CLOUD`  | scalar      | `model:cloud`                            | roocode/settings.jsonc (reference only)                         |
| `ROOCODE_MODE_*`       | scalar      | `model:tag`                              | roocode/settings.jsonc per-mode config                          |
| `KILOCODE_MODEL`       | scalar      | `model:tag`                              | kilocode/settings.jsonc (reference only)                        |
| `KILOCODE_MODEL_CLOUD` | scalar      | `model:cloud`                            | kilocode/settings.jsonc (reference only)                        |
| `AIDER_MODEL`          | scalar      | `model:tag`                              | aider/aider.conf.yml                                            |
| `AIDER_WEAK_MODEL`     | scalar      | `model:tag`                              | aider/aider.conf.yml                                            |
| `AIDER_EDITOR_MODEL`   | scalar      | `model:tag`                              | aider/aider.conf.yml                                            |
| `ZED_MODEL`            | scalar      | `model:tag`                              | zed/settings.json                                               |
| `CURSOR_MODEL`         | scalar      | `model:tag`                              | cursor/settings.jsonc (reference only)                          |
| `CURSOR_MODEL_CLOUD`   | scalar      | `model:cloud`                            | cursor/settings.jsonc (reference only)                          |

### Naming Convention

All model names in `models.sh` use **plain Ollama format** (`model:tag`).
No more LiteLLM format (hyphens). No more `:latest` appending in configs —
bare names like `qwen3:14b` resolve to defaults natively.

| Target          | Format                                   | Example                             |
| --------------- | ---------------------------------------- | ----------------------------------- |
| Ollama          | `model:tag`                              | `qwen3-coder-30b-a3b:q5`            |
| OpenRouter      | `org/model`                              | `anthropic/claude-sonnet-4-6`       |
| OpenCode prefix | `ollama/model:tag` or `openrouter/org/m` | `ollama/qwen3-coder-30b-a3b:q5`     |

### Rules

1. **Plain Ollama names only** — `OLLAMA_MODELS` entries use standard Ollama format.
2. **No `:latest`** — bare model names resolve to default tags automatically.
3. **All references must resolve** — every model name in every config file must exist in `OLLAMA_MODELS` or `OPENROUTER_MODELS`.
4. **Align comments** — right-side comments in `models.sh` groups must be column-aligned within each section.
5. **Markdown pull commands use standard names** — in `.md` files, use names from ollama.com (e.g., `ollama pull qwen3:14b`).

### Context Window Variants

Create via Ollama Modelfiles with `PARAMETER num_ctx`:

```shell
# Create a 32k context variant of the base model
echo 'FROM qwen3-coder-30b-a3b:q5
PARAMETER num_ctx 32768' > /tmp/Modelfile.32k
ollama create qwen3-coder-30b-a3b:q5-32k -f /tmp/Modelfile.32k
```

These aliases share the same underlying weights, so they don't consume additional disk space.

---

## Downstream Config Files

### 1. `ollama/config.json`

Ollama's own integration config — model lists and aliases for Claude and OpenCode.

```
ollama/config.json:
  integrations:
    claude:
      aliases:                    # from CLAUDE_CODE associative array
        primary: <ollama-model>   # CLAUDE_CODE[primary]
        fast: <ollama-model>      # CLAUDE_CODE[fast]
        reasoning: <ollama-model> # CLAUDE_CODE[reasoning]
        research: <ollama-model>  # CLAUDE_CODE[research] (larger profiles only)
        coding: <ollama-model>    # CLAUDE_CODE[coding] (larger profiles only)
        opus: <ollama-model>      # CLAUDE_CODE[opus]
      models:                      # sorted list of all local Ollama models
        - <ollama-model>
    opencode:
      models:                      # same list as claude.models
        - <ollama-model>
  last_model: <ollama-model>       # last used model
  last_selection: "run"
```

**Gotchas:**
- No `:latest` appending needed — bare names like `qwen3:14b` resolve natively
- No duplicate entries
- Sort alphabetically within each list

### 2. `claude/settings.json`

Claude Code — uses Ollama's integration directly. Since Claude Code v2, you can
point it at Ollama:

```
claude/settings.json:
  env:
    ANTHROPIC_BASE_URL: "http://localhost:11434"
    ANTHROPIC_API_KEY: "ollama"
    ANTHROPIC_DEFAULT_SONNET_MODEL: <ollama-model>   # CLAUDE_CODE[primary]
    ANTHROPIC_DEFAULT_HAIKU_MODEL: <ollama-model>     # CLAUDE_CODE[fast]
    ANTHROPIC_DEFAULT_OPUS_MODEL: <ollama-model>     # CLAUDE_CODE[opus]
  model: <ollama-model>                              # default = primary
  permissions: { ... }
```

Or use the built-in Ollama integration:

```shell
ollama launch claude
```

**Gotchas:**
- Base URL is `:11434` (not `:4000`) — Ollama's port
- API key is `ollama` (any non-empty string works)

### 3. `continue/config.yaml`

Continue.dev config — mix of OpenRouter cloud and Ollama local models.

```yaml
models:
  # Cloud (via OpenRouter)
  - name: <display>
    provider: openai
    apiBase: https://openrouter.ai/api/v1
    apiKey: env.OPENROUTER_API_KEY
    model: <openrouter-model>       # e.g., moonshot/kimi-k2.6
    roles: [chat]

  # Local (via Ollama)
  - name: <display>
    provider: ollama
    apiBase: http://localhost:11434
    model: <ollama-model>           # e.g., qwen3:14b
    roles: [chat, edit, apply, summarize, autocomplete, embed, rerank]
```

**Gotchas:**
- No more `provider: openai` with LiteLLM base URL for chat models
- All local models use `provider: ollama` directly
- Autocomplete models need `requestOptions.timeout: 8000`

### 4. `crush/crush.json`

Crush terminal AI — connects to Ollama's OpenAI-compatible endpoint.

```json
{
  "providers": {
    "ollama": {
      "name": "Ollama (Local)",
      "type": "openai-compat",
      "base_url": "http://localhost:11434/v1",
      "api_key": "ollama",
      "models": [
        { "id": "<ollama-model>", "name": "<display>", ... }
      ]
    }
  }
}
```

**Gotchas:**
- Base URL is `:11434/v1` (Ollama's OpenAI-compatible endpoint)
- API key can be any string (Ollama doesn't validate it)

### 5. `gemini/settings.json`

Google Gemini CLI — connects to Ollama.

```json
{
  "provider": {
    "ollama": {
      "name": "Ollama (Local)",
      "options": {
        "baseURL": "http://localhost:11434/v1",
        "apiKey": "ollama"
      },
      "models": {
        "<ollama-model>": { "name": "<display>" }
      }
    }
  }
}
```

### 6. `grok/grok.json`

Grok CLI — both OpenRouter cloud and Ollama local models.

```json
{
  "provider": {
    "openrouter": {
      "options": { "baseURL": "https://openrouter.ai/api/v1" },
      "models": { "<openrouter-model>": { "name": "<display>" } }
    },
    "ollama": {
      "options": { "baseURL": "http://localhost:11434" },
      "models": { "<ollama-model>": { "name": "<display>" } }
    }
  }
}
```

**Gotchas:**
- Ollama `baseURL` has NO `/v1` suffix (unlike Gemini)

### 7. `groq/local-settings.json`

Groq cloud-only — no local models. Unchanged.

### 8. `opencode/opencode.jsonc`

OpenCode config — both OpenRouter cloud and Ollama local, plus agent assignments.

```jsonc
{
  "provider": {
    "openrouter": {
      "models": { "<openrouter-model>": { "name": "<display>" } }
    },
    "ollama": {
      "models": { "<ollama-model>": { "name": "<display>" } }
    }
  },
  "model": "ollama/<model>",           // OPENCODE_AGENTS[code]
  "small_model": "ollama/<model>",     // OPENCODE_AGENTS[plan]
  "agent": {
    "<role>": {
      "model": "ollama/<model>"         // or "openrouter/<model>"
    }
  }
}
```

**Gotchas:**
- No more `litellm` provider block
- No more `:latest` appending
- Agent `model` values need `ollama/` or `openrouter/` prefix

### 9. `cline/settings.jsonc`

Cline (VS Code extension):

- Provider: OpenAI Compatible
- Base URL: `http://localhost:11434/v1`
- API Key: `ollama`
- Model: plain Ollama name (e.g., `qwen3-coder-30b-a3b:q5`)

### 10. `roocode/settings.jsonc`

Roo Code (VS Code extension). Same setup as Cline — each mode can use different models from the same `:11434/v1` endpoint.

### 11. `kilocode/settings.jsonc`

Kilo Code (VS Code extension). Same as Cline/RooCode — `:11434/v1` endpoint.

### 12. `aider/aider.conf.yml`

Aider CLI — uses Ollama's native chat API.

```yaml
model: ollama_chat/<ollama-model>      # AIDER_MODEL
weak-model: ollama_chat/<ollama-model>  # AIDER_WEAK_MODEL
editor-model: ollama_chat/<ollama-model> # AIDER_EDITOR_MODEL
```

**Gotchas:**
- Use `ollama_chat/<model>` prefix, not `openai/`
- No proxy layer needed

### 13. `zed/settings.json`

Zed editor:

```json
{
  "assistant": {
    "default_model": { "provider": "openai", "model": "<ollama-model>" },
    "version": "2"
  },
  "language_models": {
    "openai": {
      "api_url": "http://localhost:11434/v1",
      "available_models": [ ... ]
    }
  }
}
```

### 14. `cursor/settings.jsonc`

Cursor IDE. Set via Cursor Settings (Cmd+Shift+J) → Models UI:

1. Set OpenAI API Key: `ollama`
2. Enable "Override OpenAI Base URL": `http://localhost:11434/v1`
3. Add custom model names (plain Ollama format)

---

## Update Checklist

When `models.sh` changes, update these files in order:

1. **`models.sh`** — source of truth (already changed)
2. **`ollama/config.json`** — model lists + aliases
3. **`claude/settings.json`** — env vars (point at `:11434`)
4. **`continue/config.yaml`** — model entries + roles (all `provider: ollama`)
5. **`opencode/opencode.jsonc`** — provider models + agent assignments
6. **`gemini/settings.json`** — model dict (point at `:11434/v1`)
7. **`grok/grok.json`** — OpenRouter + Ollama model dicts
8. **`groq/local-settings.json`** — only if Groq model names change
9. **`aider/aider.conf.yml`** — model names (`ollama_chat/` prefix)
10. **`zed/settings.json`** — default_model + available_models list
11. **`cline/settings.jsonc`** — update reference comments
12. **`roocode/settings.jsonc`** — update modeApiConfigs + reference comments
13. **`kilocode/settings.jsonc`** — update reference comments
14. **`cursor/settings.jsonc`** — update reference comments
15. **`crush/crush.json`** — model IDs (point at `:11434/v1`)

---

## Profile-Specific Notes

### macbook-m1-16gb / macmini-m2-16gb (16 GB)

- **Shared model set** — identical files, same memory constraints
- Resident set: qwen3:14b (11GB solo only) OR multi-model: r1-tools-8B + 4B + 1.5B + embed = 9.3GB
- No qwen3.5-27b, codestral:22b — physically impossible (19GB > 16GB)
- No `CLAUDE_CODE[research]` or `CLAUDE_CODE[coding]`
- All tool assignments use `qwen3:14b` as primary

### macbook-m2-32gb (32 GB)

- Resident set: 14B-q5 + r1-tools-8B + 4B + 1.5B + embed = 20.3GB
- qwen3.5-27b:q5 (19GB) for writing — solo only
- codestral:22b (14GB) — on-demand only
- `CLAUDE_CODE[opus]` = `qwen3.5-27b:q5`

### macbook-m5-48gb (48 GB)

- Resident set: coder-30B-q5 + r1-tools-14B + 4B + 1.5B + embed = 36.3GB
- qwen3.5-27b:q5 (19GB) swaps in for writing
- codestral:22b on-demand only
- `CLAUDE_CODE[primary]` = `qwen3-coder-30b-a3b:q5`

### macbook-m5-64gb (64 GB)

- Solo mode: coder-next-80B:q4 (48GB) + 4B + 1.5B + embed
- Multi mode: coder-30B-q6 + r1-tools-32B + 4B + 1.5B + embed = 52.3GB
- Wide model selection for all roles
- `CONTINUE_ROLES[kimi]` for cloud reasoning
- `CLAUDE_CODE[primary]` = `qwen3-coder-next-80b:q4`
