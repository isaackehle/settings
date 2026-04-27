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
#   :thinking → Extended chain-of-thought
#   :online   → Web search grounding
#   :extended → Longer context

# M5 Max 64GB - Extended configuration
MODELS=(
    # ═══════════════════════════════════════════════════════════════════════════════
    # CLOUD MODELS (via OpenRouter — requires API key)
    # ═══════════════════════════════════════════════════════════════════════════════
    "claude-opus-4-6:cloud"                         # Claude Opus 4.6
    "claude-sonnet-4-6:cloud"                      # Claude Sonnet 4.6
    "claude-haiku-4-5:cloud"                       # Claude Haiku 4.5
    "gpt-4o:cloud"                                  # GPT-4o
    "o3:cloud"                                      # o3
    "gemini-2.5-pro:cloud"                          # Gemini 2.5 Pro
    "mistral-large:cloud"                           # Mistral Large
    "sonar-pro:cloud"                               # Perplexity Sonar
    "kimi-k2.6:cloud"                               # Kimi k2.6 (long context, reasoning)
    "glm-5.1:cloud"                                # GLM 5.1 (reasoning, Chinese-optimized)
    
    # ═══════════════════════════════════════════════════════════════════════════════
    # PRIMARY MODELS (local — pull with ollama)
    # ═══════════════════════════════════════════════════════════════════════════════
    
    # --- Qwen3 Coder Next (80B) --- NEW Jan 2026 ---
    "qwen3-coder-next-80b:q4"                        # ~48 GB | Primary coding model
    "qwen3-coder-next-80b:q4-16k"                  # ~48 GB | 16K ctx variant
    "qwen3-coder-next-80b:q4-64k"                  # ~48 GB | 64K ctx variant
    
    # --- Qwen3.5 (27B) --- #1 on IndexNow benchmark
    "qwen3.5:27b"                                   # ~20 GB | Writing, docs, cover letters
    
    # --- Qwen3.6 (35B) ---
    "qwen3.6:35b"                                   # ~35 GB | Stock (from Ollama)
    "qwen3.6:35b:q5-8k"                            # ~35 GB | 8K context
    "qwen3.6:35b:q5-128k"                          # ~35 GB | 128K context (solo only)
    
    # --- Qwen3 Coder 30B (A3B) ---
    "qwen3-coder-30b-a3b:q6"                       # ~26 GB | HF base (from unsloth)
    "qwen3-coder-30b:q6-32k"                      # ~26 GB | 32K context
    "qwen3-coder-30b:q6-220k"                     # ~26 GB | 220K context (solo only)
    
    # --- DeepSeek R1 ---
    "deepseek-r1:14b"                               # ~9 GB  | Reasoning
    "deepseek-r1-tools:14b"                         # ~10 GB | Tool calling
    "deepseek-r1-tools:32b"                         # ~20 GB | Tool calling 32B
    
    # --- Qwen3 32B ---
    "qwen3-32b:q5"                                 # ~22 GB | Research
    
    # --- Gemma 4 31B ---
    "gemma4:31b"                                    # ~18 GB | Reasoning
    
    # --- Gemma 3 12B ---
    "gemma3:12b"                                     # ~7 GB | General purpose
    
    # --- GLM-4.7 Flash ---
    "glm-4.7-flash"                                 # ~5 GB | Fast, Chinese-optimized
    
    # --- Phi-4 ---
    "phi4"                                          # ~9 GB | Efficient, small footprint
    
    # --- Codestral ---
    "codestral:22b"                                   # ~13 GB | Code, fill-in-middle
    "codestral:22b-v0.1-q8_0"                       # ~23 GB | Code apply/insert (Q8_0)
    
    # --- Llama 3.3 ---
    "llama3.3:70b"                                  # ~43 GB | General purpose (solo only)
    
    # --- Llama 3.2 ---
    "llama3.2"                                       # ~2 GB | General purpose
    
    # --- Qwen 2.5 Coder ---
    "qwen2.5-coder:7b"                              # ~4.5 GB | Fast code
    "qwen2.5-coder:1.5b"                            # ~1 GB  | Autocomplete
    
    # --- Qwen3 14B ---
    "qwen3-14b:q8"                                  # ~15 GB | Research
    "qwen3-14b:q5"                                  # ~12 GB | Research Q5
    
    # --- Qwen3 4B ---
    "qwen3-4b:q8"                                   # ~5 GB | Planning
    "qwen3-4b:q4"                                   # ~3 GB | Planning fast
    
    # --- Embeddings ---
    "nomic-embed-text"                             # ~0.3 GB | Codebase/RAG
)

# 64GB agent map
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-coder-next-80b:q4-16k"                          # OpenCode #1 — switch to qwen3.6:35b:q5-128k or qwen3-coder-30b:q6-32k via picker
    [think]="deepseek-r1-tools:32b"                             # tradeoff analysis, debugging strategy, scoring
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
    [apply]="codestral:22b-v0.1-q8_0"                    # applying suggested code to file (Q8_0)
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
CLAUDE_CODE_OPUS="qwen3.6:35b:q5-128k"                  # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# ==============================================
# CUSTOM MODEL DEFINITIONS (pull base + ollama create)
# ==============================================
CUSTOM_MODELS=(
    # Format: "source|alias|num_ctx"
    # HF base aliases must come before derived aliases that reference them.
    # ollama pull is idempotent — re-running won't re-download if already cached.
    
    # ═══════════════════════════════════════════
    # DERIVED CONTEXT ALIASES
    # ═══════════════════════════════════════════
    "qwen3.6:35b|qwen3.6:35b:q5-8k|8192|"                          # 8K ctx
    "qwen3.6:35b|qwen3.6:35b:q5-128k|131072|"                     # 128K ctx — solo only
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b:q6-32k|32768|"      # 32K ctx
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b:q6-220k|220000|"    # 220K ctx — solo only
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b:q6-8192|8192|false"# 8K ctx
    
    # ═══════════════════════════════════════════
    # HF BASE MODELS/ALIASES
    # ═══════════════════════════════════════════
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL|qwen3-coder-30b-a3b:q6||"   # ~26 GB
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL|qwen3-4b-2507:q8||"  # ~5 GB
    
    # ═══════════════════════════════════════════
    # BACKWARD-COMPAT ALIASES
    # ═══════════════════════════════════════════
    "qwen3-4b-2507:q8|qwen3-4b:q8||"
    
    # ═══════════════════════════════════════════
    # COMMUNITY MODEL ALIASES
    # ═══════════════════════════════════════════
    "dengcao/Qwen3-14B:Q8_0|qwen3-14b:q8||"                          # ~15 GB
    "Qwen3-14B:q8|qwen3-14b:q8||"                                    # auto-registered
    "dengcao/Qwen3-32B:Q5_K_M|qwen3-32b:q5||"                        # ~22 GB
    "Qwen3-32B:q5|qwen3-32b:q5||"                                    # auto-registered
    "mfdoom/deepseek-r1-tool-calling:14b|deepseek-r1-tools:14b||"    # ~10 GB
    "mfdoom/deepseek-r1-tool-calling:32b|deepseek-r1-tools:32b||"    # ~20 GB
)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3-coder-next-80b:q4-16k       interactive shell with model
#   ollama run qwen3.6:35b:q5-128k             interactive shell with model
#   ollama stop <model>                       force-unload to free memory
#   OLLAMA_KEEP_ALIVE=5m ollama serve           keep models warm for 5 mins
# ----------------------------------------------