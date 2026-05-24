# ==============================================
# MODEL DEFINITIONS - M2 Max 32GB (medium)
# ==============================================
# DATA FILE — sourced by install/deploy scripts, never executed directly.
#
# May 2026 refresh — no LiteLLM proxy. All tools connect to Ollama
# directly via http://localhost:11434/v1 (OpenAI-compatible endpoint).
# Context-window variants are created as Ollama aliases via Modelfiles
# with PARAMETER num_ctx.
#
# Concurrency budget: ~26 GB usable (32 GB - 6 GB macOS overhead).
#   Resident:     14B-q5 (11 GB) + r1-tools-8B (5 GB) + 4B (3 GB) + 1.5B (1 GB) + embed (0.3 GB) = 20.3 GB ✓
#   Heavy AC:     + qwen2.5-coder:7b (5 GB) = 25.3 GB ✓
#   Writing:      27B-q5 (19 GB) solo only
#   Codestral:    22B (14 GB) on-demand solo

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
    # CODING / GENERAL (resident)
    # ═══════════════════════════════════════════════════════════════
    "qwen3:14b"                   # ~11 GB | Primary coding + general (q5, 40k)
    "qwen3:14b"                   # ~16 GB | Max-quality solo mode (q8, 40k) — on-demand

    # ═══════════════════════════════════════════════════════════════
    # WRITING / ARCHITECT — solo only
    # ═══════════════════════════════════════════════════════════════
    "qwen3.5-27b:q5"              # ~19 GB | Writing, docs, architect (256k, 201 languages)

    # ═══════════════════════════════════════════════════════════════
    # REASONING (with tool calling)
    # ═══════════════════════════════════════════════════════════════
    "deepseek-r1-tools:8b"        # ~5 GB  | Reasoning + function calling (q4_K_M, 128k)

    # ═══════════════════════════════════════════════════════════════
    # PLANNING / FAST
    # ═══════════════════════════════════════════════════════════════
    "qwen3:4b"                    # ~3 GB  | Planning, routing, task breakdown (q4, 256k)

    # ═══════════════════════════════════════════════════════════════
    # CODE APPLY / INSERT (on-demand)
    # ═══════════════════════════════════════════════════════════════
    "codestral:22b"               # ~14 GB | Diff application (q4 default, on-demand, 32k)

    # ═══════════════════════════════════════════════════════════════
    # AUTOCOMPLETE
    # ═══════════════════════════════════════════════════════════════
    "qwen2.5-coder:1.5b"          # ~1 GB  | FIM inline completions (32k)
    "qwen2.5-coder:7b"            # ~5 GB  | Complex file completions (on-demand, 32k)

    # ═══════════════════════════════════════════════════════════════
    # EMBEDDINGS
    # ═══════════════════════════════════════════════════════════════
    "nomic-embed-text"            # ~0.3 GB | Semantic search / RAG (8k)
)

# ==============================================
# ALTERNATIVE QUANTS — on-demand only
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen3:14b"]="q8:16 GB (solo max quality)"
    ["qwen3.5-27b"]="q8:29 GB (solo prose)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# ==============================================
declare -A MODEL_CONTEXTS=(
    ["qwen3:14b"]="40k"
    ["qwen3.5-27b:q5"]="8k 32k 128k"
    ["deepseek-r1-tools:8b"]="128k"
    ["codestral:22b"]="32k"
)

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# ==============================================
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3:14b"                       # primary coding agent
    [think]="deepseek-r1-tools:8b"           # tradeoff analysis, debugging strategy
    [write]="qwen3.5-27b:q5"                 # resumes, cover letters, polished prose
    [research]="qwen3:14b"                   # codebase/web investigation
    [plan]="qwen3:4b"                        # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3:14b"                       # chat panel + inline edit (Ctrl+I)
    [chat_alt]="codestral:22b"               # manual model switch in chat
    [apply]="codestral:22b"                  # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"       # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"   # switch manually for complex files
    [embed]="nomic-embed-text"               # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3:14b"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1-tools:8b"
    [opus]="qwen3.5-27b:q5"
)

# --- Cline / Roo Code / Kilo Code (VS Code) ---
CLINE_MODEL="qwen3:14b"
CLINE_MODEL_CLOUD="kimi-k2.6"


KILOCODE_MODEL="qwen3:14b"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Aider (CLI) ---
AIDER_MODEL="qwen3:14b"
AIDER_WEAK_MODEL="qwen3:4b"
AIDER_EDITOR_MODEL="codestral:22b"

# --- Zed ---
ZED_MODEL="qwen3.5-27b:q5"

# --- Cursor ---
CURSOR_MODEL="qwen3:14b"
CURSOR_MODEL_CLOUD="kimi-k2.6"

# ==============================================
# OLlama direct usage
# ==============================================
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3:14b                         interactive shell
#   ollama run qwen3.5-27b:q5                    interactive shell (writing)
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
