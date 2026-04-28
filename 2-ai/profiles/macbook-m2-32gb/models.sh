#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - M2 Max 32GB
# ==============================================
#
# NAMING CONVENTION (Jan 2026):
#   Ollama:    model:quantization-context   (e.g., qwen3-coder-30b:q5-32k)
#   LiteLLM:  model-quantization-context (e.g., qwen3-coder-30b-q5-32k)
#
# The context size comes AFTER the quantization level.
#   OLD: qwen3-coder-30b-32k:q5  →  NEW: qwen3-coder-30b:q5-32k
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
#   :thinking → Extended chain-of-thought
#   :online   → Web search grounding
#   :extended → Longer context

# Cloud models (via OpenRouter — requires API key)
OPENROUTER_MODELS=(
    "claude-opus-4-6:cloud"                         # Claude Opus 4.6
    "claude-sonnet-4-6:cloud"                      # Claude Sonnet 4.6
    "claude-haiku-4-5:cloud"                       # Claude Haiku 4.5
    "gpt-4o:cloud"                                  # GPT-4o
    "o3:cloud"                                      # o3
    "gemini-3-flash-preview:cloud"                          # Gemini 3 Flash
    "sonar-pro:cloud"                               # Perplexity Sonar
)

# M2 Max 32GB - Standard configuration
OLLAMA_MODELS=(
    # ═══════════════════════════════════════════════════════════════════════════════
    # PRIMARY MODELS (local — pull with ollama)
    # ═══════════════════════════════════════════════════════════════════════════════

    # --- Qwen 3 (14B) ---
    "qwen3-14b"                                  # ~9 GB  | Writing, docs, cover letters

    # --- DeepSeek R1 ---
    "deepseek-r1:8b"                             # ~5 GB  | Reasoning, chat-only (no tools)

    # --- Codestral ---
    "codestral:22b"                              # ~14 GB | Code apply/insert, light coding

    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"                            # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                         # ~1 GB  | Autocomplete

    # --- Embeddings ---
    "nomic-embed-text"                            # ~0.3 GB| Embeddings (Continue/RAG)

    # --- GPT-OSS ---
    "gpt-oss:latest"                              # ~14 GB  | General purpose
    "gpt-oss:20b"                                 # ~14 GB  | Reasoning/Coding


    # ═══════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS
    # ═══════════════════════════════════════════════════════════════════════════════
    "kimi-k2.6:cloud"                               # Kimi k2.6 (long context, reasoning)
    "glm-5.1:cloud"                                # GLM 5.1 (reasoning, Chinese-optimized)
    "mistral-large-3:675b-cloud"                           # Mistral Large
    "gemini-3-flash-preview:cloud"                          # Gemini 3 Flash
    "gpt-oss:20b-cloud"                            # GPT-OSS 20B Cloud
    "gpt-oss:120b-cloud"                           # GPT-OSS 120B Cloud
)

# ----------------------------------------------
# opencode
# ----------------------------------------------
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-14b"                                          # OpenCode #1 (IndexNow benchmark)
    [think]="deepseek-r1-tools:8b"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3-14b"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-14b"                                      # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q4"                                      # next steps, task breakdown, routing
)

# ----------------------------------------------
# Continue (VS Code)
# ----------------------------------------------
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-14b"                                 # chat panel + inline edit (Ctrl+I)
    [chat_alt]="codestral:22b"                         # manual model switch in chat
    [apply]="codestral:22b"                          # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

# ----------------------------------------------
# Cline (VS Code)
# ----------------------------------------------
CLINE_MODEL="qwen3-14b"

# ----------------------------------------------
# Claude Code
# ----------------------------------------------
CLAUDE_CODE_SONNET="qwen3-14b"            # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU="qwen3-4b:q4"        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS="codestral:22b"         # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# ==============================================
# CUSTOM MODEL DEFINITIONS (pull base + ollama create)
# ==============================================
CUSTOM_MODELS=(
    # Format: "source|alias|num_ctx"
    # HF base aliases must come before derived aliases that reference them.
    # ollama pull is idempotent — re-running won't re-download if already cached.

    # ═══════════════════════════════════════════
    # HF BASE MODELS/ALIASES
    # ═══════════════════════════════════════════
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M|qwen3-4b-2507:q4||"                 # ~3 GB

    # ═══════════════════════════════════════════
    # BACKWARD-COMPAT ALIASES
    # ═══════════════════════════════════════════
    "qwen3-4b-2507:q4|qwen3-4b:q4||"

    # ═══════════════════════════════════════════
    # COMMUNITY MODEL ALIASES
    # ═══════════════════════════════════════════
    "mfdoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b||" # ~5 GB
)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3-14b                        interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------