# ==============================================
# MODEL DEFINITIONS - M5 Max 64GB (maximum)
# ==============================================
# DATA FILE — sourced by install/deploy scripts, never executed directly.
#
# SINGLE SOURCE OF TRUTH. Every model, quant option, context variant,
# and tool assignment lives here. Install and deploy scripts read this
# file to pull models, create context aliases, and generate tool configs.
#
# May 2026 refresh — no LiteLLM proxy.
# Concurrency budget: ~54 GB usable (64 GB - 6 GB macOS - 4 GB Ollama).
#
# >>> SHARED GGUF-FIRST DEFINITIONS >>>
# ----------------------------------------------------------------------
# LLAMA.CPP-FIRST ADDITIONS
# ----------------------------------------------------------------------
# The sections below preserve the current Ollama-oriented structure while
# adding the minimum metadata needed for a llama.cpp-first workflow.
#
# Why this exists:
# - `ai/runtimes/llama-cpp.sh` needs a simple way to resolve high-level roles like
#   `fast`, `general`, `coder`, and `heavy` into concrete local model aliases.
# - Future install scripts need enough metadata to map those aliases to
#   Hugging Face repos, preferred GGUF quantizations, and expected artifact
#   names on disk.
# - We are intentionally keeping this small at first so existing deploy
#   scripts do not break while the runtime layer is being introduced.
#
# Design rules:
# - `LOCAL_MODEL_NAMES` is the role → local alias map consumed by
#   `llama-cpp.sh` and future runtime-aware scripts.
# - `GGUF_SOURCES` records the canonical upstream Hugging Face repo for each
#   local alias. This is documentation plus machine-readable install metadata.
# - `GGUF_QUANTS` records the preferred GGUF quant for the alias.
# - `GGUF_LOCAL_FILENAMES` records the expected local artifact filename. This is the
#   filename install scripts should create or normalize to under `${GGUF_DIR}`.
# - Keep aliases stable even if the upstream repo or quant changes later.
#   Tool configs should point at stable aliases, not volatile artifact names.
# - This section does NOT replace the broader Ollama model lists yet; it adds
#   the minimum runtime contract for the new llama.cpp-first scripts.

# ==============================================
# LLAMA.CPP ROLE MAP — minimal runtime contract
# ==============================================
# Role names are intentionally generic so wrapper scripts can say:
#   llama-cpp.sh run fast
#   llama-cpp.sh serve coder
#   llama-cpp.sh bench heavy
#
# The values are stable *local aliases* for this machine profile. These do not
# need to match upstream Hugging Face filenames exactly. Think of them as the
# profile's canonical local model identifiers.
declare -A LOCAL_MODEL_NAMES=(
    ["apply"]="codestral:22b"
    ["autocomplete"]="qwen2.5-coder:1.5b"
    ["autocomplete_heavy"]="qwen2.5-coder:7b"
    ["coder"]="qwen3-coder-30b-a3b:q6"
    ["embedding"]="nomic-embed-text"
    ["fast"]="qwen3:4b"
    ["fast_alt"]="qwen3.5:4b"
    ["general"]="qwen3.5-27b:q4"
    ["heavy"]="qwen3.6-35b:opus4.6"
    ["reasoning"]="deepseek-r1:32b"
    ["reasoning_tools"]="deepseek-r1-tools:32b"
    ["summary"]="qwen3.5:4b"
)

# ==============================================
# MODEL REGISTRY — loaded from models.json
# ==============================================
# All model metadata lives in models.json (one model = one JSON object).
# This section parses it into the associative arrays that install/deploy scripts expect.
# To add or edit a model, change models.json — do not edit the arrays below.

# Resolve models.json relative to this file's directory.
# BASH_SOURCE works when sourced directly; fall back to SETTINGS_BASE when
# sourced through process substitution (source <(sed ...)).
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]%/*}/models.json" ]; then
    _MODELS_JSON="${BASH_SOURCE[0]%/*}/models.json"
elif [ -n "${SETTINGS_BASE:-}" ] && [ -f "${SETTINGS_BASE}/ai/profiles/macbook-m5-64gb/models.json" ]; then
    _MODELS_JSON="${SETTINGS_BASE}/ai/profiles/macbook-m5-64gb/models.json"
else
    echo "ERROR: models.json not found (tried BASH_SOURCE and SETTINGS_BASE)" >&2
    return 1 2>/dev/null || exit 1
fi

# Require jq for JSON parsing
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: jq is required to parse models.json. Install with: brew install jq" >&2
    return 1 2>/dev/null || exit 1
fi

declare -A GGUF_SOURCES=() GGUF_QUANTS=() GGUF_LOCAL_FILENAMES=() GGUF_REMOTE_FILENAMES=()
declare -A GGUF_FAMILIES=() OLLAMA_CONTEXT_WINDOWS=() MODELFILE_PARAMS=() MODEL_REMOTES=()

while IFS= read -r _line; do
    _alias="${_line%%|*}"
    _rest="${_line#*|}"
    _family="${_rest%%|*}"; _rest="${_rest#*|}"
    _quant="${_rest%%|*}"; _rest="${_rest#*|}"
    _local_fn="${_rest%%|*}"; _rest="${_rest#*|}"
    _remote_fn="${_rest%%|*}"; _rest="${_rest#*|}"
    _hf_source="${_rest%%|*}"; _rest="${_rest#*|}"
    _ctx="${_rest%%|*}"; _rest="${_rest#*|}"
    _params="${_rest%%|*}"; _rest="${_rest#*|}"
    _remote_pull="${_rest%%|*}"
    [[ -z "$_alias" ]] && continue
    [[ -n "$_hf_source" ]] && GGUF_SOURCES["$_alias"]="$_hf_source"
    [[ -n "$_quant" ]] && GGUF_QUANTS["$_alias"]="$_quant"
    [[ -n "$_local_fn" ]] && GGUF_LOCAL_FILENAMES["$_alias"]="$_local_fn"
    [[ -n "$_remote_fn" ]] && GGUF_REMOTE_FILENAMES["$_alias"]="$_remote_fn"
    [[ -n "$_family" ]] && GGUF_FAMILIES["$_alias"]="$_family"
    [[ -n "$_ctx" ]] && OLLAMA_CONTEXT_WINDOWS["$_alias"]="$_ctx"
    [[ -n "$_params" ]] && MODELFILE_PARAMS["$_alias"]="$_params"
    [[ -n "$_remote_pull" ]] && MODEL_REMOTES["$_alias"]="$_remote_pull"
done < <(
    jq -r '
        .models | to_entries[] |
        .key as $alias |
        .value |
        [
            $alias,
            .family // "",
            .quant // "",
            .local_filename // "",
            .remote_filename // "",
            .hf_source // "",
            (.context_windows | map(tostring) | join(" ")),
            (.modelfile_params | join("\\n")),
            .remote_pull // ""
        ] | join("|")
    ' "$_MODELS_JSON"
)
unset _line _alias _rest _family _quant _local_fn _remote_fn _hf_source _ctx _params _remote_pull _MODELS_JSON

# Optional additional GGUF variants to keep installed concurrently per alias.
# Value format: quant|filename|source, quant|filename|source
# Example: ["qwen3:4b"]="Q4_K_M|qwen3__4b__q5.gguf|hf.co/..."
declare -A GGUF_VARIANTS=()

# ==============================================
# CLOUD MODELS (via OpenRouter — tools connect directly)
# ==============================================
OPENROUTER_MODELS=(
    "claude-opus-4-6"
    "claude-sonnet-4-6"
    "claude-haiku-4-5"
    "gpt-4o"
    "o3"
    "sonar-pro"
    "deepseek-v4-pro"
    "gemini-3-flash-preview"
    "glm-5.1"
    "gpt-oss:120b"
    "gpt-oss:20b"
    "kimi-k2.6"
    "mistral-large-3"
)

# ==============================================
# OLLAMA CLOUD MODELS (zero-disk — route to remote servers)
# Pull the manifest to enable cloud-routed inference through Ollama.
# No local weights — only a tiny JSON manifest is downloaded.
# ==============================================
OLLAMA_CLOUD_MODELS=(
    "qwen3.5:397b-cloud"        # 397B | Writing, thinking, tools, vision (262K context)
    "qwen3-coder:480b-cloud"     # 480B | Coding, tools (262K context)
    "gemma4:31b-cloud"           # 33B  | Thinking, tools, vision (262K context)
    "gpt-oss:120b-cloud"         # 117B | Tools, thinking (131K context)
)



# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# Each entry: base model → space-separated context sizes
# Install script runs: ollama create <base>-<size> -f Modelfile
# Share underlying weights — zero additional disk space.
# ==============================================

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# All use plain Ollama model names. Tools connect to :11434/v1.
# ==============================================

# --- OpenCode agents (→ opencode.jsonc) ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-30b-a3b:q6"
    [think]="gemma4:31b"
    [write]="qwen3.5-27b:q4"
    [research]="qwen3.5-27b:q4"
    [plan]="qwen3:4b"
)

# --- Continue (→ config.yaml) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b-a3b:q6"
    [chat_alt]="qwen3.5-27b:q4"
    [apply]="codestral:22b"
    [autocomplete]="qwen2.5-coder:1.5b"
    [autocomplete_heavy]="qwen2.5-coder:7b"
    [embed]="nomic-embed-text"
)

# --- Claude Code (→ settings.json + ollama/config.json) ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3-coder-30b-a3b:q6"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1:32b"
    [research]="qwen3.5-27b:q4"
    [coding]="qwen3-coder-30b-a3b:q6"
    [opus]="qwen3.6-35b:opus4.6"
)

# --- Aider (CLI) ---
declare -A AIDER_MODELS=(
    [editor]="codestral:22b"
    [model]="qwen3-coder-30b-a3b:q6"
    [weak]="qwen3:4b"
)

# --- Cline (VS Code) ---
declare -A CLINE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-30b-a3b:q6"
)

# --- Cursor ---
declare -A CURSOR_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-30b-a3b:q6"
)

# --- Kilo Code (VS Code) ---
declare -A KILOCODE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-30b-a3b:q6"
)

# --- Zed ---
declare -A ZED_MODELS=(
    [model]="qwen3-coder-30b-a3b:q6"
)

# --- Zoo Code (VS Code extension) ---
declare -A ZOOCODE_MODELS=(
    [architect]="qwen3-coder-30b-a3b:q6"
    [cloud]="kimi-k2.6"
    [code]="qwen3-coder-30b-a3b:q6"
    [debug]="deepseek-r1:32b"
    [model]="qwen3-coder-30b-a3b:q6"
)
