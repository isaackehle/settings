---
tags: [ai, opencode, reference, learnings]
---

# OpenCode — Configuration Learnings June 2026

Lessons from a full-day audit and fix session. Covers agent design, model
assignment, template issues, and what broke and why.

---

## What OpenCode is (and isn't)

OpenCode is a **multi-agent CLI coding assistant**. It routes tasks to specialized
agents, each backed by a different local or cloud model. It is not:

- A memory system (no cross-session context)
- A research tool by default (requires the `research` agent + webfetch)
- A writing tool (the `write` agent is for document production, not Q&A)

The single most important thing to understand: **agent selection drives everything**.
Wrong agent = wrong model = broken tool calls = frustrating output.

---

## Agent Guide — When to Use Each

| Agent | Model | Use for | Do NOT use for |
| --- | --- | --- | --- |
| `code` | qwen3-coder-30b-a3b:q6 | Editing files, implementing features, refactoring | General questions, research |
| `local` | qwen3-coder-30b-a3b:q6 | Same as code, but offline/sensitive work | Anything needing web |
| `build` | qwen3-coder-30b-a3b:q6 | Running tests, CI, build commands | Writing, planning |
| `think` | deepseek-r1-tools:32b | Decision analysis, debugging strategy, scoring | File editing |
| `research` | qwen3.5-27b:q4 | Fetching URLs, web discovery, technical research | File editing |
| `write` | qwen3.5-27b:q4 | Drafting documents, cover letters, READMEs | Searching files or web |
| `plan` | qwen3:4b | Breaking down tasks, lightweight routing | Complex tool execution |
| `summary` | qwen3.5:4b | Commit messages, session summaries | — |
| `title` | qwen3.5:4b | PR/MR titles | — |

**The research → code workflow** for design/build tasks:

```
research  →  "Find cabinet plans matching 24" × 36" dimensions"
             (fetches URLs, reads pages, returns measurements)

code      →  "Generate an SVG of the layout at 1:10 scale"
             (writes the file, opens it, iterates)
```

---

## What Broke and Why

### 1. `maxTokens: 1024` — the silent truncation killer

The `code` and `local` agents had `"maxTokens": 1024` in `opencode.jsonc`.
A 1024-token output cap silently truncates responses mid-generation. This
caused the "Mo" symptom (output ending abruptly) that looked like a model
quality problem but was actually a config cap.

**Fix:** Removed `maxTokens` from code/local/plan/build agents entirely.
Write agent raised to 4096.

---

### 2. `write` agent had too many tools

The `write` agent inherited all global tool permissions — including `glob`,
`grep`, `list`, `bash`. When asked "find me plans for these dimensions", a
14B model saw `glob` available and went scanning the filesystem.

**What happened:** The model had prior session context about the garage and
cabinets. It interpreted "find plans" as a filesystem task, found the `glob`
tool available, and ran it. It wasn't hallucinating — it was doing exactly
what its permissions allowed.

**Fix:** Added explicit tool denials to the `write` agent:

```jsonc
"tools": {
  "bash": false,
  "glob": false,
  "grep": false,
  "list": false
}
```

Write agents should produce text, not explore filesystems.

---

### 3. Model drift between `model-map.md` and `opencode.jsonc`

The generated `model-map.md` (source of truth) said:
- `think` → `gemma4:31b`
- `write`/`research` → `qwen3.5-27b:q4`

The actual `opencode.jsonc` had:
- `think` → `deepseek-r1:32b`
- `write`/`research` → `qwen3-14b:sonnet4.5`

Three models disagreed between spec and reality. The fix was to update
`opencode.jsonc` to match `models.sh` as source of truth, then regenerate
`model-map.md`.

**Lesson:** Always regenerate `model-map.md` after editing `models.sh` or
`opencode.jsonc`. The generator is at `ai/profiles/generate-model-map.sh`.

---

### 4. `qwen2.5:32b` had no tool-calling template

The Opus/Architect model was registered with a bare GGUF path, which strips
the embedded chat template. Ollama fell back to `TEMPLATE {{ .Prompt }}` —
no tool calling at all.

**Root cause:** Community GGUF distills (hesamation, Jackrong, Brian6145)
don't embed chat templates in their GGUF metadata. Bare-path Ollama
registration loses whatever template was there.

**Fix pattern — two approaches:**

1. **For official library models** (Qwen3.6, Qwen3.5, etc.): Use
   `FROM hf.co/<repo>:<filename>` in the Modelfile. Ollama fetches the model
   manifest from HuggingFace which includes the proper template metadata.
   **But**: some distill GGUFs still have no template embedded — the source
   GGUF is the bottleneck, not the registration method.

2. **For GGUFs with no embedded template**: Extract the template from the
   official base model and inject it explicitly:

   ```shell
   TMPL=$(ollama show qwen3.5-27b:q4 --template 2>/dev/null)
   cat > /tmp/fix.Modelfile << EOF
   FROM hf.co/<distill-repo>:<distill-file>.gguf
   TEMPLATE """${TMPL}"""
   PARAMETER num_ctx 32768
   PARAMETER temperature 0.6
   EOF
   ollama create <alias> -f /tmp/fix.Modelfile
   ```

   The base model's template is architecturally compatible with any distill
   of the same base (same tokenizer, same chat format). The distill only
   changed the weights, not the chat template.

**Verification:**

```shell
# For Jinja2 template models:
ollama show <model> --modelfile | grep -c "ToolCalls\|tool_call"   # must be > 0

# For architecture-native models (RENDERER/PARSER):
ollama show <model> --modelfile | grep RENDERER                     # → RENDERER qwen3.5
```

Models using `RENDERER qwen3.5` (like the official `qwen2.5:32b` library model)
are fine — Ollama handles tool formatting internally. The `{{ .Prompt }}` +
`RENDERER qwen3.5` combination is correct, not broken.

---

### 5. `deepseek-r1-tools:32b` tool check was misleading

Running `grep -c tool_call` on the MFDoom DeepSeek R1 tool-calling model
returned 0 — which looked broken. The model is actually fine:

- MFDoom's template uses `.ToolCalls` (camelCase Go template syntax)
- `grep -c tool_call` (lowercase) misses it
- The full template is 86 lines and handles tool injection and response parsing

The correct check for this model family is `grep -c "ToolCalls\|tool_call"`.

---

## Concurrent Model Loading — The Key Config

The `write` + `research` → `code` workflow requires at least 2 models loaded
simultaneously (e.g., qwen3.5-27b:q4 for write, qwen3-coder-30b-a3b:q6 for code).

**Required env vars (set via LaunchAgent at boot):**

```shell
OLLAMA_MAX_LOADED_MODELS=3     # keep up to 3 models resident
OLLAMA_FLASH_ATTENTION=1       # Metal flash attention — cuts KV cache ~3×
OLLAMA_NUM_PARALLEL=1          # one generation at a time
OLLAMA_KEEP_ALIVE=30m          # hold 30 min before evicting
```

**Safe concurrent combos on 64GB:**

```text
code(26) + plan(3) + autocomplete(1) = 30 GB   ← everyday baseline
code(26) + write(18) + plan(3)       = 47 GB   ← research/write mode
code(26) + think(20) + plan(3)       = 49 GB   ← analysis mode
```

Use `-32k` context variants for concurrent loads (saves ~12 GB vs default 256K).

---

## New Models Added (June 2026)

| Model | Role | Why |
| --- | --- | --- |
| `qwen2.5:32b` | Architect | 73.4% SWE-bench, official library (proper RENDERER template), replaced broken opus4.6 distill |
| `laguna-xs.2` | Alt coder | 68.2% SWE-bench, purpose-built agentic coding, FP8 KV cache |

`qwen2.5:32b` alias now points to `qwen2.5:32b` library weights. The
Claude Opus distill GGUF (hesamation) has no embedded template; the library
model has proper `RENDERER qwen3.5` support.

---

## Files Changed

| File | Change |
| --- | --- |
| `opencode.jsonc` | Removed maxTokens caps, fixed agent model assignments, added write tool restrictions |
| `models.sh` | Updated LOCAL_MODEL_NAMES, OPENCODE_AGENTS, CLAUDE_CODE, ZOOCODE_MODELS |
| `models.json` | Added qwen2.5:32b and laguna-xs.2 |
| `model-map.md` | Regenerated |
| `kilo.jsonc` | debug/think/architect agents fixed; new models added |
| `zoocode/settings.jsonc` | architect → qwen2.5:32b (was broken gemma4:31b cloud) |
| `ollama/config.json` | Added qwen2.5:32b series and laguna-xs.2 |
| `continue/config.yaml` | Added qwen2.5:32b and laguna-xs.2 as chat/edit models |
| `crush/crush.json` | Added qwen2.5:32b and laguna-xs.2 |
| `zed/settings.json` | Replaced broken kimi-k2.6-cloud with qwen2.5:32b-128k |
| `LaunchAgent plist` | Created OLLAMA env vars for concurrent loading |

---

## Quick OpenCode Reference

```shell
# Start with specific agent
opencode --agent research
opencode --agent code
opencode --agent think

# Switch agent mid-session
/agent code      # or /agent write, /agent research, etc.

# Switch model mid-session
/model ollama/qwen2.5:32b

# Check what's running
/status
```

---

_Generated: 2026-06-11_  
_Profile: macbook-m5-64gb_
