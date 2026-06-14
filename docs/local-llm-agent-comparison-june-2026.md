---
tags: [ai, ollama, review, planning]
---

# Local LLM Agent Configuration Review — June 2026

**Machine:** MacBook Pro M5 Max 64GB
**Secondary:** Mac Mini M2 16GB (Hermes client target)
**Context:** Local LLM agents are NOT working as expected. This document compares current reality to the profile spec, identifies gaps, and proposes a remediation plan.

---

## TL;DR

Three root causes are killing local agent quality:

1. **`qwen2.5:32b` (the Opus/Architect model) is STILL broken** — `TEMPLATE {{ .Prompt }}` means zero tool-calling. The docs claim it was fixed on 2026-06-09 but the actual machine state proves otherwise.
2. **`maxTokens: 1024` in opencode.jsonc** is far too low for a coding agent, causing truncated responses.
3. **Model-map drift**: `model-map.md` disagrees with `opencode.jsonc` on which model handles `think`, `write`, and `research` — the profile source of truth is broken.

---

## 1. Template Audit — Current Machine State

| Model                     | Current Template             | Tool Support              | Profile Expects    | Status                                           |
| ------------------------- | ---------------------------- | ------------------------- | ------------------ | ------------------------------------------------ |
| `qwen3-coder-30b-a3b:q6`  | Jinja2 (5 tool_call refs)    | ✅ Full                   | Code/Primary agent | ✅ OK                                            |
| `qwen3.5-27b:q4`          | Jinja2 (5 tool_call refs)    | ✅ Full                   | Write/Research     | ✅ OK                                            |
| `qwen3:4b`                | Jinja2 (31 lines)            | ✅ Full                   | Plan agent         | ✅ OK                                            |
| `qwen3.5:4b`              | `RENDERER qwen3.5`           | ✅ Native                 | Summary/Title      | ✅ OK                                            |
| `qwen2.5-coder:7b`        | Jinja2 (35 lines)            | ✅ Full                   | Autocomplete       | ✅ OK                                            |
| `qwen2.5-coder:1.5b`      | Jinja2                       | ✅ Full                   | Autocomplete       | ✅ OK                                            |
| `deepseek-r1:32b`         | 10-line minimal, no tools    | ⚠️ None                   | Think/Reasoning    | ⚠️ Expected (no tools needed for pure reasoning) |
| `deepseek-r1-tools:32b`   | MFDoom template              | ⚠️ 0 tool_call refs found | Reasoning+tools    | ❓ Suspect — needs re-test                       |
| `qwen3-14b:sonnet4.5`     | Jinja2 (20+ lines)           | ✅ Partial                | Write/Research     | ✅ OK                                            |
| **`qwen2.5:32b`** | **`TEMPLATE {{ .Prompt }}`** | **❌ NONE**               | **Architect/Opus** | **🔥 BROKEN**                                    |
| `qwen3.5-27b:gemini3.1`   | minimal                      | ❌ None                   | (unused in agents) | ⚠️ Low priority                                  |
| `codestral:22b`           | minimal                      | ❌ None                   | Apply/Insert       | ⚠️ Expected (FIM, no tools needed)               |
| `alpie-core:latest`       | 10-line minimal              | ⚠️ None                   | Not in profile     | ❓ Untracked                                     |

**Key finding:** Despite docs claiming this was fixed 2026-06-09, `qwen2.5:32b` has `TEMPLATE {{ .Prompt }}` on the live machine. Every tool call from this model narrates JSON as text output instead of executing tools.

---

## 2. OpenCode Config vs. Model Map Drift

The `model-map.md` (generated from `models.sh`) disagrees with `opencode.jsonc` on agent assignments:

| Agent      | `opencode.jsonc` (actual) | `model-map.md` (spec)    | Verdict                                                        |
| ---------- | ------------------------- | ------------------------ | -------------------------------------------------------------- |
| `code`     | `qwen3-coder-30b-a3b:q6`  | `qwen3-coder-30b-a3b:q6` | ✅ Match                                                       |
| `think`    | `deepseek-r1:32b`         | `gemma4:31b`             | ❌ Drift — gemma4 not installed locally, deepseek used instead |
| `write`    | `qwen3-14b:sonnet4.5`     | `qwen3.5-27b:q4`         | ❌ Drift                                                       |
| `research` | `qwen3-14b:sonnet4.5`     | `qwen3.5-27b:q4`         | ❌ Drift                                                       |
| `plan`     | `qwen3:4b`                | `qwen3:4b`               | ✅ Match                                                       |
| `build`    | `qwen3-coder-30b-a3b:q6`  | —                        | —                                                              |
| `summary`  | `qwen3.5:4b`              | —                        | —                                                              |

**gemma4:31b** is listed in `model-map.md` as the `think` model but is NOT installed locally (only `gemma4:31b-cloud` exists — a zero-disk cloud manifest).

---

## 3. OpenCode Config Issues

| Setting                  | Current Value         | Problem                                                                              | Recommendation                                                             |
| ------------------------ | --------------------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------- |
| `code.maxTokens`         | 1024                  | Way too low; coding responses get truncated mid-edit                                 | Remove or set ≥ 8192                                                       |
| `local.maxTokens`        | 1024                  | Same truncation issue                                                                | Remove or set ≥ 8192                                                       |
| `write.maxTokens`        | 2048                  | Low for full documents                                                               | Set to 4096+                                                               |
| `think` model            | `deepseek-r1:32b`     | No tool-calling template — correct for pure reasoning, but agents expect tool output | Keep for reasoning-only; use `deepseek-r1-tools:32b` if tools needed       |
| `research`/`write` model | `qwen3-14b:sonnet4.5` | Sonnet 4.5 distill from TeichAI — partial template, small for writing                | Consider `qwen3.5-27b:q4` (27B, full Jinja2 template, proven tool support) |

---

## 4. Installed vs. Profile — Model Inventory

### Models installed but NOT in profile

| Model                                           | Size      | Issue                                                                                                             |
| ----------------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------- |
| `phi4:latest`                                   | 9.1 GB    | Not in models.json — leftover experiment                                                                          |
| `phi4-mini:latest`                              | 2.5 GB    | Not in models.json — leftover                                                                                     |
| `alpie-core:latest` / `169pi/alpie-core:latest` | 20 GB     | Not in profile — external project model, taking 20 GB                                                             |
| `qwen35-27b:opus-agent`                         | 17 GB     | Not in profile — custom tag for qwen3.5-27b, unclear source                                                       |
| `qwen3-8b:sonnet4.5-distill`                    | 5 GB      | Different tag from `qwen3-8b:sonnet4.5` in profile                                                                |
| `qwen3.5-4b:opus-distill-v2`                    | 2.7 GB    | Not in profile — another 4B distill experiment                                                                    |
| `qwen3-coder-next-80b:q4`                       | **48 GB** | In profile as solo-only model, but occupies nearly ALL RAM — prevents any other model from loading simultaneously |

### Models in profile but potentially underutilized

| Model                   | Profile Role         | Actual Usage             | Note                        |
| ----------------------- | -------------------- | ------------------------ | --------------------------- |
| `gemma4:31b`            | `think` in model-map | ❌ Not installed locally | Only cloud manifest         |
| `deepseek-r1-tools:32b` | Reasoning+tools      | Partially configured     | Needs template verification |
| `qwen2.5:32b`   | Architect/Opus       | ❌ Completely broken     | Fix or replace              |

---

## 5. New Models Available in Ollama Library (June 2026)

These are now in the official Ollama library with proper templates and tool support:

### Strong candidates for M5 Max 64GB

| Model                        | Size  | SWE-Bench          | Notes                                                                                                                                        |
| ---------------------------- | ----- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| **`qwen2.5:32b`**            | 24 GB | **73.4%** Verified | Best local SWE-bench score. Official library = proper template. MoE, vision, tools, 256K ctx. Replaces broken `qwen2.5:32b` distill. |
| **`qwen3.6:27b`**            | 17 GB | High               | Fits alongside coder. 256K ctx, vision, tools.                                                                                               |
| **`laguna-xs.2`**            | 23 GB | 68.2% Verified     | Purpose-built agentic coding, 33B MoE (3B active), efficient KV cache (FP8), interleaved thinking+tools. Apache 2.0.                         |
| `qwen2.5:32b-a3b-mtp-q4_K_M` | 23 GB | Same               | MTP variant (faster inference via multi-token prediction)                                                                                    |

### Context: Current profile model SWE-bench scores (approximate)

| Current Model             | Role              | SWE-bench                          |
| ------------------------- | ----------------- | ---------------------------------- |
| `qwen3-coder-30b-a3b:q6`  | Code primary      | ~60-65% (Qwen3-Coder 30B)          |
| `qwen2.5:32b`     | Architect         | 0% (BROKEN template)               |
| `qwen3-coder-next-80b:q4` | Solo coder        | ~70%+ but 48GB — too memory hungry |
| `qwen2.5:32b` (proposed)  | Architect + Coder | **73.4%**                          |

---

## 6. Mac Mini M2 16GB — Hermes Client Plan

### Current state

- Hermes Agent v0.15.1 is installed on the M5 Max (and likely will be on the Mini)
- **1267 commits behind current** — major update needed
- `~/.hermes/config.yaml` uses `anthropic/claude-opus-4.6` via OpenRouter as default
- The profile's `hermes/config.toml` is an outdated stub (wrong model name `qwen3-coder-30b-a3b:q5`, wrong format — real config is YAML)
- Hermes is officially supported by Ollama: `ollama launch hermes --model <model>`

### Proposed Mac Mini 16GB role: Remote Hermes Client

The 16GB M2 Mac Mini **cannot run productive local inference** for most agentic models (budget ~10GB usable). As a **Hermes client** it should:

1. **Point to M5 Max for Ollama inference** via network (e.g., `http://macbook.local:11434/v1`)
2. **Use OpenRouter for cloud fallback** when M5 Max is unavailable
3. **Light local models only** for autocomplete (if Ollama runs locally at all)

### Mac Mini profile model assignments (as Hermes client)

| Role           | Model                         | Source          |
| -------------- | ----------------------------- | --------------- |
| Primary/Coding | `qwen3-coder-30b-a3b:q6`      | → M5 Max Ollama |
| Think/Reason   | `deepseek-r1-tools:32b`       | → M5 Max Ollama |
| Write/Research | `qwen3.5-27b:q4`              | → M5 Max Ollama |
| Fast/Plan      | `qwen3:4b`                    | → M5 Max Ollama |
| Summary/Title  | `qwen3.5:4b`                  | → M5 Max Ollama |
| Cloud fallback | `anthropic/claude-sonnet-4-6` | OpenRouter      |

### Current `macmini-m2-16gb` profile issues

The current profile is configured as a standalone Ollama server (not a client). Changes needed:

- All agent model assignments should reference the M5 Max Ollama endpoint, not local models
- The Hermes `config.yaml` on the Mini needs `base_url: http://<m5max-ip>:11434/v1`
- Update `models.sh` to reflect remote-backed assignments

---

## 7. Prioritized Remediation Plan

### Immediate (fixes broken agents today)

1. **Re-register `qwen2.5:32b`** with HF reference to restore tool-calling template:

   ```shell
   ollama rm qwen2.5:32b
   cat > /tmp/opus.Modelfile << 'EOF'
   FROM hf.co/hesamation/Qwen2.5-32B-Instruct-GGUF:Qwen2.5-32B-Instruct.Q4_K_M.gguf
   PARAMETER num_ctx 262144
   PARAMETER temperature 0.6
   EOF
   ollama create qwen2.5:32b -f /tmp/opus.Modelfile
   ```

   Then recreate context variants. Verify: `ollama show qwen2.5:32b --modelfile | grep -c tool_call` should return > 5.

2. **Remove `maxTokens: 1024`** from code/local agents in `opencode.jsonc` (or raise to 8192+). This is causing truncated outputs.

3. **Update `opencode.jsonc` research/write agents** from `qwen3-14b:sonnet4.5` → `qwen3.5-27b:q4` (better template, larger model, already proven). Update `think` agent back to `gemma4:31b-cloud` OR install `gemma4:31b` locally (19GB fits alongside 30B coder).

4. **Regenerate `model-map.md`** to match actual `opencode.jsonc`. The current drift between the two causes confusion.

5. **Update Hermes** on M5 Max: `hermes update` (1267 commits behind).

### Short-term (this week — model refresh)

6. **Replace `qwen3-coder-next-80b:q4`** (48 GB, untested for agents) with **`qwen2.5:32b`** (24 GB, 73.4% SWE-bench, official library, proper template). The 80B model occupies nearly all RAM and prevents co-resident models.

7. **Consider `laguna-xs.2`** (23 GB) as an alternative/complement coder. It scores 68.2% on SWE-bench (vs ~60-65% for current Qwen3-Coder), is purpose-built for agentic workflows, uses FP8 KV cache (efficient), and has native interleaved thinking+tool-calling. Fits alongside other models.

8. **Reconfigure `think` agent**: Either:
   - Install `gemma4:31b` locally (19 GB) for local think — best vision+reasoning
   - Or switch to `qwen2.5:32b` which handles both coding and reasoning

9. **Remove or quarantine off-profile models**: `phi4`, `phi4-mini`, `alpie-core`, `qwen35-27b:opus-agent`, `qwen3.5-4b:opus-distill-v2` — these are taking ~50 GB of unexplained disk space. If needed, document them in a separate experimental profile.

### Mac Mini 16GB Hermes client (separate session)

10. **Update Hermes** on Mac Mini.
11. **Update `~/.hermes/config.yaml`** to point to M5 Max Ollama server.
12. **Update the `macmini-m2-16gb` profile** in this repo to reflect its new role as a remote client — remove local-model-first assignments, add remote server URL.
13. **Keep only small local models** if any Ollama runs locally: `qwen3:4b` (2.5 GB) for fast planning, `qwen2.5-coder:1.5b` (986 MB) for autocomplete.

---

## 8. Memory Budget (M5 Max 64GB)

Usable: ~54 GB (64 GB - 6 GB macOS - 4 GB Ollama overhead)

### Current primary stack

| Model                          | Size   | Role           |
| ------------------------------ | ------ | -------------- |
| `qwen3-coder-30b-a3b:q6`       | 26 GB  | Code primary   |
| `qwen2.5:32b` (broken) | 21 GB  | Architect      |
| `qwen3.5-27b:q4`               | 17 GB  | Write/Research |
| `deepseek-r1:32b`              | 19 GB  | Think          |
| `qwen3:4b`                     | 2.5 GB | Plan           |
| `qwen3.5:4b`                   | 2.9 GB | Summary        |
| `qwen2.5-coder:1.5b`           | 0.9 GB | Autocomplete   |
| `nomic-embed-text`             | 0.3 GB | Embeddings     |

Running code + plan + embed concurrently = ~30 GB ✓ (fits)
Running code + think + plan = ~48 GB ⚠️ (tight but OK)

### Proposed improved stack

| Model                    | Size      | Role              | Change                                           |
| ------------------------ | --------- | ----------------- | ------------------------------------------------ |
| `qwen3-coder-30b-a3b:q6` | 26 GB     | Code primary      | Keep                                             |
| **`qwen2.5:32b`**        | **24 GB** | Architect + Think | **Replace** `qwen2.5:32b` + `gemma4:31b` |
| `qwen3.5-27b:q4`         | 17 GB     | Write/Research    | Keep                                             |
| `deepseek-r1-tools:32b`  | 19 GB     | Heavy reasoning   | Keep (after template fix)                        |
| `qwen3:4b`               | 2.5 GB    | Plan              | Keep                                             |
| `qwen3.5:4b`             | 2.9 GB    | Summary           | Keep                                             |
| `qwen2.5-coder:1.5b`     | 0.9 GB    | Autocomplete      | Keep                                             |
| `nomic-embed-text`       | 0.3 GB    | Embeddings        | Keep                                             |

Or alternatively swap code primary to `laguna-xs.2` (23 GB, higher SWE-bench):

| Config       | Coder                | Architect            | Think            | Total resident |
| ------------ | -------------------- | -------------------- | ---------------- | -------------- |
| A (current)  | qwen3-coder-30b (26) | qwen2.5:32b (20)       | deepseek-r1 (19) | ~48 GB         |
| B (fix only) | qwen3-coder-30b (26) | qwen2.5:32b lib (24) | deepseek-r1 (19) | ~49 GB         |
| C (refresh)  | laguna-xs.2 (23)     | qwen2.5:32b lib (24) | deepseek-r1 (19) | ~46 GB         |

Option C gives the best SWE-bench per GB of RAM.

---

## 9. Hermes vs. Other Agents — Agent Quality Context

Hermes is a full agentic framework (Python-based, `~/.hermes/`). It's markedly different from other tools in the stack:

| Tool                    | Type                         | Key strength                                  | Current local model                        |
| ----------------------- | ---------------------------- | --------------------------------------------- | ------------------------------------------ |
| **Hermes Agent**        | Full agent, memory, sessions | Long-running tasks, persistent context, hooks | `anthropic/claude-opus-4.6` via OpenRouter |
| **OpenCode**            | CLI code agent               | Fast coding, multi-file, tool-calling         | `qwen3-coder-30b-a3b:q6`                   |
| **Claude Code / Crush** | CLI code agent               | Cross-platform, strong reasoning              | `qwen3-coder-30b-a3b:q6`                   |
| **Cline / KiloCode**    | VS Code agent                | IDE integration                               | `qwen3-coder-30b-a3b:q6`                   |

Hermes uses cloud by default (Claude Opus 4.6 via OpenRouter) — **it is actually working** using cloud. The "not working" local agents are primarily OpenCode/Claude Code/Cline using the broken `qwen2.5:32b`.

---

## Summary Checklist

```text
Priority 1 — Fixes that break agents today:
  [ ] Re-register qwen2.5:32b with HF reference (restore tool-calling)
  [ ] Remove/raise maxTokens:1024 in opencode.jsonc code/local agents
  [ ] Fix write/research agents to use qwen3.5-27b:q4 (proven template)
  [ ] Regenerate model-map.md to match actual opencode.jsonc

Priority 2 — Model refresh (this week):
  [ ] Pull qwen2.5:32b from library (replace broken opus distill)
  [ ] Evaluate laguna-xs.2 as alternative coder (23 GB, 68.2% SWE-bench)
  [ ] Clean up off-profile models: phi4, alpie-core, qwen35-27b:opus-agent (~50 GB freed)
  [ ] Remove qwen3-coder-next-80b:q4 (48 GB RAM hog, replaced by qwen2.5:32b)
  [ ] Update Hermes: hermes update

Priority 3 — Mac Mini Hermes client:
  [ ] Update macmini-m2-16gb profile to remote-client mode
  [ ] Configure ~/.hermes/config.yaml to point to M5 Max Ollama
  [ ] Keep only qwen3:4b + qwen2.5-coder:1.5b locally on Mini
```

---

_Generated: 2026-06-11_
_Profile: macbook-m5-64gb_
_Status: Planning — no changes made yet_
