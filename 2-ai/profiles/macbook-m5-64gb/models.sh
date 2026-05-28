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
# LOCAL MODELS — one entry per base model, no duplicate quants
# ==============================================
OLLAMA_MODELS=(
    # CODING
    "qwen3-coder-next-80b:q4"     # ~48 GB | Solo coding (256k). Highest quality agentic.
    "qwen3-coder-30b-a3b:q6"      # ~26 GB | Co-resident coding (256k). 30B-A3B, 3.3B active.

    # ARCHITECT / DENSE REASONING / VISION
    # Gemma 4 31B is the only DENSE model >14B in the lineup.
    # All 31B params active per token (vs MoE with ~3B active).
    # Unique: vision, configurable thinking on/off, native function calling.
    "gemma4:31b"                  # ~20 GB | Dense: vision, thinking, function calling (256k)

    # ARCHITECT / WRITING — Qwen MoE (thinking preservation)
    "qwen3.6-35b:q4"              # ~22 GB | Agentic architect, thinking across turns (256k)
    "qwen3.5-27b:q5"              # ~19 GB | Writing, docs, research (256k, 201 languages)

    # REASONING
    "deepseek-r1-tools:32b"       # ~20 GB | Pure reasoning + function calling (q4_K_M, 128k)

    # PLANNING / FAST
    "qwen3:4b"                    # ~5 GB  | Planning, routing, task breakdown (256k)

    # CODE APPLY / INSERT
    "codestral:22b"               # ~23 GB | Diff application (q8, on-demand, 32k)

    # AUTOCOMPLETE
    "qwen2.5-coder:1.5b"          # ~1 GB  | FIM inline completions (32k)
    "qwen2.5-coder:7b"            # ~5 GB  | Complex file completions (32k)

    # EMBEDDINGS
    "nomic-embed-text"            # ~0.3 GB | Semantic search / RAG (8k)
)

# ==============================================
# REMOTE MODELS — pull from community namespace, alias locally
# Some models are not in the official Ollama library and must be
# pulled from a community namespace (e.g., MFDoom/). After pulling,
# a local alias is created so all tool configs use the short name.
# ==============================================
declare -A MODEL_REMOTES=(
    ["deepseek-r1-tools:32b"]="MFDoom/deepseek-r1-tool-calling:32b"
)
# ==============================================
# ALTERNATIVE QUANTS — higher quality for hardware that supports them
# Pull on-demand: ollama pull <full-tag>
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen3-coder-30b-a3b"]="qwen3-coder:30b-a3b-q8_0:32 GB (solo only)"
    ["gemma4:31b"]="gemma4:31b-it-q8_0:28 GB (solo deep reasoning)"
    ["qwen3.6-35b"]="qwen3.6:35b-a3b-q8_0:35 GB (solo only)"
    ["qwen3.5-27b"]="qwen3.5:27b-q8_0:29 GB (solo prose only)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# Each entry: base model → space-separated context sizes
# Install script runs: ollama create <base>-<size> -f Modelfile
# Share underlying weights — zero additional disk space.
# ==============================================
declare -A MODEL_CONTEXTS=(
    ["qwen3-coder-next-80b:q4"]="16k 64k 256k"
    ["qwen3-coder-30b-a3b:q6"]="8k 32k 128k 256k"
    ["gemma4:31b"]="8k 32k 128k 256k"
    ["qwen3.6-35b:q4"]="8k 128k 256k"
    ["qwen3.5-27b:q5"]="8k 32k 128k 256k"
    ["qwen3.5-27b:q8"]="8k 32k 128k 256k"
    ["qwen3:4b"]="8k 128k"
    ["deepseek-r1-tools:32b"]="128k"
    ["qwen2.5-coder:7b"]="8k 32k"
    ["codestral:22b"]="32k"
)

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# All use plain Ollama model names. Tools connect to :11434/v1.
# ==============================================

# --- OpenCode agents (→ opencode.jsonc) ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-next-80b:q4"
    [think]="gemma4:31b"
    [write]="qwen3.5-27b:q8"
    [research]="qwen3.5-27b:q5"
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
    [reasoning]="deepseek-r1-tools:32b"
    [research]="qwen3.5-27b:q5"
    [coding]="qwen3-coder-30b-a3b:q6"
    [opus]="qwen3.6-35b:q4"
)

# --- Cline (VS Code extension) ---
CLINE_MODEL="qwen3-coder-next-80b:q4"
CLINE_MODEL_CLOUD="kimi-k2.6"

# --- Zoo Code (VS Code extension) ---
ZOOCODE_MODEL="qwen3-coder-next-80b:q4"
ZOOCODE_MODEL_CLOUD="kimi-k2.6"
ZOOCODE_MODE_CODE="qwen3-coder-next-80b:q4"
ZOOCODE_MODE_ARCHITECT="qwen3.6-35b:q4"
ZOOCODE_MODE_ASK="qwen3.5-27b:q5"
ZOOCODE_MODE_DEBUG="gemma4:31b"

# --- Kilo Code (VS Code extension) ---
KILOCODE_MODEL="qwen3-coder-next-80b:q4"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Aider (→ aider.conf.yml) ---
AIDER_MODEL="qwen3-coder-next-80b:q4"
AIDER_WEAK_MODEL="qwen3:4b"
AIDER_EDITOR_MODEL="codestral:22b"

# --- Zed (→ settings.json) ---
ZED_MODEL="qwen3-coder-next-80b:q4"

# --- Cursor (IDE) ---
CURSOR_MODEL="qwen3-coder-next-80b:q4"
CURSOR_MODEL_CLOUD="kimi-k2.6"
