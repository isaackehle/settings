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

# >>> SHARED GGUF-FIRST DEFINITIONS >>>
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

declare -A GGUF_SOURCES=(
    ["codestral:22b"]="hf.co/bartowski/Codestral-22B-v0.1-GGUF"
    ["deepseek-r1:7b"]="hf.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF"
    ["nomic-embed-text"]="hf.co/nomic-ai/nomic-embed-text-v1.5-GGUF"
    ["qwen2.5-7b:multi"]="hf.co/mradermacher/Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL-GGUF"
    ["qwen2.5-coder:1.5b"]="hf.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-GGUF"
    ["qwen2.5-coder:7b"]="hf.co/unsloth/Qwen2.5-Coder-7B-Instruct-GGUF"
    ["qwen3-8b:sonnet4.5"]="hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF"
    ["qwen3:14b"]="hf.co/Qwen/Qwen3-14B-GGUF"
    ["qwen3:4b"]="hf.co/Qwen/Qwen3-4B-GGUF"
    ["qwen3.5:4b"]="hf.co/unsloth/Qwen3.5-4B-GGUF"
)

declare -A GGUF_QUANTS=(
    ["codestral:22b"]="Q4_K_M"
    ["deepseek-r1:7b"]="Q4_K_M"
    ["nomic-embed-text"]="F16"
    ["qwen2.5-7b:multi"]="Q4_K_M"
    ["qwen2.5-coder:1.5b"]="Q4_K_M"
    ["qwen2.5-coder:7b"]="Q4_K_M"
    ["qwen3-8b:sonnet4.5"]="Q4_K_M"
    ["qwen3:14b"]="Q4_K_M"
    ["qwen3:4b"]="Q4_K_M"
    ["qwen3.5:4b"]="UD-Q4_K_XL"
)

# Simplified local filenames: {alias-normalized}-{family-tag}-{quant-lower}.gguf
# Family tags:
#   -it    instruct/vision
#   -cd    coder
#   -ds    distill
#   -it-ds instruct+distill
#   -em    embedding
declare -A GGUF_LOCAL_FILENAMES=(
    ["codestral:22b"]="codestral-22b-cd-q4_k_m.gguf"
    ["deepseek-r1:7b"]="deepseek-r1-7b-ds-q4_k_m.gguf"
    ["nomic-embed-text"]="nomic-embed-text-em-f16.gguf"
    ["qwen2.5-7b:multi"]="qwen2.5-7b-multi-it-ds-q4_k_m.gguf"
    ["qwen2.5-coder:1.5b"]="qwen2.5-coder-1.5b-cd-q4_k_m.gguf"
    ["qwen2.5-coder:7b"]="qwen2.5-coder-7b-cd-q4_k_m.gguf"
    ["qwen3-8b:sonnet4.5"]="qwen3-8b-sonnet4.5-it-ds-q4_k_m.gguf"
    ["qwen3:14b"]="qwen3-14b-it-q4_k_m.gguf"
    ["qwen3:4b"]="qwen3-4b-it-q4_k_m.gguf"
    ["qwen3.5:4b"]="qwen3.5-4b-it-ud-q4_k_xl.gguf"
)

# Verbatim filenames as they appear in the Hugging Face repo.
# Used by materialize_profile_ggufs for the download request.
# When a remote filename matches the local filename, the entry can be omitted.
declare -A GGUF_REMOTE_FILENAMES=(
    ["codestral:22b"]="Codestral-22B-v0.1-Q4_K_M.gguf"
    ["deepseek-r1:7b"]="DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
    ["nomic-embed-text"]="nomic-embed-text-v1.5.f16.gguf"
    ["qwen2.5-7b:multi"]="Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL.Q4_K_M.gguf"
    ["qwen2.5-coder:1.5b"]="Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf"
    ["qwen2.5-coder:7b"]="Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf"
    ["qwen3-8b:sonnet4.5"]="Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf"
    ["qwen3:14b"]="Qwen3-14B-Q4_K_M.gguf"
    ["qwen3:4b"]="Qwen3-4B-Q4_K_M.gguf"
    ["qwen3.5:4b"]="Qwen3.5-4B-UD-Q4_K_XL.gguf"
)

declare -A GGUF_FAMILIES=(
    ["codestral:22b"]="coder"
    ["deepseek-r1:7b"]="reasoning-tools"
    ["nomic-embed-text"]="embedding"
    ["qwen2.5-7b:multi"]="instruct-distill"
    ["qwen2.5-coder:1.5b"]="coder"
    ["qwen2.5-coder:7b"]="coder"
    ["qwen3-8b:sonnet4.5"]="instruct-distill"
    ["qwen3:14b"]="instruct"
    ["qwen3:4b"]="instruct"
    ["qwen3.5:4b"]="instruct"
)

declare -A GGUF_VARIANTS=()

declare -A OLLAMA_CONTEXT_WINDOWS=(
    ["deepseek-r1:7b"]="131072"
    ["deepseek-r1-tools:8b"]="131072"
    ["nomic-embed-text"]="8192"
    ["qwen2.5-7b:multi"]="1010000"
    ["qwen2.5-coder:7b"]="32768"
    ["qwen3-8b:sonnet4.5"]="40960"
    ["qwen3:14b"]="262144"
    ["qwen3:4b"]="131072"
    ["qwen3.5:4b"]="131072"
)

declare -A MODELFILE_PARAMS=(
    ["deepseek-r1:7b"]="PARAMETER temperature 0.3"
    ["deepseek-r1-tools:8b"]="PARAMETER temperature 0.3"
    ["qwen2.5-7b:multi"]="PARAMETER temperature 0.6"
    ["qwen2.5-coder:7b"]="PARAMETER temperature 0\nPARAMETER repeat_penalty 1.05"
    ["qwen3-8b:sonnet4.5"]="PARAMETER temperature 0.6"
    ["qwen3:14b"]="PARAMETER temperature 0.5"
    ["qwen3:4b"]="PARAMETER temperature 0.2"
    ["deepseek-r1-tools:8b"]="PARAMETER temperature 0.3"
    ["qwen3.5:4b"]="PARAMETER temperature 0.2"
)

declare -A MODEL_REMOTES=(
    ["deepseek-r1-tools:8b"]="MFDoom/deepseek-r1-tool-calling:8b"
)
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
# ALTERNATIVE QUANTS — on-demand only
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen2.5-coder"]="qwen2.5-coder:7b:q8_0|qwen2.5-coder:7b:q8|8 GB (solo coding)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS — auto-created during install
# ==============================================

# ==============================================
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen2.5-coder:7b"                  # primary coding agent
    [plan]="qwen3:4b"                          # next steps, task breakdown, routing
    [research]="qwen2.5-coder:7b"              # codebase/web investigation
    [think]="deepseek-r1:7b"                   # tradeoff analysis, debugging strategy
    [write]="qwen2.5-coder:7b"                 # resumes, cover letters, docs
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [apply]="qwen2.5-coder:7b"                 # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"        # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"    # switch manually for complex files
    [chat]="qwen2.5-coder:7b"                  # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen2.5-coder:7b"              # manual model switch in chat
    [embed]="nomic-embed-text"                 # @codebase semantic search
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