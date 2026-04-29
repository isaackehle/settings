#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - Mac Mini M2
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
    "kimi-k2.6:cloud"                               # Kimi k2.6 (long context, reasoning)
    "glm-5.1:cloud"                                # GLM 5.1 (reasoning, Chinese-optimized)
)

# Mac Mini M2 - Standard configuration (local — pull with ollama)
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
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL|qwen3-4b:q8-256k" # ~5 GB | HF base/Planning fast (256k)

    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"                            # ~5 GB  | Fast code tasks (32k)
    "qwen2.5-coder:1.5b"                         # ~1 GB  | Autocomplete (32k)

    # --- Codestral ---
    "codestral:22b"                              # ~14 GB | Code apply/insert, light coding (32k)

    # --- DeepSeek R1 ---
    "deepseek-r1:8b"                               # ~5 GB  | Reasoning, chat-only (no tools) (128k)
    "MFDoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b-128k" # ~5 GB | HF base tool calling / Tool calling alias (128k)


    # --- GPT-OSS ---
    "gpt-oss:latest"                              # ~14 GB  | General purpose (32k)
    "gpt-oss:20b"                                 # ~14 GB  | Reasoning/Coding (32k)

    # --- Embeddings ---
    "nomic-embed-text"                            # ~0.3 GB| Embeddings (Continue/RAG) (8k)

    # ═══════════════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS
    # ═══════════════════════════════════════════════════════════════════════════════════════
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
    [code]="qwen3-14b:q5-40k"                                          # OpenCode #1 (IndexNow benchmark)
    [think]="deepseek-r1-tools:8b-128k"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3-14b:q5-40k"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-14b:q5-40k"                                      # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q8-256k"                                          # next steps, task breakdown, routing
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
# Cline (VS Code)
# ----------------------------------------------
CLINE_MODEL="qwen3-14b:q5-40k"

# ----------------------------------------------
# Claude Code
# ----------------------------------------------
CLAUDE_CODE_SONNET="qwen3-14b:q5-40k"            # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU="qwen3-4b:q8-256k"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS="codestral:22b"             # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)


# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run <model>                          interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------