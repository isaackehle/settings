# Canonical Rules for Profile Configuration

> **Purpose:** Every decision made across profiles is captured here with a weight
> so that audits, maintenance, and new-machine setups respect the same choices.
> Weight: **critical** > high > medium > low > cosmetic.
>
> **Decision process:** When choosing a model for a role, ASK the tradeoffs:
>
> - What's the inference speed (tok/s)?
> - Does it fit in the machine's RAM budget alongside other models?
> - Is a specialized variant (coder, distil) worth the tradeoff vs general?
> - If unclear, present options with rationale — don't silently pick one.

---

## W1. MaxTokens Ceilings

| Weight       | Rule                                                      | Applies To         | Value            |
| ------------ | --------------------------------------------------------- | ------------------ | ---------------- |
| **critical** | Coding agents should never exceed 1024 maxTokens          | code, local, build | 1024             |
| **critical** | Planning agents are fast/lightweight                      | plan               | 512              |
| **high**     | Research needs room for structured evidence               | research           | 1024             |
| **high**     | Writing needs room for prose, cover letters, docs         | write              | 2048             |
| low          | Reasoning agents (think) are read-only, few tokens needed | think              | default (no cap) |
| low          | Summary/title agents are tiny, fast                       | summary, title     | default (no cap) |

**Rationale:** `maxTokens` was the #1 performance killer — original `16000` caused
~141s wait times per response at 113 tok/s. Tokens beyond what the model actually
needs are wasted wall-clock time. 1024 handles virtually all coding responses;
the model can always call back for follow-ups.

---

## W2. Instructions Policy

| Weight       | Rule                                                                     | Applies To          |
| ------------ | ------------------------------------------------------------------------ | ------------------- |
| **critical** | `instructions` MUST be `[]` (empty array) globally                       | All opencode.jsonc  |
| high         | Per-project instructions go in `.opencode/opencode.json` at project root | Per-project configs |
| medium       | Shared instructions (if any) go in `agents/*.md` prompt files            | Agent prompt files  |

**Rationale:** The old glob `["CONTRIBUTING.md", "docs/*.md"]` loaded 2000+ lines
into every prompt. Instructions should be project-specific, not global.

---

## W3. MCP Tool Filters

| Weight       | Rule                                                                      | Applies To                |
| ------------ | ------------------------------------------------------------------------- | ------------------------- |
| **critical** | MCP tools (HA, Reminders) must be filtered on agents that don't need them | think, write, code, local |
| high         | Agents that benefit from MCP access should NOT have filters               | build, research, plan     |
| low          | Tiny agents (summary, title) don't need explicit filters                  | summary, title            |

**Pattern:**

```jsonc
// Agents that should NOT see MCP tools:
"code": {
  "tools": {
    "home-assistant_*": false,
    "apple-reminders_*": false
  }
},
"local": {
  "tools": {
    "home-assistant_*": false,
    "apple-reminders_*": false
  }
},
"think": {
  "tools": {
    "home-assistant_*": false,
    "apple-reminders_*": false
  }
},
"write": {
  "tools": {
    "home-assistant_*": false,
    "apple-reminders_*": false
  }
}

// Agents that SHOULD see MCP tools — no "tools" block at all:
"build": { ... /* no tools filter */ }
"research": { ... /* no tools filter */ }
"plan": { ... /* no tools filter */ }
```

**Rationale:** MCP tool definitions inflate context for agents that never use
them (think = reasoning, write = prose). `code` and `local` were initially
unfiltered too, but in practice MCP access causes them to attempt Home
Assistant tool calls for general questions (e.g., weather), which hang on
slow remote connections and return nothing useful. They should use webfetch
instead. `build`, `research`, and `plan` keep MCP access since they may
genuinely benefit from HA data or reminders.

---

## W4. MCP Server Configuration

| Weight       | Rule                                                                  | Applies To         |
| ------------ | --------------------------------------------------------------------- | ------------------ |
| **critical** | Every opencode config MUST include `mcp` + `experimental.mcp_timeout` | All opencode.jsonc |
| **critical** | `experimental.mcp_timeout` MUST be `8000` (8 seconds)                 | Same               |
| high         | HA token references `${HOMEASSISTANT_TOKEN}` env var (not inline)     | Same               |
| high         | HA URL is `https://kehle.duckdns.org:8123`                            | Same               |

**Required MCP block:**

```jsonc
"mcp": {
  "apple-reminders": {
    "type": "local",
    "command": ["npx", "-y", "mcp-server-apple-events"],
    "enabled": true
  },
  "home-assistant": {
    "type": "local",
    "command": ["uvx", "ha-mcp@latest"],
    "enabled": true,
    "env": {
      "HOMEASSISTANT_URL": "https://kehle.duckdns.org:8123",
      "HOMEASSISTANT_TOKEN": "${HOMEASSISTANT_TOKEN}"
    }
  }
},
"experimental": {
  "mcp_timeout": 8000
}
```

**Rationale:** Without `mcp_timeout`, an unreachable HA server stalls the agent
indefinitely. Without the MCP block, there's no way to use HA/Reminders at all.

---

## W5. Provider Requirements

| Weight       | Rule                                                                     | Applies To         |
| ------------ | ------------------------------------------------------------------------ | ------------------ |
| **critical** | MUST include `ollama` provider (localhost:11434)                         | All opencode.jsonc |
| **critical** | MUST include `openrouter` provider (openrouter.ai)                       | All opencode.jsonc |
| high         | SHOULD include `llamarouter` provider (localhost:10000) for GGUF direct  | All opencode.jsonc |
| medium       | OpenRouter `apiKey` uses env var interpolation (`${OPENROUTER_API_KEY}`) | All opencode.jsonc |

**Rationale:** llamarouter gives access to llama.cpp-served GGUFs independently
from Ollama. OpenRouter provides cloud fallback.

---

## W6. Missing Agents

| Weight | Rule                                                                 | Applies To         |
| ------ | -------------------------------------------------------------------- | ------------------ |
| high   | ALL opencode configs must define `build`, `summary`, `title` agents  | All opencode.jsonc |
| high   | ALL `models.sh` must have complete `OPENCODE_AGENTS` with ALL agents | All models.sh      |

**Complete agent set:**

```
code, local, plan, research, think, write, build, summary, title
```

**Rationale:** Incomplete agent roster means `opencode <agent>` silently falls
back to the default agent. New tools/patterns reference these agents.

---

## W7. Model Assignments (by hardware tier)

| Tier     | RAM  | Primary Coder            | Reasoning         | Writing               | Opus (Claude)             | Plan/Fast  |
| -------- | ---- | ------------------------ | ----------------- | --------------------- | ------------------------- | ---------- |
| **64GB** | 64GB | `qwen3-coder-30b-a3b:q6` | `deepseek-r1:32b` | `qwen3-14b:sonnet4.5` | `qwen3.6-35b:opus4.7-128k` | `qwen3:4b` |
| **48GB** | 48GB | `qwen3-coder-30b-a3b:q5` | `deepseek-r1:32b` | `qwen3.5-27b:q4`      | `qwen3.6-35b:opus4.7-128k` | `qwen3:4b` |
| **32GB** | 32GB | `qwen3-coder-30b-a3b:q5` | `deepseek-r1:7b`  | `qwen3.5-27b:q4`      | `qwen3.5-27b:q4` (Tier 2) | `qwen3:4b` |
| **16GB** | 16GB | `qwen2.5-coder:7b`       | `deepseek-r1:7b`  | `qwen3:14b`           | `qwen3:14b` (Tier 2)      | `qwen3:4b` |

**Claude Sonnet on 16GB:** uses `qwen3-8b:sonnet4.5` (not the primary coder) — 8B dense,
56 tok/s, same speed as 14B but fits alongside other models at ~6GB RAM.
`qwen2.5-coder:7b` is the coder for non-Claude tools where smaller footprint matters.

| Weight       | Rule                                                                                    |
| ------------ | --------------------------------------------------------------------------------------- |
| **critical** | Primary coder for 32GB+ MUST be `qwen3-coder-30b-a3b` (MoE, best quality/speed ratio)   |
| **critical** | Primary coder for 16GB MUST be `qwen2.5-coder:7b` (fits in RAM)                         |
| **critical** | Claude's "Sonnet" (primary) MUST match the primary coder, NOT a general model           |
| high         | Opus for 48GB+ MUST be `qwen3.6-35b:opus4.7-128k` (MoE 35B, 23GB Q4_K_M, ~110 tok/s, Claude 4.6 reasoning distilled). The 3.6:35b base variants are blocked by a `rope_sections` 3-vs-4 bug in llama.cpp's qwen35moe.cpp; the opus4.7-128k distillate from `hf.co/hesamation` is the one variant in the family that ships with a working RoPE layout. Decision: 2026-06-13 (revised 1h).

**NOTE: rope_sections fix in llama.cpp master**
The `qwen3.6:35b` base variants (96k, 32k, 128k, 256k, and the base opus tag) all carry the `rope_sections` bug (3 vs 4). The opus distillates from both hesamation (4.6) and mudler (4.7) ship with a working RoPE layout. Recommendation: keep only `opus4.6-128k` and `opus4.7-128k` (the distillate variants), drop all base variants. Decision: 2026-06-13. |
| high         | `deepseek-r1:32b` only on 48GB+ (needs >=48GB RAM)                                      |
| high         | `deepseek-r1:7b` on 16GB-32GB (fits comfortably)                                        |
| medium       | Writing model can be a general model (not necessarily coder) — good prose > speed       |
| medium       | Opus for 32GB stays at `qwen3.5-27b:q4` (Tier 2 — 35B MoE at 21GB margin is tight)      |
| medium       | Opus for 16GB stays at `qwen3:14b` (Tier 2 — 9B Opus distil is weaker than 14B general) |
| low          | `qwen3:4b` is universal fast model across all tiers                                     |

**Rationale for Opus choices:**

- `qwen3.6-35b:opus4.7-128k` is a MoE 35B-A3B (Q8 quant, ~24GB), APEX-I calibrated for Claude 4.7 reasoning. **Measured 110 tok/s** on the M5 Max 64GB — solid throughput at 128K context. The 3.6:35b base variants (`qwen3.6:35b-96k`, `qwen3.6:35b`, `qwen3.6:35b-32k/128k`, `qwen3.6-35b:opus4.6` base) are blocked by a `rope_sections` 3-vs-4 bug in llama.cpp's `qwen35moe.cpp` and `qwen35.cpp` (the GGUF was written with 3 sections; the source hard-codes an expected length of 4). The Opus-distilled variant from `hf.co/mudler/Qwen3.6-35B-A3B-Claude-4.7-Opus-Distilled-APEX-GGUF` ships with a working RoPE layout and runs cleanly through Ollama. Decision: 2026-06-13 (revised 1h).

**NOTE: rope_sections fix in llama.cpp master**
The `qwen3.6:35b` base variants (96k, 32k, 128k, 256k, and the base opus tag) all carry the `rope_sections` bug (3 vs 4). The opus distillates from both hesamation (4.6) and mudler (4.7) ship with a working RoPE layout. Recommendation: keep only `opus4.6-128k` and `opus4.7-128k` (the distillate variants), drop all base variants. Decision: 2026-06-13.
- 32GB: 20GB dense leaves ~12GB for other models — workable as sole model, tight if running alongside.
- 16GB: dense 32B won't fit alongside anything; use `qwen3:14b` Tier 2 distil.

---

## W8. Temperature Settings

| Weight       | Agent              | Temperature | Rationale                              |
| ------------ | ------------------ | ----------- | -------------------------------------- |
| **critical** | code, build, local | 0.1–0.2     | Low temp = deterministic code          |
| high         | plan               | 0.25        | Slight creativity for task breakdown   |
| high         | research           | 0.25        | Structured findings, consistent format |
| medium       | think              | 0.3         | Balance reasoning creativity and focus |
| medium       | write              | 0.65        | Higher temp = varied, natural prose    |
| low          | summary, title     | 0.2         | Deterministic summaries                |

---

## W9. Global Top-Level Settings

| Weight       | Setting           | Value                                   |
| ------------ | ----------------- | --------------------------------------- |
| **critical** | `default_agent`   | `"code"`                                |
| high         | `model` (default) | matches primary coder                   |
| high         | `small_model`     | `"ollama/qwen3:4b"`                     |
| medium       | `server.port`     | `4096`                                  |
| low          | `server.mdns`     | `true`                                  |
| low          | `plugin`          | `["opencode-openai-codex-auth@latest"]` |

---

## W10. Permission Defaults

| Weight       | Tool                           | Default   | Exceptions                       |
| ------------ | ------------------------------ | --------- | -------------------------------- |
| **critical** | `bash`                         | `"allow"` | `rm -rf *` → ask, `sudo *` → ask |
| high         | `edit`                         | `"ask"`   | —                                |
| medium       | `glob`, `grep`, `list`, `read` | `"allow"` | —                                |
| high         | `webfetch`                     | `"allow"` | —                                |
| medium       | `external_directory`           | `"ask"`   | —                                |

---

## W11. API Key Interpolation Style

| Weight | Rule                                      | Format                   | Example                        |
| ------ | ----------------------------------------- | ------------------------ | ------------------------------ |
| high   | OpenRouter apiKey uses `${ENV_VAR}` style | `${OPENROUTER_API_KEY}`  | Consistent with HA token style |
| medium | HA token uses `${ENV_VAR}` style          | `${HOMEASSISTANT_TOKEN}` | Same interpolation throughout  |

**Rationale:** `${VAR}` is the standard OpenCode/JSONC environment variable
interpolation syntax. The old `{env:VAR}` style is a different tool's convention.

---

## W12. Model Key Alphabetical Ordering

| Weight | Rule                                                                             | Applies To             |
| ------ | -------------------------------------------------------------------------------- | ---------------------- |
| medium | Model keys within every provider's `models` block MUST be alphabetically sorted  | All opencode.jsonc     |
| low    | When adding a new model, insert at the correct alphabetical position, not at end | Model list maintenance |

**Rationale:** Alphabetical ordering makes diffs reviewable and prevents
accidental duplicates. A model added at the end of the list is easy to miss
during audit. Sort order is by the model key string (the left-hand side before
the colon in `"qwen3.5-9b:opus4.7-128k" : { ... }`), using standard lexicographic
ordering.

**Example of correct ordering:**

```jsonc
"models": {
  "gemma4:31b": { ... },
  "qwen3.6-35b:opus4.7-128k": { ... },
  "qwen3.5-9b:gemini3.1": { ... },
  "qwen3.5-9b:opus4.7-128k": { ... },
  "qwen3.5:4b": { ... },
  "qwen3.6-27b:opus-sonnet": { ... },
  "qwen3:14b": { ... },
  "qwen3:4b": { ... }
}
```

Note: `gemma4` sorts before `qwen3.6` (g < q), and `qwen3.6-35b:opus4.7-128k` sorts before
`qwen3.5-9b:*` because `3.5` < `3.6` at the 5th character (`.` < `-` not the deciding
factor — `5` < `6` at character 6 is).
`qwen3.6-35b:opus4.7-128k` vs `qwen3.5-9b:...` where `3.5` < `3.6` at the 5th character.
Within the same base model, the variant suffix determines order.

---

## W13. Model Source: HF GGUF + `ollama create`

| Weight   | Rule                                                                                           | Applies To                  |
| -------- | ---------------------------------------------------------------------------------------------- | --------------------------- |
| **high** | All models MUST be built from HuggingFace GGUF files via `ollama create`, not `ollama pull`    | Model installation workflow |
| medium   | Download the GGUF directly from the original HF source, write a Modelfile, run `ollama create` | Model installation workflow |
| low      | If HF has safetensors only (no GGUF available), `ollama pull` is acceptable as an exception    | Model installation workflow |

**Rationale:** `ollama pull` downloads a model from the Ollama registry — a black box with
no guarantee of provenance, quantization quality, or prompt template fidelity. Building
from the canonical HF GGUF ensures:

- Verifiable source (the exact quantization uploaded by the model author or a trusted
  community member)
- Full control over the Modelfile (template, system prompt, context window, license)
- Reproducible builds across machines (same HF source → same model)

**Exception:** `alpie-core` (`169Pi/Alpie-Core`) is only available on HF as safetensors
(4-bit NF4, not GGUF). There is no community GGUF conversion. For this model, use
`ollama pull 169pi/alpie-core` then `ollama cp 169pi/alpie-core alpie-core:latest`.

**Workflow for adding a new model:**

```bash
# 1. Find the GGUF on HuggingFace (search "<model-name> GGUF Q4_K_M")
# 2. Download the GGUF file
cd /tmp/ollama-hf-build
huggingface-cli download <hf-repo> --local-dir . --include "*.gguf"
# Or for a single file:
# curl -L -o <filename>.gguf https://huggingface.co/<repo>/resolve/main/<filename>.gguf

# 3. Create a Modelfile
echo "FROM ./<filename>.gguf" > Modelfile

# 4. Create the Ollama model
ollama create <model-name> -f Modelfile

# 5. Clean up
rm -rf /tmp/ollama-hf-build
```

**HF GGUF sources for the current model roster:**

| Config Name                  | HF Repo                                                           | GGUF File                                                       | Size   |
| ---------------------------- | ----------------------------------------------------------------- | --------------------------------------------------------------- | ------ |
| `phi4`                       | `itlwas/phi-4-Q4_K_M-GGUF`                                        | `phi-4-q4_k_m.gguf`                                             | 9.1 GB |
| `phi4-mini`                  | `bartowski/microsoft_Phi-4-mini-instruct-GGUF`                    | `microsoft_Phi-4-mini-instruct-Q4_K_M.gguf`                     | 2.5 GB |
| `qwen3.5-4b:opus-distill-v2` | `Jackrong/Qwen3.5-4B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF` | `Qwen3.5-4B.Q4_K_M.gguf`                                        | 2.6 GB |
| `qwen3-8b:sonnet4.5-distill` | `TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF`       | `Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf` | 5.0 GB |
| `qwen35-27b:opus-agent`      | `Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF`   | `Qwen3.5-27B.Q4_K_M.gguf` (reuse existing local GGUF)           | 17 GB  |
| `alpie-core:latest`          | `169Pi/Alpie-Core` (safetensors only — use `ollama pull`)         | N/A — exception                                                 | 20 GB  |

---

## How to Use This File

1. **Setting up a new machine profile:** Follow W1–W11 in order. Each section
   tells you what values are required per hardware tier (W7).

2. **Auditing existing profiles:** Check each rule. Any violation of a
   **critical** or **high** weight item must be fixed before the config is
   considered clean.

3. **After changes:** Re-run the profile's deployment script (`setup_ai.sh`
   or equivalent) to push updates to the machine.

4. **Updating this file:** When a new tool, agent, or pattern is introduced,
   add it here with the appropriate weight. Do not remove old rules — mark
   them `deprecated` if superseded.
