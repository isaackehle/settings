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
in `scripts/models.sh`. When a custom GGUF alias changes, this skill keeps two things in sync:

1. `scripts/models.sh` — the `CUSTOM_MODELS_*` source array entries
2. Per-machine `MODELS.md` files — the Model Matrix documentation tables

Custom GGUF aliases are created at install time by `install_custom_models` in `docs/02 - AI/install-models.sh`,
which writes a temp Modelfile, calls `ollama create`, then deletes the temp file. There are no persistent
Modelfile templates — `CUSTOM_MODELS_*` entries in `models.sh` are the single source of truth for the
`source|alias|num_ctx|thinking_mode` tuple.

The goal is not to replace every model on every run — it's to surface meaningful upgrades: a newer
version of something already installed, a new model that beats the current one on the relevant
benchmark, or a smaller model that fits better in available RAM with similar quality.

---

## Workflow

### Step 1 — Read the current model config

Read `scripts/models.sh` from the settings repo. Extract:

- Which hardware profiles exist (m5-48gb, m5-64gb, m1, macmini-m2, etc.)
- Which models are assigned to each profile and role (chat, autocomplete, apply, embed, reasoning)
- Custom model aliases in `CUSTOM_MODELS_*` arrays — note the `source|alias|num_ctx` format:
  - `source` — HuggingFace URL (`hf.co/owner/repo:tag`) or Ollama model ref
  - `alias` — the local Ollama name that will be created (e.g., `qwen3.6-35b-a3b:q5`)
  - `num_ctx` — optional context override (e.g., `32768`); empty means Ollama default

Also read the per-machine `MODELS.md` files (e.g., `scripts/macbook-m5-48gb/MODELS.md`) to understand
what's currently documented as installed and to compare with any discovered upgrades.

If the user specifies a profile, focus there. Otherwise check all profiles.

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

Cross-reference with `models.sh` to identify:

- Models configured but not yet pulled
- Models pulled but no longer referenced (orphans)
- Aliases installed whose source URL no longer matches what's in `models.sh` (drift)

### Step 3 — Search for new releases

Search these sources. Aim for breadth first, then drill into specifics.

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

Use web search to find the latest tags for models already in the stack:

```shell
# Check for newer tags on a model
curl -s "https://ollama.com/library/qwen2.5-coder/tags" 2>/dev/null | head -100
ollama search qwen3-coder 2>/dev/null | head -20
```

**HuggingFace search (if HuggingFace MCP tools are available):**

Search for trending GGUF models:

- `GGUF coding model trending`
- `GGUF reasoning instruct`
- `GGUF embed`

Prefer bartowski or lmstudio-community quantizations (standard llama.cpp format, compatible with
all Ollama versions). Unsloth UD-quants (dynamic mixed-quant) require a recent llama.cpp build
and may be incompatible with older Ollama releases — prefer bartowski Q5_K_M / Q6_K when
in doubt. A new GGUF for an existing model
family (e.g., Q5_K_M → Q6_K) warrants an update to `models.sh` even if the base model hasn't
changed, if the newer quant improves quality or fits better in the target RAM budget.

### Step 4 — Check llmfit compatibility

If `llmfit` is available (`which llmfit`), verify suggested models fit the target RAM:

```shell
llmfit model <model-name>
```

If not installed, estimate from parameter count × bytes per parameter at the target quant:

| Quant  | Bytes/param approx |
| ------ | ------------------ |
| Q4_K_M | 0.5                |
| Q5_K_M | 0.625              |
| Q6_K   | 0.75               |
| Q8_0   | 1.0                |
| F16    | 2.0                |

A 30B model at Q5_K_M ≈ 30B × 0.625 ≈ 18.75 GB + ~2 GB Ollama overhead.

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
  - RAM: [estimated footprint]
  - Changes needed: models.sh · MODELS.md

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

## Applying an upgrade — two files, one change

When the user approves an upgrade, update both in order:

### 1. Update `scripts/models.sh`

Find the relevant `CUSTOM_MODELS_*` array entry and update the source field:

```bash
# Old
"hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL|qwen3-coder-30b-a3b:q5|"

# New
"hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_M|qwen3-coder-30b-a3b:q5|"
```

The install script (`install_custom_models` in `docs/02 - AI/install-models.sh`) builds a temp Modelfile
at runtime and calls `ollama create` — no persistent Modelfile files are stored. After updating
`models.sh`, re-running the installer picks up the change automatically.

The alias name (e.g., `qwen3.6-35b-a3b:q5`) encodes the quant tier — change it when the quant
changes, keep it when only the source URL changes (e.g., same quant, new upstream revision). All
derived aliases (`qwen3.6-35b-32k:q5`, `qwen3.6-35b-220k:q5`) are unaffected unless the base alias
name changes.

If the model architecture or quantization tier changes significantly (e.g., Q5 → Q6 across
a profile bump), also update:

- The alias names to reflect the new quant (`-q5` → `-q6`)
- All derived alias entries in the same array
- The role mapping variables (`CLAUDE_CODE_SONNET_48GB`, `OPENCODE_AGENTS_48GB`, etc.)

### 2. Update the relevant `MODELS.md` matrix

Each machine has a `config/<machine>/MODELS.md` with the Model Matrix table. Update:

- The **Source** row: new HF URL or Ollama model path
- The **RAM loaded** row: if the new quant changes memory footprint
- The **Alias chain** section: if filenames or source URLs changed
- The **Install** section: if the quant tag appears in any code example
- The **`Models last updated:`** header line: bump to today's date (format: `YYYY-MM-DD`)

The matrix table uses model names as column headers — those don't change unless the alias name
changes. If an alias name changes, update the column header and every row that references it.

Always bump the date even for minor source-URL-only changes — the date signals the last time
the installed stack was reviewed and verified, not just when the documentation was touched.

---

## Guardrails

- Only suggest models with GGUF weights on Ollama Hub or HuggingFace. Do not suggest models
  requiring GPU-only inference unless the user has a dedicated GPU machine.
- Prefer unsloth, bartowski, or lmstudio-community GGUF quantizations (standard llama.cpp format). Unsloth
  UD-quants may require a newer llama.cpp than the installed Ollama version supports — call out
  this risk if suggesting a UD-quant.
- `scripts/models.sh` (`CUSTOM_MODELS_*` source fields) is the single source of truth for what
  gets installed. There are no separate Modelfile template files.
- Do not suggest models larger than ~80% of the profile's total RAM.
- Flag speculative releases (announced but not yet pullable) clearly.

---

## Follow-up actions

After presenting the report, offer to:

1. Apply the upgrade (both files — models.sh + MODELS.md, including the `Models last updated:` date) — show a diff first.
2. Run `llmfit` on each candidate if available.
3. Re-run the install: `bash docs/02 - AI/install-models.sh` → select profile.
4. Verify with `ollama list` and `ollama ps` after pulling.
