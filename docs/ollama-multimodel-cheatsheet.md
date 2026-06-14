---
tags: [ai, ollama, reference, cheatsheet]
---

# Ollama Multi-Model Cheat Sheet — M5 Max 64GB

Step-by-step guide: HuggingFace → `ollama create` → concurrent loading.  
Follow sections in order. Every command is copy-pasteable.

---

## Part 1 — Ollama Environment (Concurrent Loading Config)

Ollama holds models in unified memory between requests. With no configuration it
evicts after 5 minutes of inactivity and only loads 1 model at a time by default.
These env vars unlock true multi-model resident behaviour.

### Env vars to set

| Variable | Value | Effect |
| --- | --- | --- |
| `OLLAMA_MAX_LOADED_MODELS` | `3` | Keep up to 3 models in memory simultaneously |
| `OLLAMA_FLASH_ATTENTION` | `1` | Metal flash-attention — cuts KV cache memory ~3× |
| `OLLAMA_NUM_PARALLEL` | `1` | One generation at a time per model (keeps GPU coherent) |
| `OLLAMA_KEEP_ALIVE` | `30m` | Hold a model 30 min after last use before unloading |

> **`OLLAMA_KV_CACHE_TYPE`** (q4_0/q8_0) — available in Ollama 0.5+. On 0.30.0 it
> is silently ignored. Upgrade to unlock it; it can halve KV memory again.

### Make these permanent — LaunchAgent setenv plist

Create `~/Library/LaunchAgents/com.kehle.ollama-env.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.kehle.ollama-env</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/sh</string>
        <string>-c</string>
        <string>
            launchctl setenv OLLAMA_MAX_LOADED_MODELS 3;
            launchctl setenv OLLAMA_FLASH_ATTENTION 1;
            launchctl setenv OLLAMA_NUM_PARALLEL 1;
            launchctl setenv OLLAMA_KEEP_ALIVE 30m
        </string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

Load it immediately (then it auto-loads at every login):

```shell
launchctl load ~/Library/LaunchAgents/com.kehle.ollama-env.plist
brew services restart ollama
```

Verify:

```shell
launchctl getenv OLLAMA_MAX_LOADED_MODELS   # → 3
launchctl getenv OLLAMA_FLASH_ATTENTION     # → 1
```

---

## Part 2 — HuggingFace → `ollama create` Reference Guide

**The rule:** Always use `FROM hf.co/<repo>:<filename>` in Modelfiles — never
`FROM /path/to/file.gguf`. The HF reference preserves the Jinja2 chat template
embedded in the GGUF metadata. Bare paths strip it and break tool-calling.

**Re-download behaviour:** If the GGUF blob already exists in Ollama's cache
(`~/.ollama/models/blobs/`), Ollama uses it instantly — no re-download. If it
exists only in `/usr/local/lib/llama-models/` (llama-router copy) but NOT in
Ollama's cache, Ollama fetches from HF to its own cache.

---

### 2a — Models to re-register (already on machine, broken templates)

#### `qwen2.5:32b` — BROKEN, fix first

Template is `{{ .Prompt }}` — zero tool-calling. HF blob already in Ollama cache.
Re-registration is instant (no download).

```shell
# 1. Remove broken alias
ollama rm qwen2.5:32b

# 2. Re-create from HF reference (uses cached blob)
cat > /tmp/opus.Modelfile << 'EOF'
FROM hf.co/hesamation/Qwen2.5-32B-Instruct-GGUF:Qwen2.5-32B-Instruct.Q4_K_M.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0.6
EOF
ollama create qwen2.5:32b -f /tmp/opus.Modelfile

# 3. Verify template is restored
ollama show qwen2.5:32b --modelfile | grep -c tool_call
# Must return > 5. If 0, template is still broken.

# 4. Recreate context variants (template inherits from base)
for ctx_k in 8 32 128 256; do
  cat > /tmp/opus-ctx.Modelfile << EOF
FROM qwen2.5:32b
PARAMETER num_ctx $((ctx_k * 1024))
PARAMETER temperature 0.6
EOF
  ollama create "qwen2.5:32b-${ctx_k}k" -f /tmp/opus-ctx.Modelfile
done

rm /tmp/opus.Modelfile /tmp/opus-ctx.Modelfile
```

---

#### `deepseek-r1-tools:32b` — verify, re-register if needed

```shell
# Check if tool-calling template is intact
ollama show deepseek-r1-tools:32b --modelfile | grep -c tool_call
# If > 0: skip this section. If 0: run the block below.

# Re-register from MFDoom (this IS the tool-calling community build)
ollama rm deepseek-r1-tools:32b
ollama pull MFDoom/deepseek-r1-tool-calling:32b    # ~19 GB — downloads if not cached

cat > /tmp/r1tools.Modelfile << 'EOF'
FROM MFDoom/deepseek-r1-tool-calling:32b
PARAMETER num_ctx 131072
PARAMETER temperature 0.3
EOF
ollama create deepseek-r1-tools:32b -f /tmp/r1tools.Modelfile

# Context variants
for ctx_k in 8 32 128; do
  cat > /tmp/r1-ctx.Modelfile << EOF
FROM deepseek-r1-tools:32b
PARAMETER num_ctx $((ctx_k * 1024))
PARAMETER temperature 0.3
EOF
  ollama create "deepseek-r1-tools:32b-${ctx_k}k" -f /tmp/r1-ctx.Modelfile
done

rm /tmp/r1tools.Modelfile /tmp/r1-ctx.Modelfile
```

---

#### `qwen3-coder-30b-a3b:q6` — verify template (should already be OK)

```shell
ollama show qwen3-coder-30b-a3b:q6 --modelfile | grep -c tool_call
# Should return 5. If not, re-register:

cat > /tmp/coder.Modelfile << 'EOF'
FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0
PARAMETER repeat_penalty 1.05
EOF
ollama rm qwen3-coder-30b-a3b:q6
ollama create qwen3-coder-30b-a3b:q6 -f /tmp/coder.Modelfile   # Will re-download ~26 GB if not cached

# Context variants (always from base to inherit template)
for ctx_k in 8 16 32 64 128 256; do
  cat > /tmp/coder-ctx.Modelfile << EOF
FROM qwen3-coder-30b-a3b:q6
PARAMETER num_ctx $((ctx_k * 1024))
PARAMETER temperature 0
PARAMETER repeat_penalty 1.05
EOF
  ollama create "qwen3-coder-30b-a3b:q6-${ctx_k}k" -f /tmp/coder-ctx.Modelfile
done

rm /tmp/coder.Modelfile /tmp/coder-ctx.Modelfile
```

---

#### `qwen3.5-27b:q4` — verify (should already have proper Jinja2 template)

```shell
ollama show "qwen3.5-27b:q4" --modelfile | grep -c tool_call
# Should return 5+. If 0, re-register:

cat > /tmp/writer.Modelfile << 'EOF'
FROM hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF:Qwen3.5-27B.Q4_K_M.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0.6
EOF
ollama rm "qwen3.5-27b:q4"
ollama create "qwen3.5-27b:q4" -f /tmp/writer.Modelfile   # ~17 GB if not cached

for ctx_k in 8 32 128 256; do
  cat > /tmp/writer-ctx.Modelfile << EOF
FROM qwen3.5-27b:q4
PARAMETER num_ctx $((ctx_k * 1024))
PARAMETER temperature 0.6
EOF
  ollama create "qwen3.5-27b:q4-${ctx_k}k" -f /tmp/writer-ctx.Modelfile
done

rm /tmp/writer.Modelfile /tmp/writer-ctx.Modelfile
```

---

### 2b — New models to pull (first time, from official library)

#### `qwen2.5:32b` — NEW, official Ollama library (24 GB download)

Best local agentic coding model as of June 2026 (73.4% SWE-bench Verified).
Proper templates and tool support from the library. Use this alongside or
instead of the Claude-distill GGUF.

```shell
ollama pull qwen2.5:32b          # 24 GB — Q4_K_M by default, 256K context, vision+tools

# Context variant for co-resident use (smaller KV, saves ~12 GB at 256K vs 32K)
cat > /tmp/qwen36-32k.Modelfile << 'EOF'
FROM qwen2.5:32b
PARAMETER num_ctx 32768
EOF
ollama create qwen2.5:32b-32k -f /tmp/qwen36-32k.Modelfile

cat > /tmp/qwen36-128k.Modelfile << 'EOF'
FROM qwen2.5:32b
PARAMETER num_ctx 131072
EOF
ollama create qwen2.5:32b-128k -f /tmp/qwen36-128k.Modelfile

rm /tmp/qwen36-32k.Modelfile /tmp/qwen36-128k.Modelfile
```

---

#### `laguna-xs.2` — Optional agentic coder (23 GB download)

Purpose-built agentic coding model (68.2% SWE-bench Verified, 33B MoE / 3B
activated). FP8 KV cache, interleaved thinking+tool-calling. Fits alongside
write/plan models.

```shell
ollama pull laguna-xs.2          # 23 GB — Q4_K_M, 128K context

# For co-resident use
cat > /tmp/laguna-32k.Modelfile << 'EOF'
FROM laguna-xs.2
PARAMETER num_ctx 32768
EOF
ollama create laguna-xs.2:32k -f /tmp/laguna-32k.Modelfile
rm /tmp/laguna-32k.Modelfile
```

---

### 2c — Small models (official library pulls, no Modelfile needed)

```shell
# Plan / routing — always-on
ollama pull qwen3:4b

# Summary / title — always-on  
ollama pull qwen3.5:4b              # Uses RENDERER qwen3.5 (architecture-native)

# Autocomplete — tiny, always-on
ollama pull qwen2.5-coder:1.5b

# Embeddings — tiny, always-on
ollama pull nomic-embed-text
```

---

## Part 2d — Restoring Distill Models with Correct Templates

Community GGUF distills (Claude Opus/Sonnet, Gemini reasoning distills) don't embed
chat templates in their GGUF metadata. Ollama falls back to `TEMPLATE {{ .Prompt }}`,
breaking tool-calling. The fix: inject the official base model's template explicitly.

The distill and its base share the same architecture and tokenizer, so the base
model's template is fully compatible with the distill's weights.

```shell
# Pattern: extract template from official library model, overlay on distill GGUF
TEMPLATE=$(ollama show <base-library-model> --template 2>/dev/null)

cat > /tmp/distill.Modelfile << EOF
FROM hf.co/<hf-repo>:<gguf-filename>
TEMPLATE """${TEMPLATE}"""
PARAMETER num_ctx 32768
PARAMETER temperature 0.6
EOF

ollama rm <alias>
ollama create <alias> -f /tmp/distill.Modelfile
rm /tmp/distill.Modelfile

# Verify template was applied
ollama show <alias> --modelfile | grep -c tool_call   # must be > 0
```

### Template source map

| Distill alias | HF source | Base template source |
| --- | --- | --- |
| `qwen2.5:32b-distill` | `hf.co/hesamation/Qwen2.5-32B-Instruct-GGUF` | `qwen2.5:32b` |
| `qwen3.6-27b:opus-sonnet` | `hf.co/Brian6145/Qwen3.6-27B-Claude-Opus-Sonnet-DistilledV2-MTP-GGUF` | `qwen3.6:27b` |
| `qwen3.5-27b:gemini3.1` | `hf.co/Jackrong/Qwen3.5-27B-Gemini-3.1-Pro-Reasoning-Distill-GGUF` | `qwen3.5:27b` |
| `qwen3-14b:sonnet4.5` | `hf.co/TeichAI/Qwen3-14B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF` | `qwen3:14b` |
| `qwen3-8b:sonnet4.5` | `hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF` | `qwen3:8b` |

> `qwen3.5-27b:q4` already has a proper template (7 tool refs) and does NOT need this fix.
> Use a distinct alias like `qwen2.5:32b-distill` to keep it alongside the library version.

---

## Part 3 — Concurrent Loading Memory Budget

**Usable memory:** ~54 GB (64 GB − 6 GB macOS − 4 GB Ollama overhead)

Memory occupied = model weights + KV cache.  
With `OLLAMA_FLASH_ATTENTION=1`, KV cache at 32K context ≈ 0.5–1 GB per model.

### Weight reference table

| Model | Weights | @ 32K KV (FA=1) | @ 128K KV (FA=1) | @ 256K KV (FA=1) |
| --- | --- | --- | --- | --- |
| `qwen3-coder-30b-a3b:q6` | 26 GB | 27 GB | 29 GB | 33 GB |
| `qwen2.5:32b` (library) | 24 GB | 25 GB | 27 GB | 31 GB |
| `qwen2.5:32b` (distill) | 21 GB | 22 GB | 24 GB | 28 GB |
| `deepseek-r1-tools:32b` | 19 GB | 20 GB | 22 GB | — |
| `laguna-xs.2` | 23 GB | 24 GB | 26 GB | — |
| `qwen3.5-27b:q4` | 17 GB | 18 GB | 20 GB | 23 GB |
| `qwen3:4b` | 2.5 GB | 3 GB | 3.5 GB | — |
| `qwen3.5:4b` | 2.9 GB | 3.4 GB | — | — |
| `qwen2.5-coder:1.5b` | 0.9 GB | 1 GB | — | — |
| `nomic-embed-text` | 0.3 GB | 0.3 GB | — | — |

---

### Co-resident configurations

#### Tier 0 — Always-on baseline (31 GB)

Always resident. Lightweight enough to stay loaded 24/7.

```text
qwen3-coder-30b-a3b:q6-32k   27 GB   code / primary agent
qwen3:4b-8k                   3 GB   plan / routing
qwen2.5-coder:1.5b            1 GB   autocomplete (FIM)
nomic-embed-text              0.3 GB  embeddings
─────────────────────────────────────
                              ≈ 31 GB  ✅ 57% of usable
```

---

#### Tier 1 — Standard dev mode (34 GB)

Add summary model for commit messages and titles.

```text
qwen3-coder-30b-a3b:q6-32k   27 GB   code / build agents
qwen3.5:4b                    3.4 GB  summary / title agents
qwen3:4b-8k                   3 GB   plan agent
qwen2.5-coder:1.5b            1 GB   autocomplete
nomic-embed-text              0.3 GB  embeddings
─────────────────────────────────────
                              ≈ 35 GB  ✅ 65% of usable
```

---

#### Tier 2 — Research / write mode (48 GB)

Heavy writing and research. Coder stays resident for context switching.

```text
qwen3-coder-30b-a3b:q6-32k   27 GB   code agent
qwen3.5-27b:q4-32k           18 GB   write / research agents
qwen3:4b-8k                   3 GB   plan agent
─────────────────────────────────────
                              ≈ 48 GB  ✅ 89% of usable
```

> ⚠️ Load autocomplete separately before this tier — it'll be evicted when
> `qwen3.5-27b:q4` loads if `OLLAMA_MAX_LOADED_MODELS=3` is already full.

---

#### Tier 3 — Think / reasoning mode (50 GB)

Deep analysis and tool-calling reasoning. Evicts write model.

```text
qwen3-coder-30b-a3b:q6-32k   27 GB   code / build agents
deepseek-r1-tools:32b-32k    20 GB   think agent (reasoning + tools)
qwen3:4b-8k                   3 GB   plan agent
─────────────────────────────────────
                              ≈ 50 GB  ✅ 93% of usable
```

---

#### Tier 4 — Full architect pipeline (52 GB) ⚠️ tight

Coder + architect on the same machine. Use -32k context variants only.

```text
qwen3-coder-30b-a3b:q6-32k   27 GB   code agent
qwen2.5:32b-32k              25 GB   architect / opus agent
qwen3:4b-8k                   3 GB   plan agent
─────────────────────────────────────
                              ≈ 55 GB  ⚠️ ~102% of usable
```

> Architect + coder simultaneously is marginal at 64 GB. Ollama will likely
> manage it via swapping. For reliable operation, run them sequentially or
> upgrade context to keep KV below 1 GB each.

---

#### Which context variant to use per load tier

| Tier | Coder ctx | Architect ctx | Think ctx | Write ctx |
| --- | --- | --- | --- | --- |
| 0 — baseline | 32K | — | — | — |
| 1 — dev | 32K | — | — | — |
| 2 — research | 32K | — | — | 32K |
| 3 — think | 32K | — | 32K | — |
| 4 — architect | 32K | 32K | — | — |
| Solo (debug big) | 128K | 128K | 128K | 256K |

Use `-NNNk` tagged variants for multi-model tiers, base tags for solo runs.

---

## Part 4 — OpenCode Agent Fixes

After re-registering models, update `opencode.jsonc`:

### Issue 1: `maxTokens: 1024` truncates code output — remove it

The code and local agents have `"maxTokens": 1024`. This is causing the "Mo"
truncation. Remove these lines entirely (the model's context window governs
max output size instead).

```jsonc
// Remove or comment out in the code and local agents:
// "maxTokens": 1024,

// write agent: raise from 2048 to 4096
"maxTokens": 4096,
```

### Issue 2: write/research agents — use proven 27B model

```jsonc
// Change from:
"model": "ollama/qwen3-14b:sonnet4.5",

// To:
"model": "ollama/qwen3.5-27b:q4",
```

### Issue 3: think agent — switch to tools version

```jsonc
// Change from:
"model": "ollama/deepseek-r1:32b",

// To:
"model": "ollama/deepseek-r1-tools:32b",
```

### Quick diff summary

| Agent | Before | After |
| --- | --- | --- |
| `code` | `maxTokens: 1024` | remove limit |
| `local` | `maxTokens: 1024` | remove limit |
| `write` | `maxTokens: 2048` + `qwen3-14b:sonnet4.5` | `maxTokens: 4096` + `qwen3.5-27b:q4` |
| `research` | `qwen3-14b:sonnet4.5` | `qwen3.5-27b:q4` |
| `think` | `deepseek-r1:32b` | `deepseek-r1-tools:32b` |

---

## Part 5 — Validation Checklist

Run these after completing setup. Every check must pass before trusting agents.

**Note on template types:** Ollama has two valid tool-calling modes:
- **Jinja2 template** — explicit `ToolCalls`/`tool_call` tokens in the template text
- **Architecture-native** — `RENDERER qwen3.5` / `PARSER qwen3.5` directives; Ollama handles
  tool formatting internally — no template tokens needed. Same quality, different mechanism.

`deepseek-r1:32b` and `nomic-embed-text` intentionally have no tool support (pure reasoning / embeddings).

```shell
# 1. Env vars are set
launchctl getenv OLLAMA_MAX_LOADED_MODELS   # → 3
launchctl getenv OLLAMA_FLASH_ATTENTION     # → 1

# 2. Full template health check (handles both Jinja2 and RENDERER models)
for model in qwen3-coder-30b-a3b:q6 qwen2.5:32b qwen2.5:32b \
             qwen3.5-27b:q4 deepseek-r1-tools:32b qwen3:4b qwen3.5:4b \
             qwen2.5-coder:1.5b qwen2.5-coder:7b nomic-embed-text; do
  mf=$(ollama show "$model" --modelfile 2>/dev/null)
  if echo "$mf" | grep -q "RENDERER\|PARSER"; then
    echo "✅ $model → architecture-native"
  elif echo "$mf" | grep -cE "ToolCalls|tool_call" | grep -qv "^0$"; then
    echo "✅ $model → Jinja2 tools"
  elif echo "$model" | grep -qE "embed|deepseek-r1:32b"; then
    echo "✅ $model → no tools needed"
  else
    echo "❌ $model → BROKEN"
  fi
done

# 3. Context variants for multi-model tiers
for v in qwen3-coder-30b-a3b:q6-32k qwen2.5:32b-32k \
         qwen3.5-27b:q4-32k deepseek-r1-tools:32b-32k qwen3:4b-8k; do
  ollama list 2>/dev/null | awk '{print $1}' | grep -qx "$v" \
    && echo "✅ $v" || echo "❌ $v MISSING"
done

# 4. Memory check — load tier 1 baseline (should fit in 35 GB)
ollama run --nowordwrap qwen3-coder-30b-a3b:q6-32k "say hi"
ollama run --nowordwrap qwen3.5:4b "say hi"
ollama run --nowordwrap qwen3:4b-8k "say hi"
ollama ps   # Should show 3 models loaded
```

---

## Part 6 — Cleanup: Off-Profile Models to Remove

These models are NOT in the profile and collectively waste ~50 GB of disk:

```shell
# Confirm what disk they use first
ollama list | grep -E "phi4|alpie-core|qwen35-27b:opus-agent|qwen3.5-4b:opus-distill|qwen3-8b:sonnet4.5-distill"

# Remove after confirming nothing depends on them
ollama rm phi4:latest
ollama rm phi4-mini:latest
ollama rm alpie-core:latest
ollama rm "169pi/alpie-core:latest"
ollama rm "qwen35-27b:opus-agent"
ollama rm "qwen3.5-4b:opus-distill-v2"
ollama rm "qwen3-8b:sonnet4.5-distill"

# The 80B coder takes 48 GB but is solo-only — remove in favour of qwen2.5:32b
ollama rm "qwen3-coder-next-80b:q4"
ollama rm "qwen3-coder-next-80b:q4-8k"
ollama rm "qwen3-coder-next-80b:q4-16k"
ollama rm "qwen3-coder-next-80b:q4-32k"
ollama rm "qwen3-coder-next-80b:q4-64k"
ollama rm "qwen3-coder-next-80b:q4-128k"
ollama rm "qwen3-coder-next-80b:q4-256k"
# The GGUF on disk is separate — optionally:
# rm /usr/local/lib/llama-models/qwen3-coder-next-80b-cd-q4_k_m.gguf   # frees ~48 GB on disk
```

---

## Part 7 — Mac Mini M2 16GB: Hermes Client Config

### Goal

The Mac Mini cannot run meaningful local inference (≤10 GB usable).  
Configure it as a **Hermes remote client** pointing at the M5 Max's Ollama.

### Prerequisites on M5 Max

```shell
# Allow Ollama to accept connections from LAN (not just localhost)
launchctl setenv OLLAMA_HOST 0.0.0.0:11434
brew services restart ollama

# Confirm the M5 Max's LAN IP
ipconfig getifaddr en0    # e.g. 192.168.1.50
```

### On Mac Mini — update Hermes

```shell
# Update Hermes first (1267 commits behind)
hermes update

# Verify version after update
hermes --version
```

### On Mac Mini — `~/.hermes/config.yaml`

Change `base_url` to point at M5 Max and update model:

```yaml
model:
  default: qwen3-coder-30b-a3b:q6     # served by M5 Max
  provider: ollama-remote
  base_url: http://192.168.1.50:11434/v1   # ← M5 Max LAN IP

# Cloud fallback when M5 Max is offline
fallback_providers:
  - name: openrouter
    base_url: https://openrouter.ai/api/v1
    default_model: anthropic/claude-sonnet-4-6
```

> Replace `192.168.1.50` with actual M5 Max LAN address (from `ipconfig getifaddr en0`).
> If both machines are on Tailscale, use the Tailscale IP instead.

### On Mac Mini — local-only models (if Ollama runs locally at all)

Only keep tiny models that fit in 10 GB:

```shell
# Keep only these two locally on the Mini:
ollama pull qwen3:4b          # 2.5 GB — fast local planning
ollama pull qwen2.5-coder:1.5b  # 0.9 GB — autocomplete (FIM)

# Remove everything else that is not a tiny model
# Big inference routes to M5 Max
```

### The profile stub at `ai/profiles/default/hermes/config.toml`

⚠️ The file at `ai/profiles/default/hermes/config.toml` uses the wrong format
(TOML, wrong model name). The real Hermes config is YAML at `~/.hermes/config.yaml`.
The TOML stub can be updated but is not read by Hermes directly.

---

## Quick Reference Card

```text
┌─────────────────────────────────────────────────────────────────┐
│  OLLAMA MULTI-MODEL QUICK CARD — M5 Max 64GB                    │
├─────────────────────────────────────────────────────────────────┤
│  ENV VARS (set once, then restart ollama):                       │
│    OLLAMA_MAX_LOADED_MODELS=3                                    │
│    OLLAMA_FLASH_ATTENTION=1                                      │
│    OLLAMA_KEEP_ALIVE=30m                                         │
├─────────────────────────────────────────────────────────────────┤
│  MODEL STACK vs USABLE 54 GB:                                    │
│    coder  qwen3-coder-30b-a3b:q6     26 GB   always-on          │
│    arch   qwen2.5:32b (library)      24 GB   on-demand          │
│    write  qwen3.5-27b:q4            17 GB   on-demand          │
│    think  deepseek-r1-tools:32b     19 GB   on-demand          │
│    plan   qwen3:4b                   2.5 GB  always-on          │
│    sum    qwen3.5:4b                 2.9 GB  always-on          │
│    auto   qwen2.5-coder:1.5b         0.9 GB  always-on          │
│    embed  nomic-embed-text           0.3 GB  always-on          │
├─────────────────────────────────────────────────────────────────┤
│  SAFE CONCURRENT COMBOS (use -32k variants):                     │
│    ✅  coder(27) + plan(3) + auto(1) = 31 GB  ← default          │
│    ✅  coder(27) + write(18) + plan(3)= 48 GB  ← research        │
│    ✅  coder(27) + think(20) + plan(3)= 50 GB  ← analysis        │
│    ⚠️  coder(27) + arch(25) + plan(3) = 55 GB  ← use -32k only  │
│    ❌  coder + arch + think (69 GB)           ← never            │
├─────────────────────────────────────────────────────────────────┤
│  CONTEXT VARIANT RULE:                                           │
│    Multi-model tiers → use -32k variants                        │
│    Solo (one big model) → use -128k or -256k                    │
├─────────────────────────────────────────────────────────────────┤
│  HF → OLLAMA CREATE RULE:                                        │
│    Always: FROM hf.co/<repo>:<filename>   ← keeps template      │
│    Never:  FROM /path/to/file.gguf        ← breaks tool-calling │
├─────────────────────────────────────────────────────────────────┤
│  VERIFY TEMPLATE HEALTH:                                         │
│    ollama show <model> --modelfile | grep -c tool_call           │
│    → >= 5: full tool support                                     │
│    → 0:    broken (re-register with hf.co)                      │
└─────────────────────────────────────────────────────────────────┘
```

---

_Generated: 2026-06-11_  
_Profile: macbook-m5-64gb_  
_Status: Planning — no changes made yet_
