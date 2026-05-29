# ==============================================
# MODEL DEFINITIONS - 16GB lightweight (shared)
# ==============================================
# DATA FILE — sourced by install/deploy scripts, never executed directly.
# Shared with macbook-m1-16gb (same memory constraints).
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
    # CODING / GENERAL (solo mode)

    "qwen2.5-coder:7b"            # ~5 GB  | Primary coding + general (q4_K_M, 32k)

    # CODE APPLY / INSERT (on-demand)
    "codestral:22b"               # ~14 GB | Diff application (q4 default, on-demand, 32k)

    # CODING (solo / swap-in)
    "qwen3:14b"                    # ~11 GB | Solo coding when 7B is insufficient (256k)

    # REASONING (swap-in)
    "deepseek-r1-tools:8b"         # ~5 GB  | Reasoning + function calling (128k)

    # PLANNING / FAST
    "qwen3:4b"                    # ~5 GB  | Planning, routing, task breakdown (256k)

    # CODE (fast/on-demand)
    "qwen2.5-coder:1.5b"          # ~1 GB  | FIM inline completions + light chat (32k)

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
)
# ==============================================
# ALTERNATIVE QUANTS — on-demand only
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen2.5-coder:7b"]="qwen2.5-coder:7b-q8_0|qwen2.5-coder:7b-q8|8 GB (solo coding)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# ==============================================
declare -A MODEL_CONTEXTS=(
    ["qwen2.5-coder:7b"]="8k 32k"
    ["qwen3:14b"]="8k 40k 128k 256k"
    ["qwen3:4b"]="8k 128k"
    ["deepseek-r1-tools:8b"]="128k"
    ["codestral:22b"]="32k"
)

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen2.5-coder:7b"                  # primary coding agent
    [think]="deepseek-r1-tools:8b"             # tradeoff analysis, debugging strategy
    [write]="qwen2.5-coder:7b"                 # resumes, cover letters, docs
    [research]="qwen2.5-coder:7b"              # codebase/web investigation
    [plan]="qwen3:4b"                          # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen2.5-coder:7b"                  # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen2.5-coder:7b"              # manual model switch in chat
    [apply]="qwen2.5-coder:7b"                 # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"        # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"    # switch manually for complex files
    [embed]="nomic-embed-text"                 # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen2.5-coder:7b"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1-tools:8b"
    [research]="qwen2.5-coder:7b"
    [coding]="qwen2.5-coder:7b"
    [opus]="qwen2.5-coder:7b"
)

# --- Cline / Roo Code / Kilo Code (VS Code) ---
CLINE_MODEL="qwen2.5-coder:7b"
CLINE_MODEL_CLOUD="kimi-k2.6"

KILOCODE_MODEL="qwen2.5-coder:7b"
KILOCODE_MODEL_CLOUD="kimi-k2.6"

# --- Zoo Code (VS Code extension) ---
ZOOCODE_MODEL="qwen2.5-coder:7b"
ZOOCODE_MODEL_CLOUD="kimi-k2.6"
ZOOCODE_MODE_CODE="qwen2.5-coder:7b"
ZOOCODE_MODE_ARCHITECT="qwen2.5-coder:7b"
ZOOCODE_MODE_ASK="qwen2.5-coder:7b"
ZOOCODE_MODE_DEBUG="deepseek-r1-tools:8b"

# --- Aider (CLI) ---
AIDER_MODEL="qwen2.5-coder:7b"
AIDER_WEAK_MODEL="qwen3:4b"
AIDER_EDITOR_MODEL="qwen2.5-coder:7b"

# --- Zed ---
ZED_MODEL="qwen2.5-coder:7b"

# --- Cursor ---
CURSOR_MODEL="qwen2.5-coder:7b"
CURSOR_MODEL_CLOUD="kimi-k2.6"

# ==============================================
# Ollama direct usage
# ==============================================
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3:14b                         interactive shell
#   ollama run deepseek-r1-tools:8b              reasoning shell
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
