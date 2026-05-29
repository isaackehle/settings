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
    "qwen3.5:cloud"              # 397B | Writing, thinking, tools, vision (262K context)
    "qwen3-coder:480b-cloud"     # 480B | Coding, tools (262K context)
    "qwen3-coder-next:cloud"     # 80B  | Coding, tools (262K context)
    "gemma4:31b-cloud"           # 33B  | Thinking, tools, vision (262K context)
    "gpt-oss:120b-cloud"         # 117B | Tools, thinking (131K context)
)

# =========================================================================
# LOCAL MODELS SETUP
# ========================================================================

# --- Ollama Models ---
OLLAMA_MODELS=(
    "qwen2.5-coder:7b"            # ~5 GB  | Primary coding + general (q4_K_M, 32k)
    "codestral:22b"               # ~14 GB | Diff application (q4 default, on-demand, 32k)
    "qwen3:14b"                    # ~11 GB | Solo coding when 7B is insufficient (256k)
    "deepseek-r1-tools:8b"         # ~5 GB  | Reasoning + function calling (128k)
    "qwen3:4b"                    # ~5 GB  | Planning, routing, task breakdown (256k)
    "qwen2.5-coder:1.5b"          # ~1 GB  | FIM inline completions + light chat (32k)
    "nomic-embed-text"            # ~0.3 GB | Semantic search / RAG (8k)
)

# --- oMLX Models (HuggingFace paths) ---
# oMLX uses HF repo IDs. Quantization is usually specified in the repo name.
OMLX_MODELS=(
    "mlx-community/Qwen2.5-Coder-7B-Instruct-4bit"    # Primary coding (4.28 GB)
    "mlx-community/Codestral-22B-v0.1-4bit"           # Diff apply (12.5 GB)
    "Qwen/Qwen3-14B-MLX-4bit"                         # Solo coding (7.75 GB)
    "mlx-community/DeepSeek-R1-Distill-Qwen-7B-4bit"   # Reasoning (4.28 GB)
    "Qwen/Qwen3-4B-MLX-4bit"                          # Planning (2.14 GB)
    "mlx-community/Qwen2.5-Coder-1.5B-Instruct-4bit"   # Autocomplete (0.87 GB)
    "mlx-community/nomicai-modernbert-embed-base-8bit" # Embeddings (0.16 GB)
)

# --- LM Studio Models ---
# LM Studio models are typically managed via GUI and stored in ~/.cache/lm-studio
# Here we list the recommended targets for manual download.
LMSTUDIO_MODELS=(
    "Qwen2.5-Coder-7B-Instruct-GGUF"
    "DeepSeek-R1-Distill-Qwen-7B-GGUF"
    "Qwen3-4B-GGUF"
)

# ==============================================
# REMOTE MODELS — pull from community namespace, alias locally
# ========================================================================
declare -A MODEL_REMOTES=(
    ["deepseek-r1-tools:8b"]="MFDoom/deepseek-r1-tool-calling:8b"
)

# ==============================================
# ALTERNATIVE QUANTS — on-demand only
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen2.5-coder"]="qwen2.5-coder:7b:q8_0|qwen2.5-coder:7b:q8|8 GB (solo coding)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# ========================================================================
declare -A MODEL_CONTEXTS=(
    ["qwen2.5-coder:7b"]="8k 32k"
    ["qwen3:14b"]="8k 40k 128k 256k"
    ["qwen3:4b"]="8k 128k"
    ["deepseek-r1-tools:8b"]="128k"
    ["codestral:22b"]="32k"
)

# ========================================================================
# ROLE MAPPINGS (Backend Agnostic)
# ========================================================================
# These mappings allow deploy scripts to pick the correct model for the
# chosen backend (OLLAMA, OMLX, or LMSTUDIO).

declare -A MODEL_ROLES=(
    [primary]="qwen2.5-coder:7b|mlx-community/Qwen2.5-Coder-7B-Instruct-4bit|Qwen2.5-Coder-7B"
    [solo]="qwen3:14b|Qwen/Qwen3-14B-MLX-4bit|Qwen3-14B"
    [reasoning]="deepseek-r1-tools:8b|mlx-community/DeepSeek-R1-Distill-Qwen-7B-4bit|DeepSeek-R1-7B"
    [planning]="qwen3:4b|Qwen/Qwen3-4B-MLX-4bit|Qwen3-4B"
    [autocomplete]="qwen2.5-coder:1.5b|mlx-community/Qwen2.5-Coder-1.5B-Instruct-4bit|Qwen2.5-Coder-1.5B"
    [apply]="codestral:22b|mlx-community/Codestral-22B-v0.1-4bit|Codestral-22B"
    [embed]="nomic-embed-text|mlx-community/nomicai-modernbert-embed-base-8bit|Nomic-Embed"
)

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="primary"
    [think]="reasoning"
    [write]="primary"
    [research]="primary"
    [plan]="planning"
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="primary"
    [chat_alt]="primary"
    [apply]="primary"
    [autocomplete]="autocomplete"
    [autocomplete_heavy]="primary"
    [embed]="embed"
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="primary"
    [fast]="planning"
    [reasoning]="reasoning"
    [research]="primary"
    [coding]="primary"
    [opus]="primary"
)

# --- Cline / Roo Code / Kilo Code (VS Code) ---
CLINE_MODEL="primary"
CLINE_MODEL_CLOUD="kimi-k2.6"

KILOCODE_MODEL="primary"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Zoo Code (VS Code extension) ---
ZOOCODE_MODEL="primary"
ZOOCODE_MODEL_CLOUD="kimi-k2.6"
ZOOCODE_MODE_CODE="primary"
ZOOCODE_MODE_ARCHITECT="primary"
ZOOCODE_MODEL_DEBUG="reasoning"

# --- Aider (CLI) ---
AIDER_MODEL="primary"
AIDER_WEAK_MODEL="planning"
AIDER_EDITOR_MODEL="primary"

# --- Zed ---
ZED_MODEL="primary"

# --- Cursor ---
CURSOR_MODEL="primary"
CURSOR_MODEL_CLOUD="kimi-k2.6"
