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
#   Resident:    30B-coder-q5 (21 GB) + 4B (5 GB) + 1.5B (1 GB) + embed (0.3 GB) = 27.3 GB ✓
#   Reasoning:   Unload coder-30B, load r1-tools:32b (20 GB) + 4B + 1.5B + embed = 26.3 GB ✓
#   Writing:     Unload coder-30B, load 27B-q8 (29 GB) + 4B + 1.5B + embed = 35.3 GB ✓
#   Gemma:       Unload coder-30B, load gemma4:31b (20 GB) + 4B + 1.5B + embed = 26.3 GB ✓
#   Codestral & autocomplete-heavy are on-demand only

# >>> SHARED GGUF-FIRST DEFINITIONS >>>
# ----------------------------------------------------------------------
# LLAMA.CPP-FIRST ADDITIONS
# ----------------------------------------------------------------------
# The sections below preserve the current Ollama-oriented structure while
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
    ["heavy"]="qwen3.6-35b:opus4.6"
    ["reasoning"]="deepseek-r1:32b"
    ["embedding"]="nomic-embed-text"
)

# ==============================================
# GGUF SOURCE METADATA — minimal install/runtime metadata
# ==============================================
declare -A GGUF_SOURCES=(
    ["qwen3:4b"]="hf.co/Qwen/Qwen3-4B-GGUF"
    ["qwen3.5-27b:q4"]="hf.co/Jackrong/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    ["qwen3-coder-30b-a3b:q5"]="hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF"
    ["qwen3.6-35b:opus4.6"]="hf.co/hesamation/Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-GGUF"
    ["deepseek-r1:32b"]="hf.co/bartowski/DeepSeek-R1-Distill-Qwen-32B-GGUF"
    ["qwen2.5-coder:1.5b"]="hf.co/Qwen/Qwen2.5-Coder-1.5B-Instruct-GGUF"
    ["qwen2.5-coder:7b"]="hf.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF"
    ["codestral:22b"]="hf.co/bartowski/Codestral-22B-v0.1-GGUF"
    ["gemma4:31b"]="hf.co/google/gemma-4-31b-it-GGUF"
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
    ["qwen3-coder-30b-a3b:q5"]="Q5_K_M"
    ["qwen3.6-35b:opus4.6"]="Q4_K_M"
    ["deepseek-r1:32b"]="Q4_K_M"
    ["qwen2.5-coder:1.5b"]="Q4_K_M"
    ["qwen2.5-coder:7b"]="Q4_K_M"
    ["codestral:22b"]="Q4_K_M"
    ["gemma4:31b"]="Q4_K_M"
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
    ["qwen3-coder-30b-a3b:q5"]="qwen3-coder-30b-a3b-cd-q5_k_m.gguf"
    ["qwen3.6-35b:opus4.6"]="qwen3.6-35b-opus4.6-it-ds-q4_k_m.gguf"
    ["deepseek-r1:32b"]="deepseek-r1-32b-ds-q4_k_m.gguf"
    ["qwen2.5-coder:1.5b"]="qwen2.5-coder-1.5b-cd-q4_k_m.gguf"
    ["qwen2.5-coder:7b"]="qwen2.5-coder-7b-cd-q4_k_m.gguf"
    ["codestral:22b"]="codestral-22b-cd-q4_k_m.gguf"
    ["gemma4:31b"]="gemma4-31b-it-q4_k_m.gguf"
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
    ["qwen3-coder-30b-a3b:q5"]="Qwen3-Coder-30B-A3B-Instruct-Q5_K_M.gguf"
    ["qwen3.6-35b:opus4.6"]="Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled.Q4_K_M.gguf"
    ["deepseek-r1:32b"]="DeepSeek-R1-Distill-Qwen-32B-Q4_K_M.gguf"
    ["qwen2.5-coder:1.5b"]="qwen2.5-coder-1.5b-instruct-q4_k_m.gguf"
    ["qwen2.5-coder:7b"]="qwen2.5-coder-7b-instruct-q4_k_m.gguf"
    ["codestral:22b"]="Codestral-22B-v0.1-Q4_K_M.gguf"
    ["gemma4:31b"]="gemma-4-31b-it-Q4_K_M.gguf"
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
    ["qwen3-coder-30b-a3b:q5"]="coder"
    ["qwen3.6-35b:opus4.6"]="instruct-distill"
    ["deepseek-r1:32b"]="reasoning-tools"
    ["qwen2.5-coder:1.5b"]="coder"
    ["qwen2.5-coder:7b"]="coder"
    ["codestral:22b"]="coder"
    ["gemma4:31b"]="vision-instruct"
    ["nomic-embed-text"]="embedding"
    ["qwen3.5:4b"]="instruct"
    ["qwen2.5-7b:multi"]="instruct-distill"
    ["qwen3.5-27b:gemini3.1"]="instruct-distill"
    ["qwen3-8b:sonnet4.5"]="instruct-distill"
    ["qwen3-14b:sonnet4.5"]="instruct-distill"
    ["qwen3.6-27b:opus-sonnet"]="instruct-distill"
)

declare -A GGUF_VARIANTS=(
    ["qwen3-coder-30b-a3b:q5"]="Q6_K|qwen3-coder-30b-a3b-cd-q6_k.gguf|hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF|Qwen3-Coder-30B-A3B-Instruct-Q6_K.gguf"
)

declare -A OLLAMA_CONTEXT_WINDOWS=(
    ["deepseek-r1:32b"]="131072"
    ["nomic-embed-text"]="8192"
    ["qwen3-coder-30b-a3b:q5"]="32768"
    ["qwen3.5-27b:q4"]="32768"
    ["qwen3.6-35b:opus4.6"]="32768"
    ["qwen3:4b"]="131072"
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
    ["qwen3-coder-30b-a3b:q5"]="PARAMETER temperature 0\nPARAMETER repeat_penalty 1.05"
    ["qwen3.6-35b:opus4.6"]="PARAMETER temperature 0.5"
    ["deepseek-r1:32b"]="PARAMETER temperature 0.3"
    ["qwen3.5:4b"]="PARAMETER temperature 0.2"
    ["qwen2.5-7b:multi"]="PARAMETER temperature 0.6"
    ["qwen3.5-27b:gemini3.1"]="PARAMETER temperature 0.6"
    ["qwen3-8b:sonnet4.5"]="PARAMETER temperature 0.6"
    ["qwen3-14b:sonnet4.5"]="PARAMETER temperature 0.6"
    ["qwen3.6-27b:opus-sonnet"]="PARAMETER temperature 0.6"
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
# ALTERNATIVE QUANTS
# Pull on-demand: ollama pull <full-tag>
# ==============================================
declare -A MODEL_QUANTS=(
    ["qwen3-coder-30b-a3b"]="qwen3-coder-30b-a3b:q8|qwen3-coder-30b-a3b:q8|32 GB (solo coding)"
    ["qwen3.5-27b"]="qwen3.5-27b:q4|qwen3.5-27b:q4|19 GB (writing / research)"
    ["qwen3.6-35b:opus4.6"]="qwen3.6-35b:opus4.6:q8_0|qwen3.6-35b:opus4.6:q8|36 GB (agentic reasoning)"
)

# ==============================================
# CONTEXT WINDOW VARIANTS
# Created via ollama create during setup (share weights, zero extra disk).
# ==============================================

# ==============================================
# TOOL ASSIGNMENTS
# All use plain Ollama model names. Tools connect to :11434/v1.
# ==============================================

# --- OpenCode agents ---
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-30b-a3b:q5"         # primary coding agent
    [think]="deepseek-r1:32b"          # tradeoff analysis, debugging strategy
    [write]="qwen3.5-27b:q4"                # resumes, cover letters, polished prose
    [research]="qwen3-coder-30b-a3b:q5"      # codebase/web investigation
    [plan]="qwen3:4b"                        # next steps, task breakdown, routing
)

# --- Continue (VS Code) ---
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b-a3b:q5"          # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3.5-27b:q4"              # manual model switch in chat
    [apply]="codestral:22b"                   # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"       # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"   # switch manually for complex files
    [embed]="nomic-embed-text"               # @codebase semantic search
)

# --- Claude Code ---
declare -A CLAUDE_CODE=(
    [primary]="qwen3-coder-30b-a3b:q5"
    [fast]="qwen3:4b"
    [reasoning]="deepseek-r1:32b"
    [research]="qwen3-coder-30b-a3b:q5"
    [coding]="qwen3-coder-30b-a3b:q5"
    [opus]="qwen3.6-35b:opus4.6"
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
    [model]="qwen3-coder-30b-a3b:q5"
)

# --- Zoo Code (VS Code extension) ---
declare -A ZOOCODE_MODELS=(
    [architect]="qwen3-coder-30b-a3b:q5"
    [cloud]="kimi-k2.6"
    [code]="qwen3-coder-30b-a3b:q5"
    [debug]="deepseek-r1:32b"
    [model]="qwen3-coder-30b-a3b:q5"
)
