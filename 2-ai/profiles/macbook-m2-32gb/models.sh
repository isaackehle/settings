#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - M2 Max 32GB
# ==============================================
#
# NAMING CONVENTION (Jan 2026):
#   Ollama:    model:quantization-context   (e.g., qwen3-coder:q5-32k)
#   LiteLLM:  model-quantization-context (e.g., qwen3-coder-q5-32k)
#
# The context size comes AFTER the quantization level.
#   OLD: qwen3-coder-32k:q5  →  NEW: qwen3-coder:q5-32k
#
# Example: qwen3-coder:q5-32k = Q5 quantization, 32K context window
#
# When adding, removing, or renaming models here, also update:
#   config/profile.d/_computer_profile   vault alias — per-machine model selection

# ==============================================
# MODEL REFERENCE
# ==============================================
#
# CLOUD MODELS (via OpenRouter):
#   Claude Opus 4.6     → anthropic/claude-opus-4-6
#   Claude Sonnet 4.6   → anthropic/claude-sonnet-4-6
#   Claude Haiku 4.5    → anthropic/claude-haiku-4-5
#   GPT-4o              → openai/gpt-4o
#   o3                  → openai/o3
#   Gemini 2.5 Pro      → google/gemini-2.5-pro
#   Mistral Large       → mistralai/mistral-large
#   Perplexity Sonar    → perplexity/sonar-pro
#   Kimi k2.6          → moonshot/kimi-k2.6
#   GLM 5.1            → thudm/glm-5.1
#
# EMBEDDINGS:
#   Nomic Embed         → nomic-embed-text
#
# OPENROUTER VARIANTS (append to model ID):
#   :free     → Free tier (rate-limited)
#   :nitro    → Fastest provider
#   :online   → Web search grounding
#   :extended → Longer context

# Cloud models (via OpenRouter — requires API key)
OPENROUTER_MODELS=(
    "claude-opus-4-6:cloud"
    "claude-sonnet-4-6:cloud"
    "claude-haiku-4-5:cloud"
    "gpt-4o:cloud"
    "o3:cloud"
    "sonar-pro:cloud"
)

# M2 Max 32GB - Standard configuration (local — pull with ollama)
OLLAMA_MODELS=(
    # ═══════════════════════════════════════════════════════════════════════════════════════
    # PRIMARY MODELS (local — pull with ollama)
    # ═══════════════════════════════════════════════════════════════════════════════════════

    # --- Qwen 3.5 (27B) Claude 4.6 Opus ---
    "sinhang/qwen3.5-claude-4.6-opus:27b-q5_K_M|qwen3.5-27b:q5-256k" # ~19 GB | Writing, docs, cover letters / Image
    "qwen3.5-27b:q5-256k|qwen3.5-27b:q5-8k|8192"
    "qwen3.5-27b:q5-256k|qwen3.5-27b:q5-32k|32768"
    "qwen3.5-27b:q5-256k|qwen3.5-27b:q5-128k|131072"

    # --- Qwen 3 (14B) ---
    "richardyoung/qwen3-14b-abliterated:q8_0|qwen3-14b:q8-40k"         # base Q8 (16 GB) Research (40k)
    "richardyoung/qwen3-14b-abliterated:Q5_K_M|qwen3-14b:q5-40k"       # base Q5 (11 GB) Research (40k)

    # --- Qwen 3 (4B) ---
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_XL|qwen3-4b:q4-256k" # ~3 GB | HF base/Planning fast (32k)

    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"              # ~5 GB  | Fast code tasks (32k)
    "qwen2.5-coder:1.5b"            # ~1 GB  | Autocomplete (32k)

    # --- Codestral ---
    "codestral:22b"                 # ~14 GB | Code apply/insert, light coding (32k)

    # --- DeepSeek R1 ---
    "deepseek-r1:8b"                                                                            # 5.2 GB  | Reasoning, chat-only (no tools) (128k)
    "deepseek-r1:8b-llama-distill-q8_0|deepseek-r1-8b:q8-128k"                                  # 8.5 GB
    "deepseek-r1:14b"                               # 9 GB
    "deepseek-r1:14b-qwen-distill-q8_0|deepseek-r1-14b:q8-128k"                                 # 16 GB  | Reasoning stock (128k)
    "MFDoom/deepseek-r1-tool-calling:8b-llama-distill-q4_K_M|deepseek-r1-tools-8b:q4-128k"      # ~5 GB | HF base tool calling / Tool calling alias (128k)
    "MFDoom/deepseek-r1-tool-calling:8b-llama-distill-q8_0|deepseek-r1-tools-8b:q8-128k"        # 9 GB  | HF base 14B (128k)

    # --- GPT-OSS ---
    "gpt-oss"                       # ~14 GB  | General purpose/Reasoning/Coding (32k)

    # --- Embeddings ---
    "nomic-embed-text"                     # ~0.3 GB| Embeddings (Continue/RAG) (8k)

    # ═══════════════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS
    # ═══════════════════════════════════════════════════════════════════════════════════════
    "deepseek-v4-pro:cloud"
    "gemini-3-flash-preview:cloud"
    "glm-5.1:cloud"
    "gpt-oss:120b-cloud"
    "gpt-oss:20b-cloud"
    "kimi-k2.6:cloud"
    "mistral-large-3:675b-cloud"
)

# ----------------------------------------------
# opencode
# ----------------------------------------------
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-14b:q5-40k"                                          # OpenCode #1 (IndexNow benchmark)
    [think]="deepseek-r1-tools-8b:q4-128k"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3-14b:q5-40k"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-14b:q5-40k"                                      # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q4-256k"                                          # next steps, task breakdown, routing
)

# ----------------------------------------------
# Continue (VS Code)
# ----------------------------------------------
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-14b:q5-40k"                                 # chat panel + inline edit (Ctrl+I)
    [chat_alt]="codestral:22b"                         # manual model switch in chat
    [apply]="codestral:22b"                          # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

# ----------------------------------------------
# Claude Code
# ----------------------------------------------
declare -A CLAUDE_CODE=(
    [primary]="qwen3-14b:q5-40k"
    [fast]="qwen3-4b:q4-256k"
    [reasoning]="deepseek-r1-tools-8b:q4-128k"
    [opus]="codestral:22b"
)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run <model>                          interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------

# ----------------------------------------------
# Cline (VS Code)
# ----------------------------------------------
CLINE_MODEL="qwen3-14b:q8-40k"
CLINE_MODEL_CLOUD="kimi-k2.6:cloud"

# ----------------------------------------------
# Roo Code (VS Code)
# ----------------------------------------------
ROOCODE_MODEL="qwen3-14b:q8-40k"
ROOCODE_MODEL_CLOUD="kimi-k2.6:cloud"
ROOCODE_MODE_CODE="qwen3-14b:q8-40k"
ROOCODE_MODE_ARCHITECT="qwen3.5-27b:q5-32k"
ROOCODE_MODE_ASK="qwen3-14b:q8-40k"
ROOCODE_MODE_DEBUG="deepseek-r1-tools-8b:q4-128k"

# ----------------------------------------------
# Kilo Code (VS Code)
# ----------------------------------------------
KILOCODE_MODEL="qwen3-14b:q8-40k"
KILOCODE_MODEL_CLOUD="kimi-k2.6:cloud"

# ----------------------------------------------
# Aider
# ----------------------------------------------
AIDER_MODEL="qwen3-14b:q8-40k"
AIDER_WEAK_MODEL="qwen3-4b:q4-256k"
AIDER_EDITOR_MODEL="codestral:22b"

# ----------------------------------------------
# Zed
# ----------------------------------------------
ZED_MODEL="qwen3.5-27b:q5-32k"

# ----------------------------------------------
# Cursor
# ----------------------------------------------
CURSOR_MODEL="qwen3-14b:q8-40k"
CURSOR_MODEL_CLOUD="kimi-k2.6:cloud"
