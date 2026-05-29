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
#   Resident:     qwen3-coder-30b-a3b:q5 (21 GB) + qwen3:4b (5 GB) + 1.5B (1 GB) + embed (0.3 GB) = 27.3 GB borderline
#   Solo mode:    coder-30B alone fits comfortably
#   Writing:      Unload coder-30B, load 27B-q5 (19 GB)
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

# ==============================================
# LOCAL MODELS (pull with ollama)
# ==============================================
OLLAMA_MODELS=(
    # CODING (resident)

    "qwen3-coder-30b-a3b:q5"      # ~21 GB | Primary coding (256k). 30B-A3B, 3.3B active.

    # CODING (solo / swap-in)
    "qwen3:14b"                    # ~11 GB | Solo coding when 30B cannot fit (256k)

    # REASONING (swap-in)
    "deepseek-r1-tools:8b"         # ~5 GB  | Reasoning + function calling (128k)

    # WRITING / ARCHITECT — swap-in
    "qwen3.5-27b:q5"              # ~19 GB | Writing, docs, architect (256k, 201 languages)

    # PLANNING / FAST
    "qwen3:4b"                    # ~5 GB  | Planning, routing, task breakdown (256k)

    # CODE APPLY / INSERT (on-demand)
    "codestral:22b"               # ~14 GB | Diff application (q4 default, on-demand, 32k)

    # AUTOCOMPLETE
    "qwen2.5-coder:1.5b"          # ~1 GB  | FIM inline completions (32k)
    "qwen2.5-coder:7b"            # ~5 GB  | Complex file completions (on-demand, 32k)

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
    ["deepseek-r1-tools:8b"]="MFDoom/deepseek-r1-tool-calling:8b"
    ["qwen3.5-27b:q5"]="sinhang/qwen3.5-claude-4.6-opus:27b-q5_K_M"
)
# ==============================================
# ALTERNATIVE QUANTS — on-demand only
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen3-coder-30b-a3b"]="qwen3-coder-30b-a3b:q8|32 GB (solo coding)"
    ["qwen3.5-27b"]="qwen3.5-27b:q8|29 GB (writing / research)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# ==============================================
declare -A MODEL_CONTEXTS=(
    ["qwen3-coder-30b-a3b:q5"]="8k 32k 128k"
    ["qwen3:14b"]="8k 40k 128k 256k"
    ["qwen3:4b"]="8k 128k"
    ["deepseek-r1-tools:8b"]="128k"
    ["qwen3.5-27b:q5"]="8k 32k 128k"
    ["qwen3.5-27b:q8"]="8k 32k 128k"
    ["qwen2.5-coder:7b"]="8k 32k"
    ["codestral:22b"]="32k"
)

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-30b-a3b:q5"          # primary coding agent
    [think]="deepseek-r1-tools:8b"            # tradeoff analysis, debugging strategy
    [write]="qwen3.5-27b:q5"                 # resumes, cover letters, polished prose
    [research]="qwen3-coder-30b-a3b:q5"      # codebase/web investigation
    [plan]="qwen3:4b"                        # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b-a3b:q5"          # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3.5-27b:q5"               # manual model switch in chat
    [apply]="codestral:22b"                   # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"        # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"   # switch manually for complex files
    [embed]="nomic-embed-text"               # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3-coder-30b-a3b:q5"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1-tools:8b"
    [research]="qwen3-coder-30b-a3b:q5"
    [coding]="qwen3-coder-30b-a3b:q5"
    [opus]="qwen3.5-27b:q5"
)

# --- Cline / Roo Code / Kilo Code (VS Code) ---
CLINE_MODEL="qwen3-coder-30b-a3b:q5"
CLINE_MODEL_CLOUD="kimi-k2.6"

KILOCODE_MODEL="qwen3-coder-30b-a3b:q5"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Kilo Code (VS Code extension) ---
KILOCODE_MODEL="qwen3-coder-30b-a3b:q5"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Zoo Code (VS Code extension) ---
ZOOCODE_MODEL="qwen3-coder-30b-a3b:q5"
ZOOCODE_MODEL_CLOUD="kimi-k2.6"
ZOOCODE_MODE_CODE="qwen3-coder-30b-a3b:q5"
ZOOCODE_MODE_ARCHITECT="qwen3.5-27b:q5"
ZOOCODE_MODE_ASK="qwen3.5-27b:q5"
ZOOCODE_MODE_DEBUG="deepseek-r1-tools:8b"

# --- Aider (CLI) ---
AIDER_MODEL="qwen3-coder-30b-a3b:q5"
AIDER_WEAK_MODEL="qwen3:4b"
AIDER_EDITOR_MODEL="codestral:22b"

# --- Zed ---
ZED_MODEL="qwen3.5-27b:q5"

# --- Cursor ---
CURSOR_MODEL="qwen3-coder-30b-a3b:q5"
CURSOR_MODEL_CLOUD="kimi-k2.6"

# ==============================================
# Ollama direct usage
# ==============================================
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3-coder-30b-a3b:q5          interactive shell (coding)
#   ollama run qwen3.5-27b:q5                   interactive shell (writing)
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
