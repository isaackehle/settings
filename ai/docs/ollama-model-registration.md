---
tags: [ai, ollama, troubleshooting, reference]
---

# Ollama Model Registration — Troubleshooting & Best Practices

## Runtime Install (June 2026) — Official Standalone, NOT Homebrew

**The runtime is the official standalone tarball installed to a user-owned path,
managed by a launchd agent. Do NOT use Homebrew or the GUI App.**

Why: the Homebrew `ollama` bottle (0.30.7/0.30.8 era) ships only the Go `ollama`
binary plus an MLX/Metal stub and **omits `llama-server`**. ollama routes every
GGUF model (our entire `~/.ollama` store) through `llama-server`, so the brew
build cannot load any model — generation fails with
`error starting llama-server: llama-server binary not found` and the CPU
fallback also won't start a server. The macOS GUI App bundled a working
`llama-server`, which is the only reason it used to work. We replaced both with
the official standalone release tarball, which bundles `ollama` + the full
`lib/ollama/` backend (incl. `llama-server` + Metal libs). GPU-accelerated,
no GUI, no sudo.

Install layout (user-owned):

```
~/.local/ollama/bin/ollama          # the binary  (client v0.30.8)
~/.local/ollama/lib/ollama/         # llama-server + ggml/metal backend (36 files)
~/.local/bin/ollama -> ../ollama/bin/ollama   # on PATH
```

Service (all tuning env vars baked in — see plist):

```
~/Library/LaunchAgents/com.kehle.ollama.plist     # label: com.kehle.ollama
# repo source of truth:
ai/profiles/macbook-m5-64gb/ollama/com.kehle.ollama.plist
```

Baked env: `OLLAMA_HOST=0.0.0.0:11434`, `OLLAMA_MAX_LOADED_MODELS=3`,
`OLLAMA_NUM_PARALLEL=1`, `OLLAMA_KEEP_ALIVE=30m`, `OLLAMA_FLASH_ATTENTION=1`,
`OLLAMA_KV_CACHE_TYPE=q8_0`. (Do **not** also export these from the shell rc —
a shell export never reaches the launchd-managed server process.) This service
supersedes the old env-only agent `com.kehle.ollama-env`.

Install / reinstall is automated by `ai/runtimes/ollama.sh` (`setup_ollama`).
Manual service reload:

```shell
cp ai/profiles/macbook-m5-64gb/ollama/com.kehle.ollama.plist ~/Library/LaunchAgents/
launchctl bootout   gui/$(id -u)/com.kehle.ollama 2>/dev/null || true
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.kehle.ollama.plist
launchctl enable    gui/$(id -u)/com.kehle.ollama
```

Verified working: `qwen2.5:32b-96k` loads **100% GPU** (Apple M5 Max, Metal),
context 98304, generation through `/v1/chat/completions` returns HTTP 200.
Upgrades = re-run `setup_ollama` (re-downloads the latest tarball); the
`~/.ollama` model store is never touched.

## Key Findings (June 2026)

### Architecture Support Requires Ollama ≥ 0.30.0

The `qwen35` GGUF architecture (used by Qwen 3.5 models) is **not supported** in
Ollama 0.24.0. Upgrading to Ollama 0.30.0 resolves the `unknown model architecture:
'qwen35'` error.

**Symptom:** `unable to load model: /path/to/sha256-blob` with server log showing
`unknown model architecture: 'qwen35'`.

**Fix:** Use Ollama 0.30.0+. (The runtime is now the official standalone tarball
under `~/.local/ollama` — see the Runtime Install section above. `brew upgrade
ollama` is obsolete and produces a backend without `llama-server`.)

### Bare GGUF Path Registration Works (With Caveats)

Models registered with `FROM /path/to/file.gguf` (bare local blob paths) work
functionally but **lose the embedded Jinja2 chat template**. This means:

- Tool-calling may break (model narrates tool calls as text instead of structured JSON)
- Chat formatting may differ from the model author's intent

**Preferred:** Use `FROM hf.co/<repo>:<filename>` to preserve the chat template.

**Current state (June 2026):** `qwen3.5-27b:q4` has been re-registered with
`FROM hf.co/...` and has a full Jinja2 template with tool-calling support. All
other custom models still use bare blob paths. See the Template Audit section
below for the full status.

### Ollama GUI App vs Homebrew Version (HISTORICAL — no longer applicable)

> **Superseded (June 2026):** Neither the GUI App nor Homebrew is used anymore.
> The runtime is the official standalone tarball under `~/.local/ollama`, run by
> the `com.kehle.ollama` launchd agent (see the Runtime Install section at the
> top). The notes below are retained only to explain old installs.

The Ollama GUI app (`/Applications/Ollama.app`) and the Homebrew binary
(`/opt/homebrew/bin/ollama`) were separate installations with separate versions.
After upgrading via `brew upgrade ollama`, the **GUI app had to also be updated**
separately — the server process ran from the GUI app, not Homebrew.

**Fix when server version lags client version:**

```shell
# Check versions (client vs server)
ollama --version                    # shows client version
curl -s http://localhost:11434/api/version  # shows server version

# If server is older, update the GUI app
curl -sL "https://ollama.com/download/Ollama-darwin.zip" -o /tmp/Ollama-darwin.zip
killall Ollama 2>/dev/null
rm -rf /Applications/Ollama.app
unzip -q /tmp/Ollama-darwin.zip -d /Applications/
open /Applications/Ollama.app
```

### Distill Models Use `qwen35` Architecture

The Qwen 3.5 distill models (Claude Opus 4.6 distill, Gemini 3.1 distill) use the
same `qwen35` architecture as the base Qwen 3.5 model. They require Ollama 0.30.0+.

## Model Registration Patterns

### Pattern 1: Official Ollama Library (Preferred for library models)

```shell
ollama pull qwen3.5:27b           # pulls Q4_K_M by default
ollama pull qwen3.5:27b-q4_K_M     # explicit quant
ollama pull qwen3:4b                # standard library model
```

These always have correct chat templates and are the simplest path.

### Pattern 2: HF Reference (Preferred for custom GGUFs)

```shell
cat > /tmp/model.Modelfile << 'EOF'
FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0
PARAMETER repeat_penalty 1.05
EOF
ollama create qwen3-coder-30b-a3b:q6 -f /tmp/model.Modelfile
```

This preserves the Jinja2 chat template from the GGUF metadata, ensuring
tool-calling works correctly.

### Pattern 3: Local GGUF (Works but loses template)

```shell
cat > /tmp/model.Modelfile << 'EOF'
FROM /usr/local/lib/llama-models/qwen3.5-27b-opus4.6-it-ds-q4_k_m.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0.6
EOF
ollama create qwen3.5-27b:q4 -f /tmp/model.Modelfile
```

This works for loading the model but may lose the chat template. Use only when
the HF reference is unavailable or the model is not on HuggingFace.

### Pattern 4: Context Variants (Always from base model)

```shell
cat > /tmp/model-128k.Modelfile << 'EOF'
FROM qwen3.5-27b:q4
PARAMETER num_ctx 131072
PARAMETER temperature 0.6
EOF
ollama create qwen3.5-27b:q4-128k -f /tmp/model-128k.Modelfile
```

Context variants inherit the template from the base model. Always create them
from the base alias, not from a GGUF path.

## HF Source Reference (from models.json)

| Alias                     | HF Source                                                                              | Remote Filename                                                            |
| ------------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| `qwen3-coder-30b-a3b:q6`  | `hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF`                                      | `Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf`                             |
| `qwen3.5-27b:q4`          | `hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF`                  | `Qwen3.5-27B.Q4_K_M.gguf`                                                  |
| `qwen3.5-27b:gemini3.1`   | `hf.co/Jackrong/Qwen3.5-27B-Gemini-3.1-Pro-Reasoning-Distill-GGUF`                     | `Qwen3.5-27B.Q4_K_M.gguf`                                                  |
| `deepseek-r1:32b`         | `hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF`                                    | `DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf`                                 |
| `codestral:22b`           | `hf.co/bartowski/Codestral-22B-v0.1-GGUF`                                              | `Codestral-22B-v0.1-Q4_K_M.gguf`                                           |
| `qwen2.5:32b`             | `hf.co/hesamation/Qwen2.5-32B-Instruct-GGUF`                                           | `Qwen2.5-32B-Instruct.Q4_K_M.gguf`                                         |
| `qwen3.6-27b:opus-sonnet` | `hf.co/Brian6145/Qwen3.6-27B-Claude-Opus-Sonnet-DistilledV2-MTP-GGUF`                  | `Qwen3.6-27B-Claude-Opus-Sonnet-DistilledV2-MTP-Q4_K_M.gguf`               |
| `qwen3-14b:sonnet4.5`     | `hf.co/TeichAI/Qwen3-14B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF`                     | `Qwen3-14B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf`           |
| `qwen3-8b:sonnet4.5`      | `hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF`                      | `Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf`            |
| `qwen2.5-7b:multi`        | `hf.co/mradermacher/Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL-GGUF` | `Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL.Q4_K_M.gguf` |
| `qwen2.5-coder:7b`        | `hf.co/unsloth/Qwen2.5-Coder-7B-Instruct-GGUF`                                         | `Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf`                                    |
| `qwen2.5-coder:1.5b`      | `hf.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-GGUF`                                       | `Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf`                                  |
| `qwen3:4b`                | `hf.co/Qwen/Qwen3-4B-GGUF`                                                             | `Qwen3-4B-Q4_K_M.gguf`                                                     |
| `qwen3.5:4b`              | `hf.co/unsloth/Qwen3.5-4B-GGUF`                                                        | `Qwen3.5-4B-UD-Q4_K_XL.gguf`                                               |
| `nomic-embed-text`        | `hf.co/nomic-ai/nomic-embed-text-v1.5-GGUF`                                            | `nomic-embed-text-v1.5.f16.gguf`                                           |

## Re-registration Procedure

To re-register a model with `FROM hf.co/...` (preserving chat template):

```shell
# 1. Remove the old model
ollama rm qwen3.5-27b:q4

# 2. Create with HF reference
cat > /tmp/model.Modelfile << 'EOF'
FROM hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF:Qwen3.5-27B.Q4_K_M.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0.6
EOF
ollama create qwen3.5-27b:q4 -f /tmp/model.Modelfile

# 3. Recreate context variants from the base
cat > /tmp/model-128k.Modelfile << 'EOF'
FROM qwen3.5-27b:q4
PARAMETER num_ctx 131072
PARAMETER temperature 0.6
EOF
ollama create qwen3.5-27b:q4-128k -f /tmp/model-128k.Modelfile
```

## Ollama Version Requirements

| Architecture  | Minimum Ollama | Notes                  |
| ------------- | -------------- | ---------------------- |
| `qwen2`       | 0.14+          | Qwen 2, 2.5, 2.5 Coder |
| `qwen3`       | 0.21+          | Qwen 3, 3 Coder        |
| `qwen35`      | 0.30+          | Qwen 3.5, 3.5 distills |
| `qwen3coder`  | 0.24+          | Qwen3 Coder 30B A3B    |
| `deepseek-r1` | 0.17+          | DeepSeek R1 distills   |
| `codestral`   | 0.14+          | Codestral 22B          |

Check version: `ollama --version`
Upgrade: re-run `setup_ollama` in `ai/runtimes/ollama.sh` (re-downloads the
official standalone tarball and reloads the `com.kehle.ollama` agent).

## Template Audit (June 2026)

Models registered with `FROM hf.co/...` get full Jinja2 chat templates.
Models registered from bare GGUF paths get `TEMPLATE {{ .Prompt }}` (minimal).
Official Ollama library models get either full Jinja2 templates or
`RENDERER/PARSER` directives (architecture-native rendering).

### Full Jinja2 Template (tool-calling works)

| Model                    | Registration     | Template Lines | Tool Support |
| ------------------------ | ---------------- | -------------- | ------------ |
| `qwen3.5-27b:q4`         | `FROM hf.co/...` | 31             | Full         |
| `deepseek-r1-tools:32b`  | MFDoom pull      | 59             | Full         |
| `qwen3-coder-30b-a3b:q6` | bare GGUF        | 6              | Partial      |
| `qwen3-14b:sonnet4.5`    | bare GGUF        | 6              | Partial      |
| `qwen3-8b:sonnet4.5`     | bare GGUF        | 6              | Partial      |
| `qwen2.5-7b:multi`       | bare GGUF        | 7              | Partial      |

### Minimal Template (needs re-registration)

| Model                     | Template           | Tool Support | Priority |
| ------------------------- | ------------------ | ------------ | -------- |
| `codestral:22b`           | `{{ .Prompt }}`    | None         | Medium   |
| `qwen2.5:32b`             | `{{ .Prompt }}`    | None         | High     |
| `qwen3.5-27b:gemini3.1`   | `{{ .Prompt }}`    | None\*       | Medium   |
| `qwen3-coder-next-80b:q4` | 13 lines, no tools | None         | Low      |
| `qwen3.6-27b:opus-sonnet` | 12 lines, no tools | None         | Low      |
| `deepseek-r1:32b`         | 10 lines, no tools | None         | Low      |

\*`qwen3.5-27b:gemini3.1` works for tool-calling on Ollama 0.30.0+ because the
`qwen35` architecture has a built-in renderer, but the template is still minimal
and multi-turn conversations may not format correctly.

### Official Library Models (always correct)

| Model                | Template Type                         | Notes               |
| -------------------- | ------------------------------------- | ------------------- |
| `qwen3:4b`           | Full Jinja2 (31 lines)                | Pulled from library |
| `qwen3.5:4b`         | `RENDERER qwen3.5` / `PARSER qwen3.5` | Architecture-native |
| `qwen3.5:27b`        | `RENDERER qwen3.5` / `PARSER qwen3.5` | Architecture-native |
| `qwen2.5-coder:7b`   | Full Jinja2 (35 lines)                | Pulled from library |
| `qwen2.5-coder:1.5b` | Full Jinja2                           | Pulled from library |
| `nomic-embed-text`   | Minimal (embeddings only)             | No chat needed      |

### Re-registration Priority

Re-register with `FROM hf.co/...` when convenient. Each re-registration
requires downloading the model metadata from HuggingFace (~1-5 minutes for
metadata, longer if the GGUF needs re-downloading).

1. **High priority** (used for agentic tool-calling):
   - `qwen2.5:32b` — agentic coding model
2. **Medium priority** (used for specific tasks):
   - `codestral:22b` — apply/insert model
   - `qwen3.5-27b:gemini3.1` — writing distill
3. **Low priority** (used infrequently or for non-tool tasks):
   - `qwen3-coder-next-80b:q4` — solo coding
   - `qwen3.6-27b:opus-sonnet` — alternate distill
   - `deepseek-r1:32b` — pure reasoning (no tool-calling needed)
