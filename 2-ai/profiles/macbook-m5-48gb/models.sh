#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - M5 Max 48GB
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
    "sonar-pro:cloud"                               # Perplexity Sonar
)

# M5 Max 48GB - Standard configuration (local — pull with ollama)
OLLAMA_MODELS=(
    # ═══════════════════════════════════════════════════════════════════════════════
    # PRIMARY MODELS (local — pull with ollama)
    # ═══════════════════════════════════════════════════════════════════════════════

    # --- Qwen3.5 (27B) ---
    "qwen3.5:27b"                                   # ~20 GB | Writing, docs, cover letters

    # --- Qwen3.6 (35B) ---
    "qwen3.6:35b"                                  # ~35 GB | Stock (from Ollama)
    "qwen3.6:35b-8k"                            # ~35 GB | 8K context
    "qwen3.6:35b-32k"                           # ~35 GB | 32K context
    "qwen3.6:35b-128k"                          # ~35 GB | 128K context (solo only)

    # --- Qwen3 Coder 30B (A3B) ---
    "qwen3-coder-30b-a3b:q5"                       # ~21 GB | HF base (from unsloth)
    "qwen3-coder-30b:q5-32k"                       # ~21 GB | 32K context
    "qwen3-coder-30b:q5-220k"                      # ~21 GB | 220K context (solo only)

    # --- DeepSeek R1 ---
    "deepseek-r1:8b"                               # ~5 GB  | Reasoning
    "deepseek-r1-tools:8b"                         # ~5 GB  | Tool calling

    # --- Qwen3 14B ---
    "qwen3-14b:q5"                                 # ~12 GB | Research

    # --- Qwen3 4B ---
    "qwen3-4b:q4"                                   # ~3 GB | Planning fast

    # --- Codestral ---
    "codestral:22b"                                 # ~14 GB | Code

    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"                              # ~5 GB | Fast code
    "qwen2.5-coder:1.5b"                            # ~1 GB | Autocomplete

    # --- Embeddings ---
    "nomic-embed-text"                             # ~0.3 GB | Codebase/RAG

    # ═══════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS
    # ═══════════════════════════════════════════════════════════════════════════════
    "kimi-k2.6:cloud"                               # Kimi k2.6 (long context, reasoning)
    "glm-5.1:cloud"                                # GLM 5.1 (reasoning, Chinese-optimized)
    "mistral-large-3:675b-cloud"                           # Mistral Large
    "gemini-3-flash-preview:cloud"                          # Gemini 3 Flash
)

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
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL|qwen3-coder-30b-a3b:q5||"    # ~21 GB
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M|qwen3-4b-2507:q4||"                   # ~3 GB

    # ═══════════════════════════════════════════
    # DERIVED CONTEXT ALIASES
    # ═══════════════════════════════════════════
    "qwen3.6:35b|qwen3.6:35b-8k|8192|"                          # 8K ctx
    "qwen3.6:35b|qwen3.6:35b-32k|32768|"                         # 32K ctx
    "qwen3.6:35b|qwen3.6:35b-128k|131072|"                       # 128K ctx — solo only
    "qwen3-coder-30b-a3b:q5|qwen3-coder-30b:q5-32k|32768|"   # 32K ctx
    "qwen3-coder-30b-a3b:q5|qwen3-coder-30b:q5-220k|220000|"   # 220K ctx — solo only

    # ═══════════════════════════════════════════
    # BACKWARD-COMPAT ALIASES
    # ═══════════════════════════════════════════
    "qwen3-4b-2507:q4|qwen3-4b:q4||"

    # ═══════════════════════════════════════════
    # COMMUNITY MODEL ALIASES
    # ═══════════════════════════════════════════
    "dengcao/Qwen3-14B:Q5_K_M|qwen3-14b:q5||"                  # ~12 GB
    "Qwen3-14B-Q5_K_M|qwen3-14b:q5||"                          # auto-registered short name → lowercase alias
    "mfdoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b||" # ~5 GB
)


# ----------------------------------------------
# opencode agents
# ----------------------------------------------
declare -A OPENCODE_AGENTS=(
    [code]="qwen3.5:27b"                                          # OpenCode #1 (IndexNow benchmark); switch to qwen3-coder-30b:q5-32k or qwen3.6:35b-8k via picker
    [think]="deepseek-r1-tools:8b"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-14b:q5"                                     # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q4"                                          # next steps, task breakdown, routing
)

# ----------------------------------------------
# Continue (VS Code)
# ----------------------------------------------
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b:q5-32k"                  # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3.5:27b"                         # manual model switch in chat
    [apply]="codestral:22b"                          # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

# ----------------------------------------------
# Cline (VS Code)
# ----------------------------------------------
CLINE_MODEL="qwen3-coder-30b:q5-32k"

# ----------------------------------------------
# Claude Code
# ----------------------------------------------
CLAUDE_CODE_SONNET="qwen3-coder-30b:q5-32k"            # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU="qwen3-4b:q4"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS="qwen3-coder-30b:q5-220k"             # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3.6:35b-8k               interactive shell with model
#   ollama run qwen3.6:35b-128k             interactive shell with model
#   ollama run qwen3-coder-30b:q5-32k          interactive shell with model
#   ollama run qwen3-coder-30b:q5-220k         interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------