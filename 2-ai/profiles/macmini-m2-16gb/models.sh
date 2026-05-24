# ==============================================
# MODEL DEFINITIONS - 16GB lightweight (shared)
# ==============================================
# DATA FILE — sourced by install/deploy scripts, never executed directly.
# Shared with macmini-m2-16gb (same memory constraints).
#
# May 2026 refresh — no LiteLLM proxy. All tools connect to Ollama
# directly via http://localhost:11434/v1 (OpenAI-compatible endpoint).
#
# Concurrency budget: ~10 GB usable (16 GB - 6 GB macOS overhead).
#   Solo mode:    14B-q5 (11 GB) alone — nothing else fits.
#   Multi mode:   r1-tools-8B (5 GB) + 4B (3 GB) + 1.5B (1 GB) + embed (0.3 GB) = 9.3 GB ✓
#   Multi+heavy:  + qwen2.5-coder:7b (5 GB) = 14.3 GB (borderline, on-demand only)

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
# LOCAL MODELS (pull with ollama)
# ==============================================
OLLAMA_MODELS=(
    # ═══════════════════════════════════════════════════════════════
    # CODING / GENERAL (solo mode)
    # ═══════════════════════════════════════════════════════════════
    "qwen3:14b"                   # ~11 GB | Primary coding + general (q5, 40k)
    "qwen3:14b"                   # ~16 GB | Max-quality solo mode (q8, 40k) — on-demand

    # ═══════════════════════════════════════════════════════════════
    # REASONING (with tool calling)
    # ═══════════════════════════════════════════════════════════════
    "deepseek-r1-tools:8b"        # ~5 GB  | Reasoning + function calling (q4_K_M, 128k)

    # ═══════════════════════════════════════════════════════════════
    # PLANNING / FAST
    # ═══════════════════════════════════════════════════════════════
    "qwen3:4b"                    # ~3 GB  | Planning, routing, task breakdown (q4, 256k)

    # ═══════════════════════════════════════════════════════════════
    # CODE (fast/on-demand)
    # ═══════════════════════════════════════════════════════════════
    "qwen2.5-coder:7b"            # ~5 GB  | Fast code tasks (on-demand, 32k)

    # ═══════════════════════════════════════════════════════════════
    # AUTOCOMPLETE
    # ═══════════════════════════════════════════════════════════════
    "qwen2.5-coder:1.5b"          # ~1 GB  | FIM inline completions (32k)

    # ═══════════════════════════════════════════════════════════════
    # EMBEDDINGS
    # ═══════════════════════════════════════════════════════════════
    "nomic-embed-text"            # ~0.3 GB | Semantic search / RAG (8k)

    # ═══════════════════════════════════════════════════════════════
    # CLOUD MODELS (documented here for completeness; skipped during install)
    # ═══════════════════════════════════════════════════════════════
    "deepseek-v4-pro:cloud"
    "gemini-3-flash-preview:cloud"
    "glm-5.1:cloud"
    "gpt-oss:120b-cloud"
    "gpt-oss:20b-cloud"
    "kimi-k2.6:cloud"
    "mistral-large-3:cloud"
)

# ==============================================
# ALTERNATIVE QUANTS — on-demand only
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen3:14b"]="q8:16 GB (solo max quality)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# ==============================================
declare -A MODEL_CONTEXTS=(
    ["qwen3:14b"]="40k"
    ["deepseek-r1-tools:8b"]="128k"
)

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# ==============================================
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3:14b"                       # primary coding agent
    [think]="deepseek-r1-tools:8b"           # tradeoff analysis, debugging strategy
    [write]="qwen3:14b"                      # resumes, cover letters, docs
    [research]="qwen3:14b"                   # codebase/web investigation
    [plan]="qwen3:4b"                        # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3:14b"                       # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3:14b"                   # manual model switch in chat
    [apply]="qwen3:14b"                      # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"       # inline completions (default)
    [embed]="nomic-embed-text"               # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3:14b"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1-tools:8b"
    [opus]="qwen3:14b"
)

# --- Cline / Roo Code / Kilo Code (VS Code) ---
CLINE_MODEL="qwen3:14b"
CLINE_MODEL_CLOUD="kimi-k2.6"


KILOCODE_MODEL="qwen3:14b"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Aider (CLI) ---
AIDER_MODEL="qwen3:14b"
AIDER_WEAK_MODEL="qwen3:4b"
AIDER_EDITOR_MODEL="qwen3:14b"

# --- Zed ---
ZED_MODEL="qwen3:14b"

# --- Cursor ---
CURSOR_MODEL="qwen3:14b"
CURSOR_MODEL_CLOUD="kimi-k2.6"

# ==============================================
# OLlama direct usage
# ==============================================
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3:14b                         interactive shell
#   ollama run deepseek-r1-tools:8b              reasoning shell
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
