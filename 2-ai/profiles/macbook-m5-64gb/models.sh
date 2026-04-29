#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - M5 Max 64GB
# ==============================================
#
# NAMING CONVENTION (Jan 2026):
#   Ollama:    model:quantization-context   (e.g., qwen3-coder-30b:q6-32k)
#   LiteLLM:  model-quantization-context (e.g., qwen3-coder-30b-q6-32k)
#
# The context size comes AFTER the quantization level.
#   OLD: qwen3-coder-30b-32k:q5  →  NEW: qwen3-coder-30b:q5-32k
#
# Example: qwen3-coder:q6-32k = Q6 quantization, 32K context window
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

# M5 Max 64GB - Cloud models (via OpenRouter — requires API key)
OPENROUTER_MODELS=(
    "claude-opus-4-6:cloud"                         # Claude Opus 4.6
    "claude-sonnet-4-6:cloud"                      # Claude Sonnet 4.6
    "claude-haiku-4-5:cloud"                       # Claude Haiku 4.5
    "gpt-4o:cloud"                                  # GPT-4o
    "o3:cloud"                                      # o3
    "sonar-pro:cloud"                               # Perplexity Sonar
)

# M5 Max 64GB - Local models (pull with ollama)
OLLAMA_MODELS=(
    # ═══════════════════════════════════════════════════════════════════════════════════════
    # PRIMARY MODELS (local — pull with ollama)
    # ═══════════════════════════════════════════════════════════════════════════════════════

    # --- Qwen3 Coder Next (80B) ---
    "bazobehram/qwen3-coder-next|qwen3-coder-next-80b:q4-256k"   # ~48 GB | Primary coding model (256k)
    "qwen3-coder-next-80b:q4-256k|qwen3-coder-next-80b:q4-16k|16384|"
    "qwen3-coder-next-80b:q4-256k|qwen3-coder-next-80b:q4-64k|65536|"
    "qwen3-coder-next-80b:q4-256k|qwen3-coder-next-80b:q4-128k|131072|"

    # --- Qwen3.5 (27B) ---
    "qwen3.5:27b"                                   # ~20 GB | Writing, docs, cover letters (32k)

    # --- Qwen3.6 (35B) ---
    "fredrezones55/Qwen3.6-35B-A3B-APEX:Compact|qwen3.6:35b-256k" # ~35 GB | HF base (128k)
    "qwen3.6:35b-256k|qwen3.6:35b-8k|8192|"
    "qwen3.6:35b-256k|qwen3.6:35b-32k|32768|"
    "qwen3.6:35b-256k|qwen3.6:35b-128k|131072|"

    # --- Qwen3 Coder 30B ---
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL|qwen3-coder-30b-a3b:q6-256k" # ~26 GB | HF base (256k)
    "qwen3-coder-30b-a3b:q6-256k|qwen3-coder-30b:q6-8k|8192|"
    "qwen3-coder-30b-a3b:q6-256k|qwen3-coder-30b:q6-32k|32768|"
    "qwen3-coder-30b-a3b:q6-256k|qwen3-coder-30b:q6-128k|131072|"

    # --- DeepSeek R1 ---
    "deepseek-r1:14b"                               # ~9 GB  | Reasoning stock (128k)
    "mfdoom/deepseek-r1-tool-calling:14b|deepseek-r1-tools:14b-128k|" # HF base 14B (128k)
    "mfdoom/deepseek-r1-tool-calling:32b|deepseek-r1-tools:32b-128k|" # HF base 32B (128k)

    # --- Qwen3 32B ---
    "dengcao/Qwen3-32B:Q5_K_M|qwen3-32b:q5|"       # ~22 GB | HF base Stock/Research (32k)

    # --- Gemma 4 (31B) ---
    "gemma4:31b"                                    # ~18 GB | Reasoning (128k)

    # --- Gemma 3 (12B) ---
    "gemma3:12b"                                     # ~7 GB | General purpose (128k)

    # --- GLM-4.7 Flash ---
    "glm-4.7-flash"                                 # ~5 GB | Fast, Chinese-optimized (32k)

    # --- Phi-4 ---
    "phi4"                                          # ~9 GB | Efficient, small footprint (16k)

    # --- Codestral ---
    "codestral-22b:q8-32k|codestral-22b:q8-32k|" # ~23 GB | Code apply/insert (Q8_0) (32k)

    # --- Llama 3.3 (70B) ---
    "llama3.3:70b"                                  # ~43 GB | General purpose (solo only) (128k)

    # --- Llama 3.2 ---
    "llama3.2"                                       # ~2 GB | General purpose (128k)

    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"                              # ~4.5 GB | Fast code (32k)
    "qwen2.5-coder:1.5b"                            # ~1 GB  | Autocomplete (32k)

    # --- Qwen3 14B ---
    "dengcao/Qwen3-14B:Q8_0|qwen3-14b:q8||"         # HF base Q8 (~15 GB) (32k)
    "dengcao/Qwen3-14B:Q5_K_M|qwen3-14b:q5||"       # HF base Q5 (~12 GB) (32k)

    # --- Qwen3 4B ---
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL|qwen3-4b:q8||" # HF base (~5 GB) (32k)
    "qwen3-4b:q4"                                   # ~3 GB | Planning fast (32k)

    # --- Embeddings ---
    "nomic-embed-text"                             # ~0.3 GB | Codebase/RAG (8k)

    # ═══════════════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS
    # ═══════════════════════════════════════════════════════════════════════════════════════
    "kimi-k2.6:cloud"                               # Kimi k2.6 (long context, reasoning)
    "glm-5.1:cloud"                                # GLM 5.1 (reasoning, Chinese-optimized)
    "mistral-large-3:675b-cloud"                           # Mistral Large
    "gemini-3-flash-preview:cloud"                          # Gemini 3 Flash
    "deepseek-v4-pro:cloud"                                 # DeepSeek V4 Pro
)

# 64GB agent map
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-next-80b:q4-16k"                          # OpenCode #1 — switch to qwen3.6:35b-128k or qwen3-coder-30b:q6-32k via picker
    [think]="deepseek-r1-tools:32b-128k"                             # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                        # resumes, cover letters, docs, polished prose
    [research]="qwen3-32b:q5"                                     # codebase/web investigation
    [plan]="qwen3-4b:q8"                                         # next steps, task breakdown, routing
)

# ----------------------------------------------
# Continue (VS Code)
# ----------------------------------------------
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-next-80b:q4-16k"                    # chat panel + inline edit (Ctrl+I)
    [kimi]="kimi-k2.6:cloud"                              # Cloud-based reasoning
    [chat_alt]="qwen3.5:27b"                            # manual model switch in chat
    [apply]="codestral-22b:q8-32k"                    # applying suggested code to file (Q8_0)
    [autocomplete]="qwen2.5-coder:1.5b"                # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"            # switch manually for complex files
    [embed]="nomic-embed-text"                        # @codebase semantic search
)

# ----------------------------------------------
# Cline (VS Code)
# ----------------------------------------------
CLINE_MODEL="qwen3-coder-next-80b:q4-16k"
CLINE_MODEL_CLOUD="kimi-k2.6:cloud"

# ----------------------------------------------
# Claude Code
# ----------------------------------------------
CLAUDE_CODE_SONNET="qwen3-coder-next-80b:q4-16k"        # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU="qwen3-4b:q8"                          # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning
CLAUDE_CODE_OPUS="qwen3.6:35b-128k"                  # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3-coder-next-80b:q4-16k       interactive shell with model
#   ollama run qwen3.6:35b-128k             interactive shell with model
#   ollama stop <model>                       force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------