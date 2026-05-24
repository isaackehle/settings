# ==============================================
# MODEL DEFINITIONS - M5 Max 48GB (powerful)
# ==============================================
# DATA FILE — sourced by install/deploy scripts, never executed directly.
#
# May 2026 refresh — no LiteLLM proxy. All tools connect to Ollama
# directly via http://localhost:11434/v1 (OpenAI-compatible endpoint).
# Context-window variants are created as Ollama aliases via Modelfiles
# with PARAMETER num_ctx.
#
# Concurrency budget: ~42 GB usable (48 GB - 6 GB macOS overhead).
#   Resident:    30B-coder-q5 (21 GB) + r1-tools-14B (9 GB) + 4B (5 GB) + 1.5B (1 GB) + embed (0.3 GB) = 36.3 GB ✓
#   Writing swap: Unload coder-30B, load 27B-q8 (29 GB) when writing
#   Gemma swap:   Unload coder-30B, load gemma4:31b (20 GB) + 4B (5 GB) + 1.5B (1 GB) + embed (0.3 GB) = 26.3 GB ✓
#   Codestral & autocomplete-heavy are on-demand only

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
    # CODING — primary model (resident)
    # ═══════════════════════════════════════════════════════════════
    "qwen3-coder-30b-a3b:q5"      # ~21 GB | Primary coding (256k). 30B-A3B, 3.3B active.

    # ═══════════════════════════════════════════════════════════════
    # ARCHITECT / DENSE REASONING / VISION — swap-in specialist
    # ═══════════════════════════════════════════════════════════════
    "gemma4:31b"                  # ~20 GB | Dense: vision, configurable thinking, FC (256k)

    # ═══════════════════════════════════════════════════════════════
    # WRITING / ARCHITECT — swap-in models
    # ═══════════════════════════════════════════════════════════════
    "qwen3.5-27b:q5"              # ~19 GB | Writing, docs, architect (256k, 201 languages)

    # ═══════════════════════════════════════════════════════════════
    # REASONING (with tool calling) — resident
    # ═══════════════════════════════════════════════════════════════
    "deepseek-r1-tools:14b"       # ~9 GB  | Reasoning + function calling (q4_K_M, 128k)

    # ═══════════════════════════════════════════════════════════════
    # PLANNING / FAST
    # ═══════════════════════════════════════════════════════════════
    "qwen3:4b"                    # ~5 GB  | Planning, routing, task breakdown (256k)

    # ═══════════════════════════════════════════════════════════════
    # RESEARCH
    # ═══════════════════════════════════════════════════════════════
    "qwen3:14b"                   # ~11 GB | Codebase/web investigation (q5, 40k)

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
# ALTERNATIVE QUANTS
# Pull on-demand: ollama pull <model-tag>
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen3-coder-30b-a3b"]="q8:32 GB (solo only)"
    ["qwen3.5-27b"]="q8:29 GB (solo prose)"
    ["qwen3:14b"]="q8:16 GB (solo research)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS
# Created via ollama create during setup (share weights, zero extra disk).
# ==============================================
declare -A MODEL_CONTEXTS=(
    ["qwen3-coder-30b-a3b:q5"]="8k 32k 128k"
    ["gemma4:31b"]="8k 32k 128k"
    ["qwen3.5-27b:q5"]="8k 32k 128k"
    ["deepseek-r1-tools:14b"]="128k"
    ["qwen3:14b"]="40k"
    ["codestral:22b"]="32k"
)

# ==============================================
# TOOL ASSIGNMENTS
# All use plain Ollama model names. Tools connect to :11434/v1.
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-30b-a3b:q5"         # primary coding agent
    [think]="deepseek-r1-tools:14b"          # tradeoff analysis, debugging strategy
    [write]="qwen3.5-27b:q8"                # resumes, cover letters, polished prose
    [research]="qwen3:14b"                   # codebase/web investigation
    [plan]="qwen3:4b"                        # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b-a3b:q5"          # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3.5-27b:q8"              # manual model switch in chat
    [apply]="codestral:22b"                   # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"       # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"   # switch manually for complex files
    [embed]="nomic-embed-text"               # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3-coder-30b-a3b:q5"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1-tools:14b"
    [research]="qwen3:14b"
    [opus]="qwen3.5-27b:q5"
)

# --- Cline / Roo Code / Kilo Code (VS Code) ---
CLINE_MODEL="qwen3-coder-30b-a3b:q5"
CLINE_MODEL_CLOUD="kimi-k2.6"


KILOCODE_MODEL="qwen3-coder-30b-a3b:q5"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Aider (CLI) ---
AIDER_MODEL="qwen3-coder-30b-a3b:q5"
AIDER_WEAK_MODEL="qwen3:4b"
AIDER_EDITOR_MODEL="codestral:22b"

# --- Zed ---
ZED_MODEL="qwen3-coder-30b-a3b:q5"

# --- Cursor ---
CURSOR_MODEL="qwen3-coder-30b-a3b:q5"
CURSOR_MODEL_CLOUD="kimi-k2.6"

# ==============================================
# OLlama direct usage
# ==============================================
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3-coder-30b-a3b:q5            interactive shell (coding)
#   ollama run gemma4:31b                       dense thinking + vision (swap in)
#   ollama run qwen3.5-27b:q5                    interactive shell (writing)
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
