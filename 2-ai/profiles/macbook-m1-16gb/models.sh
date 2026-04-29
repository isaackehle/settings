#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - MacBook M1 16GB
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
    "claude-opus-4-6:cloud"                         # Claude Opus 4.6
    "claude-sonnet-4-6:cloud"                      # Claude Sonnet 4.6
    "claude-haiku-4-5:cloud"                       # Claude Haiku 4.5
    "gpt-4o:cloud"                                  # GPT-4o
    "o3:cloud"                                      # o3
    "sonar-pro:cloud"                               # Perplexity Sonar
)

# M1 16GB - Lightweight configuration
OLLAMA_MODELS=(
    # ═══════════════════════════════════════════════════════════════════════════════
    # PRIMARY MODELS (local — pull with ollama)
    # ═══════════════════════════════════════════════════════════════════════════════

    # --- Qwen 3.5 (27B) Claude 4.6 Opus ---
    "sinhang/qwen3.5-claude-4.6-opus:27b-q5_K_M|qwen3.5-27b:q5-256k" # ~19 GB | Writing, docs, cover letters / Image
    "qwen3.5-27b:q5-256k|qwen3.5-27b:q5-8k|8192"
    "qwen3.5-27b:q5-256k|qwen3.5-27b:q5-32k|32768"
    "qwen3.5-27b:q5-256k|qwen3.5-27b:q5-128k|131072"

    # --- Qwen 3 (14b) ---
    "richardyoung/qwen3-14b-abliterated:Q4_K_M|qwen3-14b:q4-40k" # ~9 GB | HF base / Research (40k)

    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"                            # ~5 GB   | Fast code tasks (32k)
    "qwen2.5-coder:1.5b"                          # ~1 GB   | Autocomplete (32k)

    # --- DeepSeek R1 ---
    "deepseek-r1:8b"                               # ~5 GB  | Reasoning, chat-only (no tools) (128k)
    "MFDoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b-128k" # ~5 GB | HF base tool calling / Tool calling alias (128k)

    # --- GPT-OSS ---
    "gpt-oss:latest"                              # ~14 GB  | General purpose (32k)
    "gpt-oss:20b"                                 # ~14 GB  | Reasoning/Coding (32k)

    # --- Embeddings ---
    "nomic-embed-text"                            # ~0.3 GB | Embeddings (Continue/RAG) (8k)

    # ═══════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS
    # ═══════════════════════════════════════════════════════════════════════════════
    "kimi-k2.6:cloud"                               # Kimi k2.6 (long context, reasoning)
    "glm-5.1:cloud"                                # GLM 5.1 (reasoning, Chinese-optimized)
    "mistral-large-3:675b-cloud"                           # Mistral Large
    "gemini-3-flash-preview:cloud"                          # Gemini 3 Flash
    "gpt-oss:20b-cloud"                            # GPT-OSS 20B Cloud
    "gpt-oss:120b-cloud"                           # GPT-OSS 120B Cloud
    "deepseek-v4-pro:cloud"                                 # DeepSeek V4 Pro
)

# ----------------------------------------------
# opencode
# ----------------------------------------------
declare -A OPENCODE_AGENTS=(
    [code]="qwen2.5-coder:7b"                                 # OpenCode #1 (IndexNow benchmark)
    [think]="deepseek-r1-tools:8b-128k"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen2.5-coder:7b"                               # resumes, cover letters, docs
    [research]="qwen2.5-coder:7b"                             # codebase investigation
    [plan]="qwen2.5-coder:1.5b"                              # next steps, task breakdown
)

# ----------------------------------------------
# Continue (VS Code)
# ----------------------------------------------
declare -A CONTINUE_ROLES=(
    [chat]="qwen2.5-coder:7b"                                # chat panel + inline edit (Ctrl+I)
    [chat_alt]="codestral:22b"                                # manual model switch in chat
    [apply]="qwen2.5-coder:7b"                               # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"                     # inline completions (default)
    [embed]="nomic-embed-text"                                # @codebase semantic search
)

# ----------------------------------------------
# Cline (VS Code)
# ----------------------------------------------
CLINE_MODEL="qwen2.5-coder:7b"

# ----------------------------------------------
# Claude Code
# ----------------------------------------------
CLAUDE_CODE_HAIKU="qwen2.5-coder:1.5b"                     # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run <model>                          interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------