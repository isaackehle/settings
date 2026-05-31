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
    ["fast"]="qwen3:4b"
    ["general"]="qwen3.5-27b:q4"
    ["coder"]="qwen3-coder-30b-a3b:q5"
    ["heavy"]="qwen3:14b"
    ["reasoning"]="deepseek-r1:7b"
    ["embedding"]="nomic-embed-text"
)

declare -A GGUF_SOURCES=(
    ["qwen3:4b"]="hf.co/Qwen/Qwen3-4B-GGUF"
    ["qwen3.5-27b:q4"]="hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    ["qwen3-coder-30b-a3b:q5"]="hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF"
    ["qwen3:14b"]="hf.co/Qwen/Qwen3-14B-GGUF"
    ["deepseek-r1:7b"]="hf.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF"
    ["qwen2.5-coder:1.5b"]="hf.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF"
    ["qwen2.5-coder:7b"]="hf.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF"
    ["codestral:22b"]="hf.co/bartowski/Codestral-22B-v0.1-GGUF"
    ["nomic-embed-text"]="hf.co/nomic-ai/nomic-embed-text-v1.5-GGUF"
    ["qwen3.5:4b"]="hf.co/unsloth/Qwen3.5-4B-GGUF"
    ["qwen2.5-7b:multi"]="hf.co/mradermacher/Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL-GGUF"
    ["qwen3.5-9b:opus4.6"]="hf.co/Jackrong/Qwen3.5-9B-Claude-4.6-Opus-Reasoning-Distilled-v2-GGUF"
    ["qwen3.5-9b:gemini3.1"]="hf.co/Jackrong/Qwen3.5-9B-Gemini-3.1-Pro-Reasoning-Distill-GGUF"
    ["qwen3-8b:sonnet4.5"]="hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF"
    ["qwen3-14b:sonnet4.5"]="hf.co/TeichAI/Qwen3-14B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF"
)

declare -A GGUF_QUANTS=(
    ["qwen3:4b"]="Q4_K_M"
    ["qwen3.5-27b:q4"]="Q4_K_M"
    ["qwen3-coder-30b-a3b:q5"]="Q5_K_M"
    ["qwen3:14b"]="Q4_K_M"
    ["deepseek-r1:7b"]="Q4_K_M"
    ["qwen2.5-coder:1.5b"]="Q4_K_M"
    ["qwen2.5-coder:7b"]="Q4_K_M"
    ["codestral:22b"]="Q4_K_M"
    ["nomic-embed-text"]="F16"
    ["qwen3.5:4b"]="Q4_K_M"
    ["qwen2.5-7b:multi"]="Q4_K_M"
    ["qwen3.5-9b:opus4.6"]="Q4_K_M"
    ["qwen3.5-9b:gemini3.1"]="Q4_K_M"
    ["qwen3-8b:sonnet4.5"]="Q4_K_M"
    ["qwen3-14b:sonnet4.5"]="Q4_K_M"
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
    ["qwen3-coder-30b-a3b:q5"]="qwen3-coder-30b-a3b-cd-q5_k_m.gguf"
    ["qwen3:14b"]="qwen3-14b-it-q4_k_m.gguf"
    ["deepseek-r1:7b"]="deepseek-r1-7b-ds-q4_k_m.gguf"
    ["qwen2.5-coder:1.5b"]="qwen2.5-coder-1.5b-cd-q4_k_m.gguf"
    ["qwen2.5-coder:7b"]="qwen2.5-coder-7b-cd-q4_k_m.gguf"
    ["codestral:22b"]="codestral-22b-cd-q4_k_m.gguf"
    ["nomic-embed-text"]="nomic-embed-text-em-f16.gguf"
    ["qwen3.5:4b"]="qwen3.5-4b-it-q4_k_m.gguf"
    ["qwen2.5-7b:multi"]="qwen2.5-7b-multi-it-ds-q4_k_m.gguf"
    ["qwen3.5-9b:opus4.6"]="qwen3.5-9b-opus4.6-it-ds-q4_k_m.gguf"
    ["qwen3.5-9b:gemini3.1"]="qwen3.5-9b-gemini3.1-it-ds-q4_k_m.gguf"
    ["qwen3-8b:sonnet4.5"]="qwen3-8b-sonnet4.5-it-ds-q4_k_m.gguf"
    ["qwen3-14b:sonnet4.5"]="qwen3-14b-sonnet4.5-it-ds-q4_k_m.gguf"
)

# Verbatim filenames as they appear in the Hugging Face repo.
declare -A GGUF_REMOTE_FILENAMES=(
    ["qwen3:4b"]="Qwen3-4B-Q4_K_M.gguf"
    ["qwen3.5-27b:q4"]="Qwen3.5-27B.Q4_K_M.gguf"
    ["qwen3-coder-30b-a3b:q5"]="Qwen3-Coder-30B-A3B-Instruct-Q5_K_M.gguf"
    ["qwen3:14b"]="Qwen3-14B-Q4_K_M.gguf"
    ["deepseek-r1:7b"]="DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"
    ["qwen2.5-coder:1.5b"]="qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
    ["qwen2.5-coder:7b"]="qwen2.5-coder-7b-instruct-q4_k_m.gguf"
    ["codestral:22b"]="Codestral-22B-v0.1-Q4_K_M.gguf"
    ["nomic-embed-text"]="nomic-embed-text-v1.5.f16.gguf"
    ["qwen3.5:4b"]="Qwen3.5-4B-Q4_K_M.gguf"
    ["qwen2.5-7b:multi"]="Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL.Q4_K_M.gguf"
    ["qwen3.5-9b:opus4.6"]="Qwen3.5-9B.Q4_K_M.gguf"
    ["qwen3.5-9b:gemini3.1"]="Qwen3.5-9B.Q4_K_M.gguf"
    ["qwen3-8b:sonnet4.5"]="Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf"
    ["qwen3-14b:sonnet4.5"]="Qwen3-14B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf"
)

declare -A GGUF_FAMILIES=(
    ["qwen3:4b"]="instruct"
    ["qwen3.5-27b:q4"]="instruct-distill"
    ["qwen3-coder-30b-a3b:q5"]="coder"
    ["qwen3:14b"]="instruct"
    ["deepseek-r1:7b"]="reasoning-tools"
    ["qwen2.5-coder:1.5b"]="coder"
    ["qwen2.5-coder:7b"]="coder"
    ["codestral:22b"]="coder"
    ["nomic-embed-text"]="embedding"
    ["qwen3.5:4b"]="instruct"
    ["qwen2.5-7b:multi"]="instruct-distill"
    ["qwen3.5-9b:opus4.6"]="instruct-distill"
    ["qwen3.5-9b:gemini3.1"]="instruct-distill"
    ["qwen3-8b:sonnet4.5"]="instruct-distill"
    ["qwen3-14b:sonnet4.5"]="instruct-distill"
)

declare -A GGUF_VARIANTS=(
    ["qwen3.5-27b:q4"]="Q8_0|qwen3.5-27b-opus4.6-it-ds-q8_0.gguf|hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF|Qwen3.5-27B.Q8_0.gguf"
)

declare -A OLLAMA_CONTEXT_WINDOWS=(
    ["deepseek-r1:7b"]="131072"
    ["nomic-embed-text"]="8192"
    ["qwen3-coder-30b-a3b:q5"]="32768"
    ["qwen3.5-27b:q4"]="32768"
    ["qwen3:14b"]="262144"
    ["qwen3:4b"]="131072"
    ["qwen3.5:4b"]="131072"
    ["qwen2.5-7b:multi"]="1010000"
    ["qwen3.5-9b:opus4.6"]="262144"
    ["qwen3.5-9b:gemini3.1"]="262144"
    ["qwen3-8b:sonnet4.5"]="40960"
    ["qwen3-14b:sonnet4.5"]="40960"
)

declare -A MODELFILE_PARAMS=(
    ["qwen3:4b"]="PARAMETER temperature 0.2"
    ["qwen3.5-27b:q4"]="PARAMETER temperature 0.6"
    ["qwen3-coder-30b-a3b:q5"]="PARAMETER temperature 0\nPARAMETER repeat_penalty 1.05"
    ["qwen3:14b"]="PARAMETER temperature 0.5"
    ["deepseek-r1:7b"]="PARAMETER temperature 0.3"
    ["qwen3.5:4b"]="PARAMETER temperature 0.2"
    ["qwen2.5-7b:multi"]="PARAMETER temperature 0.6"
    ["qwen3.5-9b:opus4.6"]="PARAMETER temperature 0.6"
    ["qwen3.5-9b:gemini3.1"]="PARAMETER temperature 0.6"
    ["qwen3-8b:sonnet4.5"]="PARAMETER temperature 0.6"
    ["qwen3-14b:sonnet4.5"]="PARAMETER temperature 0.6"
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
# TOOL ASSIGNMENTS — consumed by deploy scripts to generate configs
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-30b-a3b:q5"          # primary coding agent
    [think]="deepseek-r1:7b"            # tradeoff analysis, debugging strategy
    [write]="qwen3.5-27b:q4"                 # resumes, cover letters, polished prose
    [research]="qwen3-coder-30b-a3b:q5"      # codebase/web investigation
    [plan]="qwen3:4b"                        # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b-a3b:q5"          # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3.5-27b:q4"               # manual model switch in chat
    [apply]="codestral:22b"                   # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"        # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"   # switch manually for complex files
    [embed]="nomic-embed-text"               # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3-coder-30b-a3b:q5"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1:7b"
    [research]="qwen3-coder-30b-a3b:q5"
    [coding]="qwen3-coder-30b-a3b:q5"
    [opus]="qwen3.5-27b:q4"
)

# --- Aider (CLI) ---
declare -A AIDER_MODELS=(
    [editor]="codestral:22b"
    [model]="qwen3-coder-30b-a3b:q5"
    [weak]="qwen3:4b"
)

# --- Cline (VS Code) ---
declare -A CLINE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-30b-a3b:q5"
)

# --- Cursor ---
declare -A CURSOR_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-30b-a3b:q5"
)

# --- Kilo Code (VS Code) ---
declare -A KILOCODE_MODELS=(
    [cloud]="kimi-k2.6"
    [model]="qwen3-coder-30b-a3b:q5"
)

# --- Zed ---
declare -A ZED_MODELS=(
    [model]="qwen3.5-27b:q4"
)

# --- Zoo Code (VS Code extension) ---
declare -A ZOOCODE_MODELS=(
    [architect]="qwen3-coder-30b-a3b:q5"
    [cloud]="kimi-k2.6"
    [code]="qwen3-coder-30b-a3b:q5"
    [debug]="deepseek-r1:7b"
    [model]="qwen3-coder-30b-a3b:q5"
)
