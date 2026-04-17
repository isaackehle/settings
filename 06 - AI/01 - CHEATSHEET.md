# AI Tooling Cheat Sheet

## Core Model Stack (all local via Ollama, M5 Max 48GB)

| Model                                              | Size (loaded @32K) | Role                                                          |
| -------------------------------------------------- | ------------------ | ------------------------------------------------------------- |
| `qwen3-coder-30b-32k`                              | ~25 GB             | Primary coding — UD-Q5_K_XL weights, 32K ctx                  |
| `qwen3-coder-30b-220k`                             | ~45 GB             | Large-context coding — same weights, 220K ctx (solo use only) |
| `qwen3.5:27b`                                      | ~20 GB             | Writing, docs, cover letters                                  |
| `dengcao/Qwen3-14B:Q5_K_M`                         | ~12 GB             | Research / read-only analysis                                 |
| `mfdoom/deepseek-r1-tool-calling:8b`               | ~5 GB              | Reasoning + tool calls                                        |
| `deepseek-r1:8b`                                   | ~5 GB              | Reasoning, chat-only (no tools)                               |
| `hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M` | ~3 GB              | Planning, fast tasks                                          |
| `codestral:22b`                                    | ~14 GB             | Code apply/insert, light coding                               |
| `qwen2.5-coder:7b`                                 | ~5 GB              | Fast code tasks                                               |
| `qwen2.5-coder:1.5b`                               | ~1 GB              | Autocomplete                                                  |
| `nomic-embed-text`                                 | ~0.3 GB            | Embeddings (Continue/RAG)                                     |

**Memory rule of thumb:** code + think can coexist (~30 GB). Code + write pushes ~45 GB — fine, but nothing else large should be loaded. Ollama evicts after 5 min idle.

---

## opencode

**Config:** `scripts/configs/opencode.jsonc` → copy to `~/.config/opencode/config.jsonc`

### Agents (invoke with `/agent <name>` or select in sidebar)

| Agent            | Model                       | Use for                                                    |
| ---------------- | --------------------------- | ---------------------------------------------------------- |
| `code` (default) | qwen3-coder-30b-32k         | Editing, refactoring, debugging, tool calls                |
| `think`          | deepseek-r1-tool-calling:8b | Tradeoff analysis, debugging strategy, scoring             |
| `write`          | qwen3.5:27b                 | Resumes, cover letters, docs, polished prose               |
| `research`       | Qwen3-14B                   | Codebase/web investigation — saves to Obsidian `Research/` |
| `plan`           | Qwen3-4B                    | Next steps, task breakdown, routing                        |

### Quick reference

```
/agent code      # switch to code agent
/agent think     # switch to reasoning agent
/agent write     # switch to writing agent
/agent research  # read-only investigation
/agent plan      # fast planning
```

Switch model mid-session with the model picker (`Ctrl+M` or sidebar).
Use `qwen3-coder-30b-220k` manually when you need >32K context (large codebase traversal).

---

## Continue (VS Code)

**Config:** `~/.continue/config.yaml`

Roles determine which model is used automatically:

| Role                   | Model               | Triggered by                       |
| ---------------------- | ------------------- | ---------------------------------- |
| `chat` / `edit`        | qwen3-coder-30b-32k | Chat panel, inline edit (`Ctrl+I`) |
| `chat` (alt)           | Mistral Small 24B   | Manual model switch in chat        |
| `apply`                | codestral:22b       | Applying suggested code to file    |
| `autocomplete` (light) | qwen2.5-coder:1.5b  | Inline completions (default)       |
| `autocomplete` (heavy) | qwen2.5-coder:7b    | Switch manually for complex files  |
| `embed`                | nomic-embed-text    | `@codebase` semantic search        |

### Quick reference

```
Ctrl+L          open chat panel
Ctrl+I          inline edit (select code first)
Ctrl+Shift+R    quick refactor
@codebase       semantic search across repo
@file           include specific file in context
@docs           include indexed docs
```

Switch models in the chat panel with the model dropdown (bottom of chat).

---

## Cline (VS Code)

**Config:** Set via Cline sidebar → gear icon → API Provider: `Ollama`, Base URL: `http://localhost:11434`

Recommended model to set in Cline UI: `qwen3-coder-30b-32k`

Cline is an autonomous agent — it plans and executes multi-step tasks with tool calls. Use it for larger self-directed tasks; use Continue for quick inline edits and chat.

### Quick reference

```
Ctrl+Shift+P → "Cline: Open"   open Cline panel
"New Task"                      start a new autonomous task
Approve / Reject                review each tool call before it runs
Resume Task                     continue a previous task from history
```

**Tips:**
- Cline will ask to read/write files and run commands — review each step.
- For faster iteration on small edits, prefer Continue (`Ctrl+I`).
- Cline's task history persists in `~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/`.

---

## Claude Code

**Config:** `scripts/configs/claude_code.json` → copy to `~/.claude/settings.json` (global) or `.claude/settings.json` (project)
 
Requires LiteLLM running on port 4000 — see [LiteLLM](#litellm) below. Claude Code sends Anthropic-format requests; LiteLLM translates them to Ollama's OpenAI-compatible format.

### Model tiers
    
| Tier             | Env var                          | Mapped model             | Role                 |
| ---------------- | -------------------------------- | ------------------------ | -------------------- |
| Sonnet (default) | `ANTHROPIC_DEFAULT_SONNET_MODEL` | `qwen3-coder-30b-32k`    | Primary coding       |
| Haiku (fast)     | `ANTHROPIC_DEFAULT_HAIKU_MODEL`  | `Qwen3-4B-Instruct-2507` | Planning, routing    |
| Opus (large ctx) | `ANTHROPIC_DEFAULT_OPUS_MODEL`   | `qwen3-coder-30b-220k`   | Large context (solo) |

### Quick reference

```
/model qwen3-coder-30b-32k                                  switch to coding model
/model mfdoom/deepseek-r1-tool-calling:8b                   switch to reasoning model
/model qwen3.5:27b                                          switch to writing model
/model dengcao/Qwen3-14B:Q5_K_M                             switch to research model
/model hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M     switch to planning model
```
 
---

## LiteLLM

**Config:** `scripts/configs/litellm.yaml` → copy to `~/.config/litellm/config.yaml`

Proxy that bridges Claude Code (Anthropic API format) to Ollama (OpenAI format). All models in the core stack are pre-configured.

### Setup

```bash
pip install litellm
litellm --config scripts/configs/litellm.yaml --port 4000
```

### Quick reference

```bash
litellm --config ~/.config/litellm/config.yaml --port 4000   # start proxy
curl http://localhost:4000/health                            # verify running
curl http://localhost:4000/v1/models                         # list routed models
```

**Tips:**
- Start LiteLLM before launching Claude Code — it must be up when Claude Code initializes.
- `drop_params: true` in the config silently drops Anthropic-specific params (e.g. `betas`) that Ollama doesn't accept.
- To background it: `litellm --config ~/.config/litellm/config.yaml --port 4000 &`.

---

## Model switching in Ollama directly

```bash
ollama list                          # all installed models
ollama ps                            # currently loaded + memory usage
ollama run qwen3-coder-30b-32k       # interactive shell with model
ollama stop <model>                  # force-unload to free memory
OLLAMA_KEEP_ALIVE=0 ollama serve     # unload models immediately when idle
```
