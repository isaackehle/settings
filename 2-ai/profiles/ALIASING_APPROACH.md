# Aliasing, Quants, and Context Sizes — Recommended Approach

## The Problem

Currently there's a disconnect: `models.sh` defines every model assignment, but most tool setup scripts **never source it**. Instead they rely on pre-built config files that you have to manually keep in sync. This creates drift and makes updates painful.

## Recommended Architecture

### 1. models.sh — Single Source of Truth (already done)

Every profile's `models.sh` defines ALL model assignments. Each tool setup script **must source it** to generate configs.

### 2. Quant Variants — Declare Available Quants

Instead of listing the same model twice with different tags:

```bash
# Current (duplicate entries):
"qwen3:14b"      # ~11 GB | q5
"qwen3:14b"      # ~16 GB | q8
```

Use a dedicated associative array that declares available quantizations per model:

```bash
declare -A MODEL_QUANTS=(
    ["qwen3:14b"]="q5 q8"              # both quants available
    ["qwen3-coder-30b-a3b"]="q5 q6 q8"  # three quants
    ["gemma4:31b"]="q4 q8"             # two quants
)
```

The default quant each tool uses is declared in the tool assignment (it's already there). The install script can offer a menu:

```
  Pull qwen3:14b quants: [default: q5] q5 q8:
  1) q5 only (~11 GB)
  2) q8 only (~16 GB, solo)
  3) Both
  > 1
```

### 3. Context Windown Variants — Auto-Create During Setup

Context variants are created on-the-fly during setup using `ollama create` with `PARAMETER num_ctx`. No more manual Modelfile management.

```bash
# models.sh declares contexts needed per model
declare -A MODEL_CONTEXTS=(
    ["qwen3-coder-30b-a3b:q5"]="8k 32k 128k"   # needs short, medium, long
    ["qwen3.5-27b:q5"]="8k 32k 128k"            # same pattern
    ["codestral:22b"]="32k"                      # one context only
)
```

A helper function in `install-models.sh`:

```bash
create_context_variants() {
    local base_model="$1"
    local contexts="$2"
    for ctx in $contexts; do
        local alias="${base_model}-${ctx}"
        if ! ollama list | grep -q "$alias"; then
            echo "▶ Creating context variant: $alias"
            cat > /tmp/ollama_mf_ctx << EOF
FROM $base_model
PARAMETER num_ctx $ctx
EOF
            ollama create "$alias" -f /tmp/ollama_mf_ctx && rm /tmp/ollama_mf_ctx
        fi
    done
}
```

### 4. Tool Setup Scripts — Source models.sh, Generate Configs

Each tool setup script:

```bash
setup_opencode() {
    # Source profile models (auto-detects machine)
    local profile="${MACHINE_PROFILE}"
    local models_sh="${SETTINGS_BASE}/2-ai/profiles/${profile}/models.sh"
    [[ -f "$models_sh" ]] && source "$models_sh"

    # Generate opencode.jsonc from template, substituting model names
    local template="${SETTINGS_BASE}/2-ai/profiles/${profile}/opencode/opencode.jsonc.template"
    generate_from_template "$template" "$HOME/.config/opencode/opencode.jsonc"
}
```

The template uses placeholders that get substituted:

```jsonc
{
  "model": "ollama/{{OPENCODE_AGENTS[code]}}",
  "small_model": "ollama/{{OPENCODE_AGENTS[plan]}}",
  "agent": {
    "code": { "model": "ollama/{{OPENCODE_AGENTS[code]}}" },
    "think": { "model": "ollama/{{OPENCODE_AGENTS[think]}}" },
    ...
  }
}
```

**But** this adds complexity (template engine, more moving parts). The simpler option is:

**Option B: Pre-built configs, validated at deploy time**

Keep pre-built config files, but have each setup script **load models.sh and validate** that the config references match:

```bash
setup_opencode() {
    source "${SETTINGS_BASE}/2-ai/profiles/${profile}/models.sh"
    local config="${SETTINGS_BASE}/2-ai/profiles/${profile}/opencode/opencode.jsonc"
    # Validate: every model referenced in OPENCODE_AGENTS exists in OLLAMA_MODELS or OPENROUTER_MODELS
    for agent in "${!OPENCODE_AGENTS[@]}"; do
        local model="${OPENCODE_AGENTS[$agent]}"
        validate_model "$model" || echo "⚠ $model referenced by OPENCODE_AGENTS[$agent] not found in OLLAMA_MODELS"
    done
    cp "$config" "$HOME/.config/opencode/opencode.jsonc"
}
```

**Recommendation: Option B (validate, don't generate).** Pre-built configs are easier to read and diff. Validation catches drift. Template generation adds complexity without enough benefit.

### 5. Cloud Models — Single Declaration

Cloud models live in `OPENROUTER_MODELS` (the clean list). The `:cloud` suffix entries in `OLLAMA_MODELS` are documentation-only — the install script already skips them. Keep them as documentation, not as a secondary truth.

### 6. Unified Setup Flow

When `setup_ai.sh deploy` runs, it should:

1. Source the profile's `models.sh`
2. Create context windown variants (`MODEL_CONTEXTS`)
3. Offer to pull missing quants (`MODEL_QUANTS`)
4. Validate each tool config against models.sh
5. Deploy validated configs

## Implementation Priority

1. **Fix tool setup scripts to source models.sh** — the biggest gap
2. **Add MODEL_QUANTS + MODEL_CONTEXTS** — cleaner than duplicate entries
3. **Auto-create context variants during setup** — no more manual Modelfiles
4. **Template generation** — only if pre-built configs keep drifting

## Files That Need Changes

| File | What |
|------|------|
| `install-models.sh` | Add `create_context_variants()`, quant selection menu |
| `setup_ai.sh` | Remove LiteLLM from infrastructure, fix tool groups |
| `cline.sh` | Source models.sh, read CLINE_MODEL_CLOUD |
| `roocode.sh` | Source models.sh, read all 6 ROOCODE vars |
| `kilocode.sh` | Source models.sh |
| `aider.sh` | Source models.sh |
| `zed.sh` | Source models.sh |
| `cursor.sh` | Source models.sh |
| `opencode.sh` | Source models.sh |
| `continue.sh` | Source models.sh |
| `claude.sh` | Source models.sh, deploy config |
| `gemini.sh` | Remove LiteLLM env vars |
| `grok.sh` | Remove LiteLLM env vars |
| `crush.sh` | Remove LiteLLM references |
| All `models.sh` | Add `MODEL_QUANTS` + `MODEL_CONTEXTS` |
