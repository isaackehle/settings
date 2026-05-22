# Profile Configuration Schema

Canonical reference for how `models.sh` definitions flow into every downstream config file.

When `models.sh` changes, every file below must be updated to stay consistent.

---

## Source of Truth: `models.sh`

Every profile has one `models.sh` that defines all model assignments.

### Variable Reference

| Variable               | Type        | Format                                                    | Used By                                                         |
| ---------------------- | ----------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| `OPENROUTER_MODELS`    | array       | `org/model:cloud`                                         | continue, grok, litellm, opencode                               |
| `OLLAMA_MODELS`        | array       | `model:quant-context` or `hf/source\|alias:quant-context` | ollama/config, continue, crush, gemini, grok, litellm, opencode |
| `OPENCODE_AGENTS`      | assoc array | key → `model:quant-context`                               | opencode                                                        |
| `CONTINUE_ROLES`       | assoc array | key → `model:quant-context`                               | continue                                                        |
| `CLAUDE_CODE`          | assoc array | key → `model:quant-context`                               | claude/settings.json, ollama/config.json                        |
| `CLINE_MODEL`          | scalar      | `model:quant-context`                                     | cline/settings.jsonc (reference only)                           |
| `CLINE_MODEL_CLOUD`    | scalar      | `model:cloud`                                             | cline/settings.jsonc (reference only)                           |
| `ROOCODE_MODEL`        | scalar      | `model:quant-context`                                     | roocode/settings.jsonc (reference only)                         |
| `ROOCODE_MODEL_CLOUD`  | scalar      | `model:cloud`                                             | roocode/settings.jsonc (reference only)                         |
| `ROOCODE_MODE_*`       | scalar      | `model:quant-context`                                     | roocode/settings.jsonc per-mode config                          |
| `KILOCODE_MODEL`       | scalar      | `model:quant-context`                                     | kilocode/settings.jsonc (reference only)                        |
| `KILOCODE_MODEL_CLOUD` | scalar      | `model:cloud`                                             | kilocode/settings.jsonc (reference only)                        |
| `AIDER_MODEL`          | scalar      | `model:quant-context`                                     | aider/aider.conf.yml                                            |
| `AIDER_WEAK_MODEL`     | scalar      | `model:quant-context`                                     | aider/aider.conf.yml                                            |
| `AIDER_EDITOR_MODEL`   | scalar      | `model:quant-context`                                     | aider/aider.conf.yml                                            |
| `ZED_MODEL`            | scalar      | `model:quant-context`                                     | zed/settings.json                                               |
| `CURSOR_MODEL`         | scalar      | `model:quant-context`                                     | cursor/settings.jsonc (reference only)                          |
| `CURSOR_MODEL_CLOUD`   | scalar      | `model:cloud`                                             | cursor/settings.jsonc (reference only)                          |

### Naming Convention

| Target          | Format                                   | Example                             | Transform from Ollama |
| --------------- | ---------------------------------------- | ----------------------------------- | --------------------- |
| Ollama direct   | `model:quant-context`                    | `qwen3-coder-30b-a3b:q5-32k`        | as-is                 |
| LiteLLM         | `model-quant-context`                    | `qwen3-coder-30b-q5-32k`            | replace `:` → `-`     |
| OpenRouter      | `org/model`                              | `anthropic/claude-sonnet-4-6`       | strip `:cloud` suffix |
| OpenCode prefix | `ollama/model` or `openrouter/org/model` | `ollama/qwen3-coder-30b-a3b:q5-32k` | prepend provider      |

### Rules

1. **No `:latest` in `models.sh`** — `OLLAMA_MODELS` entries must never end in `:latest`. Use bare name (e.g., `llama3.2` not `llama3.2:latest`).
2. **Append `:latest` in config files** — Ollama automatically appends `:latest` to models without a custom tag. When referencing Ollama models in downstream config files (ollama/config.json, opencode/opencode.jsonc, continue/config.yaml, etc.), append `:latest` to bare model names (e.g., `llama3.2:latest`, `gpt-oss:latest`, `nomic-embed-text:latest`).
3. **All references must resolve** — every model name in every config file must exist in `OLLAMA_MODELS` or `OPENROUTER_MODELS`.
4. **Align comments** — right-side comments in `models.sh` groups must be column-aligned within each section.
5. **Markdown pull commands use standard names** — in `.md` files, when suggesting models to pull, use standard names from ollama.com (e.g., `ollama pull llama3.2`), not custom aliases (e.g., not `ollama pull qwen3.5-27b:q5-256k`).

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
        - <ollama-model>           # Ollama format (with :latest for bare names)
    opencode:
      models:                      # same list as claude.models
        - <ollama-model>
  last_model: <ollama-model>       # last used model
  last_selection: "run"
```

**Source mapping:**

| Field                          | Source                                    | Format        |
| ------------------------------ | ----------------------------------------- | ------------- |
| `integrations.claude.aliases`  | `CLAUDE_CODE` associative array           | Ollama format |
| `integrations.claude.models`   | `OLLAMA_MODELS` (local only, no `:cloud`) | Ollama format |
| `integrations.opencode.models` | same as `claude.models`                   | Ollama format |

**`:latest` transform for bare names:**

| `models.sh` (bare)    | `config.json` (with `:latest`)             |
| --------------------- | ------------------------------------------ |
| `llama3.2`            | `llama3.2:latest`                          |
| `gpt-oss`             | `gpt-oss:latest`                           |
| `nomic-embed-text`    | `nomic-embed-text:latest`                  |
| `deepseek-r1:8b`      | `deepseek-r1:8b` (has tag, unchanged)      |
| `qwen3.5-27b:q5-256k` | `qwen3.5-27b:q5-256k` (has tag, unchanged) |

**Gotchas:**

- Remove `:cloud` entries from the models list (cloud models aren't local Ollama models)
- Append `:latest` to bare model names (no custom tag) — Ollama does this automatically
- No duplicate entries (e.g., `gpt-oss` appears twice in some profiles)
- Sort alphabetically within each list

---

### 2. `claude/settings.json`

Claude Code's settings — routes through LiteLLM proxy.

```
claude/settings.json:
  env:
    ANTHROPIC_BASE_URL: "http://localhost:4000"
    ANTHROPIC_API_KEY: "sk-local"
    ANTHROPIC_DEFAULT_SONNET_MODEL: <litellm-model>   # from CLAUDE_CODE[primary]
    ANTHROPIC_DEFAULT_HAIKU_MODEL: <litellm-model>     # from CLAUDE_CODE[fast]
    ANTHROPIC_DEFAULT_OPUS_MODEL: <litellm-model>     # from CLAUDE_CODE[opus]
  model: <litellm-model>                              # default = primary
  permissions: { ... }
```

**Source mapping:**

| Field                            | Source                 | Transform                    |
| -------------------------------- | ---------------------- | ---------------------------- |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `CLAUDE_CODE[primary]` | Ollama → LiteLLM (`:` → `-`) |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL`  | `CLAUDE_CODE[fast]`    | Ollama → LiteLLM (`:` → `-`) |
| `ANTHROPIC_DEFAULT_OPUS_MODEL`   | `CLAUDE_CODE[opus]`    | Ollama → LiteLLM (`:` → `-`) |
| `model`                          | same as primary        | LiteLLM format               |

**`CLAUDE_CODE` key → Claude Code env var mapping:**

| `CLAUDE_CODE` key | Claude Code env var              | Purpose          |
| ----------------- | -------------------------------- | ---------------- |
| `primary`         | `ANTHROPIC_DEFAULT_SONNET_MODEL` | default coding   |
| `fast`            | `ANTHROPIC_DEFAULT_HAIKU_MODEL`  | planning/routing |
| `opus`            | `ANTHROPIC_DEFAULT_OPUS_MODEL`   | large context    |
| `reasoning`       | (ollama/config.json alias only)  | reasoning/tools  |
| `research`        | (ollama/config.json alias only)  | research         |
| `coding`          | (ollama/config.json alias only)  | coding alt       |

**Gotchas:**

- Claude Code talks to LiteLLM proxy, so all model names must be in **LiteLLM format** (dashes, not colons)
- Every model referenced here must have a matching `model_name` entry in `litellm/litellm.yaml`
- `CLAUDE_CODE[opus]` may not exist on 16GB profiles (no model large enough for solo use)

---

### 3. `continue/config.yaml`

Continue.dev config — mix of OpenRouter cloud and Ollama local models.

```
continue/config.yaml:
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
      model: <ollama-model>           # e.g., qwen3-coder-30b-a3b:q5-32k
      roles: [chat, edit, apply, summarize, autocomplete, embed, rerank]
```

**Source mapping:**

| Field         | Source                    | Format                             |
| ------------- | ------------------------- | ---------------------------------- |
| Cloud `model` | `OPENROUTER_MODELS`       | OpenRouter format (strip `:cloud`) |
| Local `model` | `CONTINUE_ROLES` + extras | Ollama format                      |
| `roles`       | `CONTINUE_ROLES` keys     | mapped to Continue role names      |

**Role mapping from `CONTINUE_ROLES`:**

| CONTINUE_ROLES key   | Continue role(s)      | Notes                       |
| -------------------- | --------------------- | --------------------------- |
| `chat`               | chat, edit, summarize | primary model               |
| `chat_alt`           | chat                  | manual switch               |
| `apply`              | apply                 | code apply/insert           |
| `autocomplete`       | autocomplete          | default completions         |
| `autocomplete_heavy` | autocomplete          | quality completions         |
| `embed`              | embed                 | semantic search             |
| `kimi`               | chat                  | cloud reasoning (64GB only) |

**Gotchas:**

- Cloud models use `provider: openai` with OpenRouter base URL (direct, not proxied)
- Local chat/edit/apply/summarize models use `provider: openai` with LiteLLM base URL (`http://localhost:4000/v1`, `apiKey: sk-local`)
- Autocomplete, embed, and rerank models stay on `provider: ollama` direct — latency-critical or special endpoints
- Autocomplete models need `requestOptions.timeout: 8000`
- LiteLLM model names (hyphenated) must match `model_name` entries in `litellm/litellm.yaml`
- llama.cpp server models are accessible via LiteLLM (see `litellm.yaml` llama-server section)

---

### 4. `crush/crush.json`

Crush terminal AI — routes through LiteLLM proxy.

```
crush/crush.json:
  providers:
    litellm:
      name: "LiteLLM (local)"
      type: "openai-compat"
      base_url: "http://localhost:4000/v1"
      api_key: "sk-local"
      models:
        - id: <litellm-model>         # LiteLLM format
          name: <display>
          context_window: <int>
          default_max_tokens: <int>
  default_provider: "litellm"
  default_model: <litellm-model>      # LiteLLM format
```

**Source mapping:**

| Field           | Source                            | Transform                    |
| --------------- | --------------------------------- | ---------------------------- |
| `models[].id`   | subset of `OLLAMA_MODELS`         | Ollama → LiteLLM (`:` → `-`) |
| `default_model` | `CONTINUE_ROLES[chat]` or primary | LiteLLM format               |

**Typical model subset (4-5 models):**

| Role            | Source variable                                   | LiteLLM model |
| --------------- | ------------------------------------------------- | ------------- |
| Primary coding  | `OPENCODE_AGENTS[code]` or `CONTINUE_ROLES[chat]` | converted     |
| Writing/general | `CONTINUE_ROLES[chat_alt]`                        | converted     |
| Reasoning       | `OPENCODE_AGENTS[think]`                          | converted     |
| Planning        | `OPENCODE_AGENTS[plan]`                           | converted     |
| Cloud           | `CLINE_MODEL_CLOUD` or first cloud model          | converted     |

**Gotchas:**

- All model IDs must exist in `litellm/litellm.yaml` `model_list`
- `context_window` should reflect the actual context variant (e.g., 131072 for 128k models)
- Prefer actual context sizes over the 32768 default when known

---

### 5. `gemini/settings.json`

Google Gemini CLI — routes through LiteLLM proxy.

```
gemini/settings.json:
  provider:
    litellm:
      name: "LiteLLM (Local)"
      options:
        baseURL: "http://localhost:4000/v1"
        apiKey: "sk-local"
      models:
        <litellm-model>:             # LiteLLM format (key, hyphens)
          name: <display>            # display name (value)
```

**Source mapping:**

| Field       | Source                    | Format                                   |
| ----------- | ------------------------- | ---------------------------------------- |
| Model keys  | subset of `OLLAMA_MODELS` | LiteLLM format (`:` → `-`, no `:latest`) |
| Model names | manual display names      | free text                                |

**Typical model subset:**

- Research models (qwen3-14b, qwen3-32b)
- General models (qwen3.5-27b variants)
- Reasoning models (deepseek-r1-tools)

**Gotchas:**

- `baseURL` should be `http://localhost:4000/v1` (LiteLLM proxy, not Ollama direct)
- Model keys must use LiteLLM hyphenated format (e.g., `qwen3.5-27b-q8-32k`, not `qwen3.5-27b:q8-32k`)
- Every model key must have a matching `model_name` in `litellm/litellm.yaml`
- Only include models that make sense for Gemini CLI usage (research, general chat)

---

### 6. `grok/grok.json`

Grok CLI — both OpenRouter cloud and Ollama local models.

```
grok/grok.json:
  provider:
    openrouter:
      name: "OpenRouter (Cloud)"
      options:
        baseURL: "https://openrouter.ai/api/v1"
        apiKey: "env.OPENROUTER_API_KEY"
      models:
        <openrouter-model>:          # OpenRouter format (key)
          name: <display>
    ollama:
      name: "Ollama (Local)"
      options:
        baseURL: "http://localhost:11434"
      models:
        <ollama-model>:              # Ollama format (key)
          name: <display>
```

**Source mapping:**

| Field             | Source                        | Format                             |
| ----------------- | ----------------------------- | ---------------------------------- |
| OpenRouter models | subset of `OPENROUTER_MODELS` | OpenRouter format (strip `:cloud`) |
| Ollama models     | subset of `OLLAMA_MODELS`     | Ollama format                      |

**Typical model subset:**

- Cloud: qwen3-8b (planning), claude-sonnet, kimi-k2.6, deepseek-r1-tool-calling-32b
- Local: primary coding, general, reasoning, planning

**Gotchas:**

- OpenRouter models use `org/model` format
- Ollama `baseURL` has NO `/v1` suffix (unlike Gemini)

---

### 7. `groq/local-settings.json`

Groq cloud-only — no local models.

```
groq/local-settings.json:
  defaultModel: <groq-model>
```

**Source mapping:**

| Field          | Source | Format                                                      |
| -------------- | ------ | ----------------------------------------------------------- |
| `defaultModel` | manual | Groq format (e.g., `qwen-3-32b`, `llama-3.3-70b-versatile`) |

**Gotchas:**

- Groq models are cloud-only and have their own naming convention
- Not derived from `OLLAMA_MODELS` or `OPENROUTER_MODELS`
- Keep as-is unless Groq model names change

---

### 8. `litellm/litellm.yaml`

LiteLLM proxy config — the unified routing layer.

```
litellm/litellm.yaml:
  model_list:
    # Cloud (via OpenRouter)
    - model_name: <litellm-model>       # LiteLLM format
      litellm_params:
        model: openrouter/<org/model>   # OpenRouter format
        api_base: https://openrouter.ai/api/v1
        api_key: os.environ/OPENROUTER_API_KEY

    # Local (via Ollama)
    - model_name: <litellm-model>       # LiteLLM format
      litellm_params:
        model: ollama_chat/<ollama-model>  # Ollama format
        api_base: http://localhost:11434

  router_settings:
    model_group_alias:
      <gemini-alias>: <litellm-model>    # Gemini API compatibility aliases
```

**Source mapping:**

| Field                        | Source                       | Transform                      |
| ---------------------------- | ---------------------------- | ------------------------------ |
| Cloud `model_name`           | `OPENROUTER_MODELS`          | strip `:cloud`, `:` → `-`      |
| Cloud `litellm_params.model` | `OPENROUTER_MODELS`          | `openrouter/` + strip `:cloud` |
| Local `model_name`           | `OLLAMA_MODELS` (local only) | `:` → `-`                      |
| Local `litellm_params.model` | `OLLAMA_MODELS`              | `ollama_chat/` + as-is         |
| `model_group_alias`          | manual per-profile           | Gemini API compat              |

**Ollama → LiteLLM model_name transform examples:**

| Ollama format                | LiteLLM model_name           | litellm_params.model                     |
| ---------------------------- | ---------------------------- | ---------------------------------------- |
| `qwen3-coder-30b-a3b:q5-32k` | `qwen3-coder-30b-q5-32k`     | `ollama_chat/qwen3-coder-30b-a3b:q5-32k` |
| `qwen3.5-27b:q8-256k`        | `qwen3.5-27b-q8-256k`        | `ollama_chat/qwen3.5-27b:q8-256k`        |
| `deepseek-r1-tools:14b-128k` | `deepseek-r1-tools-14b-128k` | `ollama_chat/deepseek-r1-tools:14b-128k` |
| `qwen2.5-coder:7b`           | `qwen2.5-coder-7b-q4-32k`    | `ollama_chat/qwen2.5-coder:7b`           |
| `nomic-embed-text`           | `nomic-embed-text`           | `ollama/nomic-embed-text`                |

**OpenRouter → LiteLLM transform examples:**

| OPENROUTER_MODELS | LiteLLM model_name | litellm_params.model            |
| ----------------- | ------------------ | ------------------------------- |
| `kimi-k2.6:cloud` | `kimi-k2.6-cloud`  | `openrouter/moonshot/kimi-k2.6` |
| `glm-5.1:cloud`   | `glm-5.1-cloud`    | `openrouter/thudm/glm-5.1`      |

**Gotchas:**

- Embedding models use `ollama/` prefix (not `ollama_chat/`)
- Default quant models (e.g., `qwen2.5-coder:7b`) need a descriptive LiteLLM name like `qwen2.5-coder-7b-q4-32k`
- `model_group_alias` maps Gemini API model names to local equivalents
- Every model referenced by `claude/settings.json`, `crush/crush.json`, `continue/config.yaml`, or `gemini/settings.json` must exist here
- llama-server models (port 8080) use `openai/<alias>` format — the alias must match the `--alias` flag passed to `llama-server`
- `request_timeout: 600` is required to prevent dropped responses from large models
- llama-server entries do not fail on startup if the server is not running; they only error when called

---

### 9. `opencode/opencode.jsonc`

OpenCode config — both OpenRouter cloud and Ollama local, plus agent assignments.

```
opencode/opencode.jsonc:
  provider:
    openrouter:
      models:
        <openrouter-model>: { name: <display> }
    ollama:
      models:
        <ollama-model>: { name: <display> }    # with :latest for bare names
    litellm:
      models:
        <litellm-model>: { name: <display> }   # llama.cpp server models via LiteLLM
  model: <provider/model>             # default model
  small_model: <provider/model>        # small/fast model
  agent:
    <role>:
      model: <provider/model>          # per-agent model
```

**Source mapping:**

| Field                        | Source                       | Format                                          |
| ---------------------------- | ---------------------------- | ----------------------------------------------- |
| `provider.openrouter.models` | `OPENROUTER_MODELS`          | OpenRouter format (strip `:cloud`)              |
| `provider.ollama.models`     | `OLLAMA_MODELS` (local only) | Ollama format (append `:latest` for bare names) |
| `model`                      | `OPENCODE_AGENTS[code]`      | `ollama/` prefix                                |
| `small_model`                | `OPENCODE_AGENTS[plan]`      | `ollama/` prefix                                |
| `agent.<role>.model`         | `OPENCODE_AGENTS[<role>]`    | `ollama/` or `openrouter/` prefix               |

**Agent model prefix rules:**

| Source           | Prefix        | Example                                  |
| ---------------- | ------------- | ---------------------------------------- |
| Ollama model     | `ollama/`     | `ollama/qwen3-coder-30b-a3b:q5-32k`      |
| OpenRouter model | `openrouter/` | `openrouter/anthropic/claude-sonnet-4-6` |

**Gotchas:**

- Append `:latest` to bare Ollama model keys (e.g., `llama3.2` → `llama3.2:latest`)
- No duplicate keys in `models` objects
- `litellm` provider (openai-compatible, port 4000) exposes llama.cpp server models
- Agent `model` values need provider prefix (`ollama/`, `openrouter/`, or `litellm/`)

---

---

### 10. `cline/settings.jsonc`

Cline (VS Code extension) — reference config + mergeable VS Code settings snippet.

**Deploy:** Merge into `~/Library/Application Support/Code/User/settings.json`

**API config:** Set via Cline sidebar (cannot be set in settings.json). Use:

- Provider: OpenAI Compatible
- Base URL: `http://localhost:4000/v1`
- API Key: `sk-local`
- Model: LiteLLM format (e.g., `qwen3-coder-next-80b-q4-16k`)

**Source mapping:**

| Field         | Source              | Format                         |
| ------------- | ------------------- | ------------------------------ |
| Primary model | `CLINE_MODEL`       | Ollama → LiteLLM (`:` → `-`)   |
| Cloud model   | `CLINE_MODEL_CLOUD` | strip `:cloud`, use in sidebar |

---

### 11. `roocode/settings.jsonc`

Roo Code (VS Code extension) — reference config + VS Code settings snippet.

**Deploy:** Merge into `~/Library/Application Support/Code/User/settings.json`

**API config:** Set via Roo Code sidebar. Supports per-mode model selection:

| Mode      | Source variable          | LiteLLM model                 |
| --------- | ------------------------ | ----------------------------- |
| Code      | `ROOCODE_MODE_CODE`      | `qwen3-coder-next-80b-q4-16k` |
| Architect | `ROOCODE_MODE_ARCHITECT` | `qwen3.6-35b-128k`            |
| Ask       | `ROOCODE_MODE_ASK`       | `qwen3-32b-q5-32k`            |
| Debug     | `ROOCODE_MODE_DEBUG`     | `deepseek-r1-tools-32b-128k`  |

**Gotchas:**

- `roo-cline.modeApiConfigs` in settings.jsonc may or may not be respected depending on extension version — verify in sidebar
- All model IDs must exist in `litellm/litellm.yaml`

---

### 12. `kilocode/settings.jsonc`

Kilo Code (VS Code extension) — reference config + VS Code settings snippet.

**Deploy:** Merge into `~/Library/Application Support/Code/User/settings.json`

Same Cline-based architecture as Roo Code. API config set via sidebar using LiteLLM proxy endpoint.

**Source mapping:**

| Field       | Source                 | Format                       |
| ----------- | ---------------------- | ---------------------------- |
| Model       | `KILOCODE_MODEL`       | Ollama → LiteLLM (`:` → `-`) |
| Cloud model | `KILOCODE_MODEL_CLOUD` | strip `:cloud`               |

---

### 13. `aider/aider.conf.yml`

Aider CLI coding assistant — standard YAML config.

**Deploy:** `~/.aider.conf.yml` (global) or `.aider.conf.yml` (per-project override)

```yaml
model: openai/<litellm-model> # AIDER_MODEL → LiteLLM format with openai/ prefix
weak-model: openai/<litellm-model> # AIDER_WEAK_MODEL
editor-model: openai/<litellm-model> # AIDER_EDITOR_MODEL
openai-api-base: http://localhost:4000/v1
openai-api-key: sk-local
```

**Source mapping:**

| Field          | Source               | Transform                                |
| -------------- | -------------------- | ---------------------------------------- |
| `model`        | `AIDER_MODEL`        | `openai/` + Ollama → LiteLLM (`:` → `-`) |
| `weak-model`   | `AIDER_WEAK_MODEL`   | same                                     |
| `editor-model` | `AIDER_EDITOR_MODEL` | same                                     |

**Gotchas:**

- Aider uses `openai/<model>` prefix to route to custom OpenAI endpoints
- The model name after `openai/` must match a `model_name` in `litellm/litellm.yaml`
- `editor-model` is specifically for applying diffs — Codestral is the best choice

---

### 14. `zed/settings.json`

Zed editor — OpenAI-compatible assistant config.

**Deploy:** Merge into `~/.config/zed/settings.json`

```json
{
  "assistant": {
    "default_model": { "provider": "openai", "model": "<litellm-model>" },
    "version": "2"
  },
  "language_models": {
    "openai": {
      "api_url": "http://localhost:4000/v1",
      "available_models": [ ... ]
    }
  }
}
```

**Source mapping:**

| Field              | Source                    | Transform                    |
| ------------------ | ------------------------- | ---------------------------- |
| `default_model`    | `ZED_MODEL`               | Ollama → LiteLLM (`:` → `-`) |
| `available_models` | subset of `OLLAMA_MODELS` | LiteLLM format               |

**Gotchas:**

- Zed can auto-discover models from `/v1/models` — `available_models` supplements with display names
- `"features": { "inline_completion_provider": "none" }` disables Zed's built-in completions to avoid conflicts

---

### 15. `cursor/settings.jsonc`

Cursor IDE — VS Code-compatible settings + configuration notes.

**Deploy:** Merge into `~/Library/Application Support/Cursor/User/settings.json`

**API config:** Done via Cursor Settings (Cmd+Shift+J) → Models UI:

1. Set OpenAI API Key: `sk-local`
2. Enable "Override OpenAI Base URL": `http://localhost:4000/v1`
3. Add custom model names (LiteLLM format)

**Source mapping:**

| Field       | Source               | Transform                    |
| ----------- | -------------------- | ---------------------------- |
| Model name  | `CURSOR_MODEL`       | Ollama → LiteLLM (`:` → `-`) |
| Cloud model | `CURSOR_MODEL_CLOUD` | strip `:cloud`               |

**Gotchas:**

- Cursor stores its model config in its own storage, not in settings.json
- Privacy: set `cursor.privacy.telemetryLevel: "off"` to prevent prompt telemetry

---

## Update Checklist

When `models.sh` changes, update these files in order:

1. **`models.sh`** — source of truth (already changed)
2. **`ollama/config.json`** — model lists + aliases
3. **`litellm/litellm.yaml`** — model_list + aliases (must exist before all proxy-dependent tools)
4. **`claude/settings.json`** — env vars (LiteLLM format, must match litellm.yaml)
5. **`crush/crush.json`** — model IDs (LiteLLM format, must match litellm.yaml)
6. **`continue/config.yaml`** — model entries + roles
7. **`opencode/opencode.jsonc`** — provider models + agent assignments
8. **`gemini/settings.json`** — LiteLLM model dict
9. **`grok/grok.json`** — OpenRouter + Ollama model dicts
10. **`groq/local-settings.json`** — only if Groq model names change
11. **`aider/aider.conf.yml`** — model names (LiteLLM format with `openai/` prefix)
12. **`zed/settings.json`** — default_model + available_models list
13. **`cline/settings.jsonc`** — update reference comments
14. **`roocode/settings.jsonc`** — update modeApiConfigs + reference comments
15. **`kilocode/settings.jsonc`** — update reference comments
16. **`cursor/settings.jsonc`** — update reference comments

---

## Profile-Specific Notes

### macbook-m1-16gb (16 GB)

- No Qwen3 Coder 30B, Qwen3 32B, Qwen3.6, Gemma 4, GLM-4.7, Llama 3.3
- No `CLAUDE_CODE_OPUS` (too large)
- No `CLINE_MODEL_CLOUD`
- `CONTINUE_ROLES[chat]` = `qwen2.5-coder:7b` (lightest coding model)

### macbook-m2-32gb (32 GB)

- Adds Qwen3 4B, Codestral
- Has `CLAUDE_CODE_OPUS` = `codestral:22b`
- No Qwen3 Coder 30B, Qwen3.6, Gemma 4, GLM-4.7, Llama 3.3

### macmini-m2-16gb (16 GB)

- Same constraints as M1 16GB
- Has `CLAUDE_CODE_OPUS` = `codestral:22b` (can fit solo)
- Has Qwen3 4B (q8-256k)

### macbook-m5-48gb (48 GB)

- Adds Qwen3 Coder 30B (q5), Qwen3.6 (q4), Gemma 4, GLM-4.7, Llama 3.3
- Has `CLINE_MODEL_CLOUD`
- `CONTINUE_ROLES[chat]` = `qwen3-coder-30b-a3b:q5-32k`

### macbook-m5-64gb (64 GB)

- Adds Qwen3 Coder Next 80B, Qwen3 Coder 30B (q6)
- Has `CONTINUE_ROLES[kimi]` for cloud reasoning
- Has reranker model in Continue
- `CONTINUE_ROLES[chat]` = `qwen3-coder-next-80b:q4-16k`
