---
name: model-updater
description: >
  Search for newer or better LLM models and suggest replacements for what's currently installed.
  Use this skill whenever the user asks about model updates, new model releases, whether their
  models are outdated, what's new from Qwen/Meta/Mistral/DeepSeek/Google, or wants to know if
  there's a better model for a specific role (coding, reasoning, autocomplete, embeddings, RAG).
  Also trigger when the user mentions llmfit, HuggingFace trending, Ollama new models, or says
  things like "check my models", "are there better options", "what dropped recently", or
  "update my model list".
---

# Model Updater

A skill for finding new model releases and suggesting upgrades to the local model stack defined
in `config/models.sh`.

The goal is not to replace every model on every run — it's to surface meaningful upgrades: a newer
version of something already installed, a new model that beats the current one on the relevant
benchmark, or a smaller model that fits better in available RAM with similar quality.

---

## Workflow

### Step 1 — Read the current model config

Read `config/models.sh` from the settings repo (usually at `~/code/isaackehle/settings` or the
user's working folder). Extract:

- Which hardware profiles exist (m5-48gb, m5-64gb, m1, macmini-m2, etc.)
- Which models are assigned to each profile and role (chat, autocomplete, apply, embed, reasoning)
- Any custom model aliases defined in `CUSTOM_MODELS_*` arrays (these pull from HuggingFace via
  `hf.co/...` URLs)

If the user specifies a profile (e.g., "check models for the 48GB config"), focus there. Otherwise
check all profiles.

### Step 2 — Check what Ollama currently has

If Ollama is running locally, call the tags endpoint to see what's installed:

```shell
curl -s http://localhost:11434/api/tags | python3 -c "
import json,sys
tags = json.load(sys.stdin)
for m in tags.get('models', []):
    print(m['name'], m.get('size',''))
"
```

Cross-reference with `models.sh` to identify any models that are configured but not yet pulled,
or pulled but no longer referenced.

### Step 3 — Search for new releases

Search these sources in parallel. Aim for breadth first, then drill into specifics.

**Web search targets:**

Search the web for recent (last 60 days) announcements from:
- Alibaba/Qwen (Qwen3, Qwen3-Coder, Qwen2.5 series)
- DeepSeek (R2, V3, Coder updates)
- Meta (Llama 4, Llama 3.x updates)
- Mistral (Devstral, Codestral updates)
- Google (Gemma 3 updates)
- Microsoft (Phi-4 updates)

Good search queries:
- `"qwen3 coder" new model release 2025`
- `deepseek r2 release ollama`
- `llama 4 ollama available`
- `best local coding LLM 2025 ollama`
- `mistral devstral ollama 2025`

**Ollama Hub search:**

Use the Ollama search API or web search to find the latest tags for models already in the stack:

```shell
# Check for newer tags on a model
curl -s "https://ollama.com/library/qwen2.5-coder/tags" 2>/dev/null | head -100
# or
ollama search qwen3-coder 2>/dev/null | head -20
```

**HuggingFace search (if HuggingFace MCP tools are available):**

Search for trending GGUF models in the categories relevant to the current stack:
- `GGUF coding model trending`
- `GGUF reasoning instruct`
- `GGUF embed`

Look at: download counts in the last 30 days, likes, and whether unsloth/bartowski/lmstudio-community
have made GGUF conversions (these are the standard quantization providers used in `models.sh`).

### Step 4 — Check llmfit compatibility

If `llmfit` is available (check with `which llmfit`), use it to verify that suggested new models
actually fit in the target machine's RAM before recommending them:

```shell
llmfit model <model-name>
```

If llmfit isn't installed, estimate from publicly listed model sizes (parameter count × bytes per
parameter at the target quantization):

| Quant | Bytes/param approx |
|-------|---------------------|
| Q4_K_M | 0.5 |
| Q5_K_M | 0.625 |
| Q6_K | 0.75 |
| Q8_0 | 1.0 |
| F16 | 2.0 |

A 30B model at Q5_K_M ≈ 30B × 0.625 ≈ 18.75 GB loaded weight, plus ~2 GB Ollama overhead.

### Step 5 — Produce the recommendation report

Write a focused report. Do not overwhelm — if nothing meaningful has changed, say so directly.

---

## Report Format

```
## Model Update Report — [date]

### Profile: [profile-name]

#### ✅ Current models looking good
- model-name: still competitive, no significant replacement available

#### 🔄 Suggested upgrades
- **[role]**: replace `current-model` → `new-model`
  - Why: [brief reason — benchmark improvement, newer architecture, smaller size]
  - Size: [estimated RAM footprint]
  - Pull: `ollama pull new-model` or custom model Modelfile entry

#### 🆕 New models worth evaluating
- **model-name** ([size], [quant])
  - Best for: [role]
  - Context window: [tokens]
  - Why notable: [one sentence]
  - Fits in [X]GB RAM: yes/no

#### ❌ Models to consider retiring
- **model-name**: superseded by [newer model], no longer maintained upstream

### Sources
- [link 1]
- [link 2]
```

Keep each entry to 2–3 lines. Link sources so the user can verify.

---

## Guardrails

- Only suggest models that have GGUF weights available on Ollama Hub or HuggingFace. Do not suggest
  models that require GPU-only inference (FP16, bfloat16 without GGUF) unless the user has a
  dedicated GPU machine.
- Prefer models with unsloth, bartowski, or lmstudio-community GGUF conversions — these are
  tested and commonly used.
- If a custom model alias in `CUSTOM_MODELS_*` would need to be updated (new base URL on
  HuggingFace), provide the exact new `hf.co/` pull path in the format the Modelfile uses.
- Do not suggest models larger than ~80% of the profile's total RAM. Leave headroom for the OS
  and other tools.
- Flag speculative releases (announced but not yet available on Ollama Hub) clearly as
  "not yet pullable".

---

## Follow-up actions

After presenting the report, offer to:

1. Update `config/models.sh` with the suggested changes (show a diff first, get approval).
2. Write new Modelfile entries in `config/scripts/modelfiles/` for any custom GGUF aliases.
3. Run `llmfit` on each candidate if the tool is available.
4. Pull the new models immediately: `bash config/install_models.sh <profile>`.
