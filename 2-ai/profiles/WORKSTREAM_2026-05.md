# Workstream Memory — May 2026 Profile Refresh

## What Was Done

This workstream completely overhauled the 5 profile configurations in `2-ai/profiles/`:

### 1. Removed LiteLLM Proxy

**Why:** Ollama's OpenAI-compatible API (`:11434/v1`) is mature enough to replace LiteLLM for all local tooling. Every tool in the stack (OpenCode, Continue, Claude Code, Cline, RooCode, Kilo Code, Aider, Zed, Cursor, Crush, Gemini CLI, Grok CLI) now connects directly to Ollama. Cloud models via OpenRouter provider blocks natively in each tool.

**Result:** No more `uv tool install litellm`, no Postgres container, no venv management, no `:4000` proxy. Zero Python dependencies for the model routing layer.

### 2. Simplified Model Sets

Each profile was analyzed for:
- **Redundancy:** Multiple models covering the same use case (e.g., both gemma4:26b and gemma4:31b, neither used by any agent)
- **Memory feasibility:** Models that can't physically co-exist on the target hardware
- **Critical bugs:** Models referenced in tool configs that can't fit in RAM (e.g., qwen3.5-27b on 16GB machines)

### 3. Model Cuts Per Profile

| Profile | Before | After | Models Cut |
|---------|--------|-------|------------|
| 64GB | ~40 entries | ~11 entries | gemma4:26b, gemma4:31b, gemma3:12b, glm-4.7-flash, phi4, llama3.3:70b, llama3.2, qwen3-14b, qwen3-32b, gpt-oss, non-32B deepseek-r1 variants, qwen2.5-coder-7b-base-q8_0 |
| 48GB | ~38 entries | ~11 entries | Above + qwen3-14b:q8, qwen3.6-35b, codestral-22b:q8 |
| 32GB | ~29 entries | ~9 entries | gpt-oss, non-tools deepseek-r1 variants, codestral:22b |
| 16GB | ~27 entries | ~7 entries | qwen3.5-27b (BUG), qwen3-14b:q8 (BUG), codestral:22b (BUG), gpt-oss:20b (BUG) |
| MacMini 16GB | ~27 entries | ~7 entries | Same as 16GB above |

### 4. Architecture Before/After

```
BEFORE (LiteLLM proxy):
  Tools → :4000 (LiteLLM) → :11434 (Ollama) + OpenRouter

AFTER (Direct):
  Tools → :11434/v1 (Ollama)
  Tools → OpenRouter (native provider blocks)
```

### 5. File Changes

| File | Action |
|------|--------|
| `2-ai/profiles/macbook-m5-64gb/models.sh` | Rewritten: 148 lines (was 234) |
| `2-ai/profiles/macbook-m5-48gb/models.sh` | Rewritten: 150 lines (was 229) |
| `2-ai/profiles/macbook-m2-32gb/models.sh` | Rewritten: 144 lines (was 187) |
| `2-ai/profiles/macbook-m1-16gb/models.sh` | Rewritten: 137 lines (was 181) |
| `2-ai/profiles/macmini-m2-16gb/models.sh` | Rewritten: 136 lines (was 187) |
| `2-ai/profiles/CONFIG_SCHEMA.md` | Rewritten: Post-LiteLLM architecture |
| `2-ai/TOOLS.md` | Updated: Removed all LiteLLM references |
| `2-ai/install-models.sh` | Simplified: Removed pipe/alias logic |
| `2-ai/profiles/prune_models.sh` | Simplified: Removed pipe/alias logic |
| `2-ai/SUGGESTIONS.md` | New: Tooling suggestions |

### 6. Key Naming Convention Change

```
BEFORE:  qwen3-coder-30b-a3b:q6-32k        (Ollama) → qwen3-coder-30b-q6-32k   (LiteLLM)
AFTER:   qwen3-coder-30b-a3b:q5             (Ollama) — same name everywhere
```

No more dual naming schemes. No more `:` → `-` transforms.

### 7. Context Window Variants

Created via Ollama Modelfiles instead of LiteLLM aliasing:

```shell
echo 'FROM qwen3-coder-30b-a3b:q5
PARAMETER num_ctx 32768' > /tmp/Modelfile.32k
ollama create qwen3-coder-30b-a3b:q5-32k -f /tmp/Modelfile.32k
```

These share underlying weights — zero additional disk space.

---

## Recent Updates (post-commit)

### 8. Added MODEL_QUANTS and MODEL_CONTEXTS

All 5 profiles now declare:
- **`MODEL_QUANTS`** — alternative (higher-quality) quants available for hardware that supports them. Install script offers these interactively.
- **`MODEL_CONTEXTS`** — context window variants for each model. Install script auto-creates them via `ollama create` with `PARAMETER num_ctx`. Share weights — zero extra disk.

### 9. Data Layer Cleanup

All `models.sh` files are now pure declarative data — no shebangs, no executable logic. They are **sourced** by scripts, never executed. Install and deploy scripts read these variables to do the actual work.

---

## What Still Needs Work

This commit completes the **data layer** (what models to use). The **execution layer** (how configs get deployed) still needs attention.

### ✅ Priority 1: Fix `setup_ai.sh` infrastructure — DONE

OpenRouter is now recommended for **all** profile classes (was limited to 32GB+). Lightweight/16GB machines also get OpenRouter as part of their recommended infrastructure, since it's just an API key with zero overhead.

`setup_ai.sh` has been scrubbed of all LiteLLM references:

1. ✅ `litellm.sh` sourcing — already removed
2. ✅ LiteLLM removed from `TOOL_GROUPS`, `GROUP_SETUP_FUNCS`, `GROUP_VERIFY_FUNCS` — already done
3. ✅ `litellm` removed from `get_recommended_infrastructure()` — already done
4. ✅ `select_infrastructure()` menu updated — removed vestigial "Local Proxy" option (was LiteLLM), renumbered, changed default from 4→1
5. ✅ `uninstall_infrastructure_component` litellm case — already removed
6. ✅ `copy_file` of litellm config — already removed
7. ✅ Display name updated: `Infrastructure (Ollama + OpenRouter + OpenWebUI)`
8. ✅ Help text for `install:infrastructure` updated to match new architecture
9. ✅ `AGENTS.md` class descriptions updated (LiteLLM → Ollama only)

### ✅ Priority 2: Regenerate pre-built config files — DONE

All 13 tool config file types across all 5 profiles have been scrubbed of LiteLLM references and updated with correct Ollama model names (colon format matching `models.sh`):

| File | Status |
|------|--------|
| `opencode/opencode.jsonc` | ✅ Removed `litellm` provider block, fixed all agent model refs to colon format |
| `continue/config.yaml` | ✅ Removed LiteLLM comments, fixed all model names to colon format, pruned stale entries |
| `claude/settings.json` | ✅ Fixed all model names to colon format matching `models.sh` |
| `ollama/config.json` | ✅ Pruned stale model lists, added context variants from `MODEL_CONTEXTS` |
| `crush/crush.json` | ✅ Fixed model names to colon format, removed stale models |
| `gemini/settings.json` | ✅ Removed `litellm` provider block (3 profiles), fixed model names to colon format |
| `grok/grok.json` | ✅ Fixed base URL to `:11434/v1`, model names to colon format |
| `aider/aider.conf.yml` | ✅ Removed LiteLLM comments, fixed model names to colon format |
| `zed/settings.json` | ✅ Already clean model format, no LiteLLM references found |
| `cline/settings.jsonc` | ✅ Already clean, no changes needed |
| `zoocode/settings.jsonc` | ✅ Fixed model names to colon format |
| `kilocode/kilo.jsonc` | ✅ Removed `litellm` provider, fixed agent model refs |
| `cursor/settings.jsonc` | ✅ Replaced LiteLLM instructions with Ollama instructions |
| `litellm/` directories | ✅ **Deleted** from all 5 profiles |
| Model naming | ✅ All model names use colon format matching Ollama (e.g., `qwen3.5-27b:q5` not `qwen3.5-27b-q5`) |
| Base URLs | ✅ All point to `http://localhost:11434/v1` (Ollama direct, no proxy) |

### ✅ Priority 3: Add missing deployments — DONE

All three missing deployments added to `deploy_configs()` in `setup_ai.sh`:

| Deployment | Status |
|------------|--------|
| `claude/settings.json` → `~/.claude/settings.json` | ✅ Added — simple copy |
| `zoocode/settings.jsonc` → VS Code settings merge | ✅ Added — reusable `_merge_vscode_extension()` helper |
| `roocode/settings.jsonc` → VS Code settings merge | ✅ Added — uses same helper, silently skipped if file missing |
| `cursor/settings.jsonc` → Cursor settings | ✅ Added — stripped of comments, merged into `~/Library/Application Support/Cursor/User/settings.json` |

Also fixed two pre-existing syntax errors in `setup_ai.sh` (stray bare `;;` tokens in the main case block).

### ✅ Priority 4: Tool setup scripts validate against models.sh — DONE

`deploy_configs()` in `setup_ai.sh` now:
- Sources `models.sh` at the start and builds a `_known_models` list from all tool model variables (OPENCODE_AGENTS, CONTINUE_ROLES, CLAUDE_CODE, CLINE_MODEL, etc.)
- Calls `_validate_config_models()` after each config file copy to check that all model references match the source of truth
- Logs warnings for any model name in a config that doesn't appear in `models.sh`, catching drift before it reaches the user

This covers: Continue, OpenCode, Ollama, Crush, Grok, Claude Code, Gemini, Zed, Aider, Kilo Code (all profiles).

### ✅ Priority 5: Remove LiteLLM from tool scripts — DONE

All shell scripts scrubbed. Zero LiteLLM references remain in `2-ai/*.sh` or `setup_ai.sh`.

| Script | Fix |
|--------|-----|
| `gemini.sh` | Removed `litellm --config` command (was pointing at deleted litellm.yaml) |
| `exo.sh` | `LiteLLM base URL` → `Ollama base URL` |
| `openwebui.sh` | Removed LiteLLM connection section (only Ollama direct documented) |
| `open-hands.sh` | `:4000/v1` → `:11434/v1` |
| `open-interpreter.sh` | `:4000/v1` → `:11434/v1` |
| `cline.sh`, `kilocode.sh`, `zed.sh`, `cursor.sh`, `grok.sh` | Already clean |

---

## Model Refresh Cadence

Run this workstream every 3-6 months:
1. Research new model releases (check Ollama library, HuggingFace trending)
2. Evaluate against current profile models — same analysis pattern:
   - Does a new model supersede an existing one?
   - Is each model actually referenced by at least one tool?
   - Can it physically co-exist with the resident set?
3. Update `models.sh`, regenerate config files, prune orphans

### From Scratch (New Machine)

```shell
# 1. Clone settings repo
git clone <repo-url> ~/code/settings
cd ~/code/settings

# 2. Source helpers
source helpers.sh

# 3. Setup Ollama
bash 2-ai/ollama.sh

# 4. Install models for detected profile
# (auto-detects MACHINE_PROFILE from helpers.sh)
bash 2-ai/install-models.sh

# 5. Setup tool configs — each tool deploys its profile-specific config
bash 2-ai/opencode.sh setup
bash 2-ai/claude.sh setup
bash 2-ai/continue.sh setup
# ... etc for each tool
```

### After Future Model Updates

1. Update `models.sh` in the relevant profile — this is the **single source of truth**
2. Update downstream config files (see checklist in `CONFIG_SCHEMA.md`)
3. Pull new models: `bash 2-ai/install-models.sh`
4. Prune orphans: `bash 2-ai/profiles/prune_models.sh <profile>`

### Model Refresh Cadence

Run this workstream every 3-6 months:
1. Research new model releases (check Ollama library, HuggingFace trending)
2. Evaluate against current profile models — same analysis pattern:
   - Does a new model supersede an existing one?
   - Is each model actually referenced by at least one tool?
   - Can it physically co-exist with the resident set?
3. Update `models.sh`, update downstream configs, prune orphans

---

## Current Model Recommendations (May 2026)

| Role | Best Model | Size | Notes |
|------|-----------|------|-------|
| Coding (maximum) | qwen3-coder-next-80b:q4 | 48 GB | Solo only, 80B-A3B with 3B active |
| Coding (practical) | qwen3-coder-30b-a3b:q5 | 21 GB | Co-resident, 3.3B active |
| Newest agentic | qwen3.6-35b:q4 | 22 GB | Thinking preservation, April 2026 release |
| Writing | qwen3.5-27b:q5 | 19 GB | 256K context, 201 languages |
| Reasoning+tools | deepseek-r1-tools:32b | 20 GB | R1 reasoning with function calling |
| Reasoning (14B) | deepseek-r1-tools:14b | 9 GB | For 48GB machines |
| Planning/fast | qwen3.5:4b | 3.4 GB | Vision, tools, 256K — consider replacing qwen3:4b |
| Autocomplete | qwen2.5-coder:1.5b | 1 GB | FIM trained, gold standard |
| Embeddings | nomic-embed-text | 0.3 GB | Proven, widely integrated |
| Apply/insert | codestral:22b | 14 GB | On-demand on ≤48GB, resident on 64GB |

### Recently Released (Consider in Next Refresh)

- **Qwen3.6** (April 2026): Supersedes Qwen3.5 for agentic coding. Thinking preservation across turns. Already in 64GB profile, could replace Qwen3.5 in 48GB profile if benchmarks confirm.
- **Gemma 4** (April 2026): Vision+audio+MoE. 31B hits 85.2% MMLU-Pro, close to frontier. Currently removed as unused, but the 26B MoE (3.8B active) could replace qwen3-14b in 32GB profiles if tool integration is good.
- **DeepSeek-V4-Flash** (April 2026): Cloud only. 1M token context. Worth evaluating for long-context tasks.
- **Llama 4**: Not released yet. Llama 3.3 (70B) remains latest from Meta.
