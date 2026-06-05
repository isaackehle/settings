# ==============================================
# MODEL DEFINITIONS - 16GB lightweight (shared)
# ==============================================
# DATA FILE — sourced by install/deploy scripts, never executed directly.
# Shared with macbook-m1-16gb (same memory constraints).
#
# May 2026 refresh — support for multiple local backends (Ollama, oMLX, LMStudio)
#
# Concurrency budget: ~10 GB usable (16 GB - 6 GB macOS overhead).
#   Ollama: Multi mode:  r1-tools-8B (5 GB) + 4B (3 GB) + 1.5B (1 GB) + embed (0.3 GB) = 9.3 GB ✓
#   oMLX:   Multi mode:  7B (4.3 GB) + 4B (2.1 GB) + 1.5B (0.9 GB) + embed (0.2 GB) = 7.5 GB ✓
#   LMStudio: Standard usage (usually 1-2 models loaded).

# ----------------------------------------------------------------------
# LLAMA.CPP-FIRST ADDITIONS
# ----------------------------------------------------------------------
# The sections below preserve the current multi-backend structure while
# adding the minimum metadata needed for a GGUF / llama.cpp-first workflow.
#
# Design rules:
# - `LOCAL_MODEL_NAMES` is the role → stable local alias map consumed by
#   llama.cpp-aware tooling and GGUF-first install/registration scripts.
# - `GGUF_SOURCES` records the canonical upstream Hugging Face repo for each
#   local alias.
# - `GGUF_QUANTS` records the preferred GGUF quant for the alias.
# - `GGUF_LOCAL_FILENAMES` records the normalized local artifact filename.
# - `GGUF_FAMILIES` records high-level runtime family/type hints.
# - `GGUF_VARIANTS` allows additional quant aliases when you want multiple
#   local registrations for the same upstream model.
#
# ==============================================
# LLAMA.CPP ROLE MAP — minimal runtime contract
# ==============================================
declare -A LOCAL_MODEL_NAMES=(
    ["coder"]="qwen2.5-coder:7b"
    ["embedding"]="nomic-embed-text"
    ["fast"]="qwen3:4b"
    ["fast_alt"]="qwen3.5:4b"
    ["general"]="qwen2.5-coder:7b"
    ["heavy"]="qwen3:14b"
    ["reasoning"]="deepseek-r1:7b"
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
elif [ -n "${SETTINGS_BASE:-}" ] && [ -f "${SETTINGS_BASE}/ai/profiles/macmini-m2-16gb/models.json" ]; then
    _MODELS_JSON="${SETTINGS_BASE}/ai/profiles/macmini-m2-16gb/models.json"
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
    "qwen3-coder-next:80b-cloud" # 80B  | Coding, tools (262K context)
    "gemma4:31b-cloud"           # 33B  | Thinking, tools, vision (262K context)
    "gpt-oss:120b-cloud"         # 117B | Tools, thinking (131K context)
)

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [build]="qwen2.5-coder:7b"                # build, test, CI
    [code]="qwen2.5-coder:7b"
    [local]="qwen2.5-coder:7b"                # fully local (no internet)
    [plan]="qwen3:4b"
    [research]="qwen2.5-coder:7b"
    [summary]="qwen3.5:4b"                    # commit messages, summaries
    [think]="deepseek-r1:7b"
    [title]="qwen3.5:4b"                      # PR/MR titles
    [write]="qwen3:14b"
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [apply]="qwen2.5-coder:7b"
    [autocomplete]="qwen2.5-coder:1.5b"
    [autocomplete_heavy]="qwen2.5-coder:7b"
    [chat]="qwen2.5-coder:7b"
    [chat_alt]="qwen2.5-coder:7b"
    [embed]="nomic-embed-text"
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [coding]="qwen2.5-coder:7b"
    [fast]="qwen3:4b"
    [opus]="qwen2.5-coder:7b"
    [primary]="qwen2.5-coder:7b"
    [reasoning]="deepseek-r1:7b"
    [research]="qwen2.5-coder:7b"
)

# --- Aider (CLI) ---
declare -A AIDER_MODELS=(
    [editor]="qwen2.5-coder:7b"
    [model]="qwen2.5-coder:7b"
    [weak]="qwen3:4b"
)

# --- Cline (VS Code) ---
declare -A CLINE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen2.5-coder:7b"
)

# --- Cursor ---
declare -A CURSOR_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen2.5-coder:7b"
)

# --- Kilo Code (VS Code) ---
declare -A KILOCODE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen2.5-coder:7b"
)

# --- Zed ---
declare -A ZED_MODELS=(
    [model]="qwen2.5-coder:7b"
)

# --- Zoo Code (VS Code extension) ---
declare -A ZOOCODE_MODELS=(
    [architect]="qwen2.5-coder:7b"
    [cloud]="kimi-k2.6"
    [code]="qwen2.5-coder:7b"
    [debug]="deepseek-r1:7b"
    [model]="qwen2.5-coder:7b"
)