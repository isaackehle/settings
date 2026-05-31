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
# - `2-ai/llama-cpp.sh` needs a simple way to resolve high-level roles like
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
    ["fast"]="qwen3:4b"
    ["general"]="qwen3.5-27b:q4"
    ["coder"]="qwen3-coder-30b-a3b:q6"
    ["heavy"]="qwen3-coder-next-80b:q4"
    ["reasoning"]="deepseek-r1:32b"
    ["embedding"]="nomic-embed-text"
)

# ==============================================
# GGUF SOURCE METADATA — minimal install/runtime metadata
# ==============================================
# These maps document where each local alias should come from when we manage
# the model as a Hugging Face-sourced GGUF artifact.
#
# Key = local alias (must match LOCAL_MODEL_NAMES values)
# Value semantics:
# - GGUF_SOURCES   → upstream Hugging Face repo or source identifier
# - GGUF_QUANTS    → preferred quant label for the local artifact
# - GGUF_LOCAL_FILENAMES → normalized GGUF filename stored in ${GGUF_DIR}
#
declare -A GGUF_SOURCES=(
    ["qwen3:4b"]="hf.co/Qwen/Qwen3-4B-GGUF"
    ["qwen3.5-27b:q4"]="hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    ["qwen3-coder-30b-a3b:q6"]="hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF"
    ["qwen3-coder-next-80b:q4"]="hf.co/unsloth/Qwen3-Coder-Next-GGUF"
    ["deepseek-r1:32b"]="hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF"
    ["nomic-embed-text"]="hf.co/nomic-ai/nomic-embed-text-v1.5-GGUF"
    ["qwen3.5:4b"]="hf.co/unsloth/Qwen3.5-4B-GGUF"
    ["qwen2.5-7b:multi"]="hf.co/mradermacher/Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL-GGUF"
    ["qwen3.5-27b:gemini3.1"]="hf.co/Jackrong/Qwen3.5-27B-Gemini-3.1-Pro-Reasoning-Distill-GGUF"
    ["qwen3-8b:sonnet4.5"]="hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF"
    ["qwen3-14b:sonnet4.5"]="hf.co/TeichAI/Qwen3-14B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF"
    ["qwen3.6-27b:opus-sonnet"]="hf.co/Brian6145/Qwen3.6-27B-Claude-Opus-Sonnet-DistilledV2-MTP-GGUF"
)

declare -A GGUF_QUANTS=(
    ["qwen3:4b"]="Q4_K_M"
    ["qwen3.5-27b:q4"]="Q4_K_M"
    ["qwen3-coder-30b-a3b:q6"]="UD-Q6_K_XL"
    ["qwen3-coder-next-80b:q4"]="Q4_K_M"
    ["deepseek-r1:32b"]="Q4_K_M"
    ["nomic-embed-text"]="F16"
    ["qwen3.5:4b"]="Q4_K_M"
    ["qwen2.5-7b:multi"]="Q4_K_M"
    ["qwen3.5-27b:gemini3.1"]="Q4_K_M"
    ["qwen3-8b:sonnet4.5"]="Q4_K_M"
    ["qwen3-14b:sonnet4.5"]="Q4_K_M"
    ["qwen3.6-27b:opus-sonnet"]="Q4_K_M"
)

# Simplified local filenames: {alias-normalized}-{family-tag}-{quant-lower}.gguf
# Family tags:
#   -it    instruct/vision
#   -cd    coder
#   -ds    distill
#   -it-ds instruct+distill
#   -em    embedding
declare -A GGUF_LOCAL_FILENAMES=(
    ["qwen3:4b"]="qwen3-4b-it-q4_k_m.gguf"
    ["qwen3.5-27b:q4"]="qwen3.5-27b-opus4.6-it-ds-q4_k_m.gguf"
    ["qwen3-coder-30b-a3b:q6"]="qwen3-coder-30b-a3b-cd-ud-q6_k_xl.gguf"
    ["qwen3-coder-next-80b:q4"]="qwen3-coder-next-80b-cd-q4_k_m.gguf"
    ["deepseek-r1:32b"]="deepseek-r1-32b-ds-q4_k_m.gguf"
    ["nomic-embed-text"]="nomic-embed-text-em-f16.gguf"
    ["qwen3.5:4b"]="qwen3.5-4b-it-q4_k_m.gguf"
    ["qwen2.5-7b:multi"]="qwen2.5-7b-multi-it-ds-q4_k_m.gguf"
    ["qwen3.5-27b:gemini3.1"]="qwen3.5-27b-gemini3.1-it-ds-q4_k_m.gguf"
    ["qwen3-8b:sonnet4.5"]="qwen3-8b-sonnet4.5-it-ds-q4_k_m.gguf"
    ["qwen3-14b:sonnet4.5"]="qwen3-14b-sonnet4.5-it-ds-q4_k_m.gguf"
    ["qwen3.6-27b:opus-sonnet"]="qwen3.6-27b-opus-sonnet-it-ds-q4_k_m.gguf"
)

# Verbatim filenames as they appear in the Hugging Face repo.
declare -A GGUF_REMOTE_FILENAMES=(
    ["qwen3:4b"]="Qwen3-4B-Q4_K_M.gguf"
    ["qwen3.5-27b:q4"]="Qwen3.5-27B.Q4_K_M.gguf"
    ["qwen3-coder-30b-a3b:q6"]="Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf"
    ["qwen3-coder-next-80b:q4"]="Qwen3-Coder-Next-Q4_K_M.gguf"
    ["deepseek-r1:32b"]="DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
    ["nomic-embed-text"]="nomic-embed-text-v1.5.f16.gguf"
    ["qwen3.5:4b"]="Qwen3.5-4B-Q4_K_M.gguf"
    ["qwen2.5-7b:multi"]="Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL.Q4_K_M.gguf"
    ["qwen3.5-27b:gemini3.1"]="Qwen3.5-27B.Q4_K_M.gguf"
    ["qwen3-8b:sonnet4.5"]="Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf"
    ["qwen3-14b:sonnet4.5"]="Qwen3-14B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf"
    ["qwen3.6-27b:opus-sonnet"]="Qwen3.6-27B-Claude-Opus-Sonnet-DistilledV2-MTP-Q4_K_M.gguf"
)

declare -A GGUF_FAMILIES=(
    ["qwen3:4b"]="instruct"
    ["qwen3.5-27b:q4"]="instruct-distill"
    ["qwen3-coder-30b-a3b:q6"]="coder"
    ["qwen3-coder-next-80b:q4"]="coder"
    ["deepseek-r1:32b"]="reasoning-tools"
    ["nomic-embed-text"]="embedding"
    ["qwen3.5:4b"]="instruct"
    ["qwen2.5-7b:multi"]="instruct-distill"
    ["qwen3.5-27b:gemini3.1"]="instruct-distill"
    ["qwen3-8b:sonnet4.5"]="instruct-distill"
    ["qwen3-14b:sonnet4.5"]="instruct-distill"
    ["qwen3.6-27b:opus-sonnet"]="instruct-distill"
)

declare -A OLLAMA_CONTEXT_WINDOWS=(
    ["deepseek-r1:32b"]="131072"
    ["nomic-embed-text"]="8192"
    ["qwen3-coder-30b-a3b:q6"]="32768 8192 131072 262144"
    ["qwen3-coder-next-80b:q4"]="32768 8192 16384 32768 65536 131072 262144"
    ["qwen3.5-27b:q4"]="32768 8192 32768 131072 262144"
    ["qwen3:4b"]="131072 8192 131072"
    ["qwen3.5:4b"]="131072"
    ["qwen2.5-7b:multi"]="1010000"
    ["qwen3.5-27b:gemini3.1"]="262144"
    ["qwen3-8b:sonnet4.5"]="40960"
    ["qwen3-14b:sonnet4.5"]="40960"
    ["qwen3.6-27b:opus-sonnet"]="262144"
)

declare -A MODELFILE_PARAMS=(
    ["qwen3:4b"]="PARAMETER temperature 0.2"
    ["qwen3.5-27b:q4"]="PARAMETER temperature 0.6"
    ["qwen3-coder-30b-a3b:q6"]="PARAMETER temperature 0\nPARAMETER repeat_penalty 1.05"
    ["qwen3-coder-next-80b:q4"]="PARAMETER temperature 0\nPARAMETER repeat_penalty 1.05"
    ["deepseek-r1:32b"]="PARAMETER temperature 0.3"
    ["qwen3.5:4b"]="PARAMETER temperature 0.2"
    ["qwen2.5-7b:multi"]="PARAMETER temperature 0.6"
    ["qwen3.5-27b:gemini3.1"]="PARAMETER temperature 0.6"
    ["qwen3-8b:sonnet4.5"]="PARAMETER temperature 0.6"
    ["qwen3-14b:sonnet4.5"]="PARAMETER temperature 0.6"
    ["qwen3.6-27b:opus-sonnet"]="PARAMETER temperature 0.6"
)
# Optional additional GGUF variants to keep installed concurrently per alias.
# Value format: quant|filename|source, quant|filename|source
# Example: ["qwen3:4b"]="Q4_K_M|qwen3__4b__q5.gguf|hf.co/..."
declare -A GGUF_VARIANTS=()
# <<< SHARED GGUF-FIRST DEFINITIONS <<<

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
    "qwen3-coder-next:80b-cloud" # 80B  | Coding, tools (262K context)
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
    [code]="qwen3-coder-next-80b:q4"
    [think]="gemma4:31b"
    [write]="qwen3.5-27b:q8"
    [research]="qwen3.5-27b:q4"
    [plan]="qwen3:4b"
)

# --- Continue (→ config.yaml) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-next-80b:q4"
    [chat_alt]="qwen3.5-27b:q8"
    [apply]="codestral:22b"
    [autocomplete]="qwen2.5-coder:1.5b"
    [autocomplete_heavy]="qwen2.5-coder:7b"
    [embed]="nomic-embed-text"
)

# --- Claude Code (→ settings.json + ollama/config.json) ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3-coder-next-80b:q4"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1:32b"
    [research]="qwen3.5-27b:q4"
    [coding]="qwen3-coder-30b-a3b:q6"
    [opus]="qwen3.6-35b:opus4.6"
)

# --- Aider (CLI) ---
declare -A AIDER_MODELS=(
    [editor]="codestral:22b"
    [model]="qwen3-coder-next-80b:q4"
    [weak]="qwen3:4b"
)

# --- Cline (VS Code) ---
declare -A CLINE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-next-80b:q4"
)

# --- Cursor ---
declare -A CURSOR_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-next-80b:q4"
)

# --- Kilo Code (VS Code) ---
declare -A KILOCODE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-next-80b:q4"
)

# --- Zed ---
declare -A ZED_MODELS=(
    [model]="qwen3-coder-next-80b:q4"
)

# --- Zoo Code (VS Code extension) ---
declare -A ZOOCODE_MODELS=(
    [architect]="qwen3-coder-next-80b:q4"
    [cloud]="kimi-k2.6"
    [code]="qwen3-coder-next-80b:q4"
    [debug]="deepseek-r1:32b"
    [model]="qwen3-coder-next-80b:q4"
)
