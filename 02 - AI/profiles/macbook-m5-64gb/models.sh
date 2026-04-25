#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS - M5 Max 64GB
# ==============================================

# M5 Max 64GB - Extended configuration
MODELS=(
    # Custom aliases built via CUSTOM_MODELS_64GB below:
    #   qwen3.6:35b                 (Ollama stock — ~35 GB)
    #   qwen3.6:35b-8k              (8K ctx alias)
    #   qwen3.6:35b-128k            (128K ctx alias)
    #   qwen3-coder-30b-a3b:q6      (HF base — pulled once, ~26 GB)
    #   qwen3-coder-30b-32k:q6      (32K ctx alias)
    #   qwen3-coder-30b-220k:q6     (220K ctx alias)
    #   qwen3-4b:q8
    #   qwen3-14b:q8
    #   qwen3-32b:q5
    #   deepseek-r1-tools:14b
    #   deepseek-r1-tools:32b
    
    "qwen3.5:27b"                                       # ~20 GB | Writing, docs, cover letters
    
    "deepseek-r1:14b"                                   # ~10 GB | Reasoning, chat-only (no tools)
    
    "codestral:22b-v0.1-q8_0"                           # ~23 GB | Code apply/insert, light coding
    
    "qwen2.5-coder:7b"                                  # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                                # ~1 GB  | Autocomplete
    
    "nomic-embed-text"                                  # ~0.3 GB| Embeddings (Continue/RAG)
    
    "llama3.3:70b"                                      # ~43 GB | General purpose (large, solo use only)
)

# 64GB agent map
declare -A OPENCODE_AGENTS=(
    [code]="qwen3.5:27b"                                          # OpenCode #1 (IndexNow benchmark); switch to qwen3.6:35b-128k or qwen3-coder-30b-32k:q6 via picker
    [think]="deepseek-r1-tools:32b"                               # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-32b:q5"                                     # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q8"                                          # next steps, task breakdown, routing
)

# 64GB Continue roles
declare -A CONTINUE_ROLES=(
    [chat]="qwen3-coder-30b-32k:q6"                  # chat panel + inline edit (Ctrl+I)
    [kimi]="kimi-k2.6:cloud"                            # Cloud-based reasoning
    [chat_alt]="qwen3.5:27b"                         # manual model switch in chat
    [apply]="codestral:22b-v0.1-q8_0"                # applying suggested code to file (Q8_0, highest quality)
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

CLINE_MODEL="qwen3-coder-30b-32k:q6"
CLINE_MODEL_CLOUD="kimi-k2.6:cloud"

# 64GB — Claude Code model mapping
CLAUDE_CODE_SONNET="qwen3-coder-30b-32k:q6"            # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU="qwen3-4b:q8"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS="qwen3.6:35b-128k"                    # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

CUSTOM_MODELS=(
    # Format: "source|alias|num_ctx"
    # HF base aliases must come before derived aliases that reference them.
    # ollama pull is idempotent — re-running won't re-download if already cached.
    
    # ── Ollama base alias (30B coder) ─────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL|qwen3-coder-30b-a3b:q6||"   # ~26 GB
    
    # ── Context-window aliases (derived from base above) ──────────────────────
    "qwen3.6:35b|qwen3.6:35b-8k|8192|"                          # 8K ctx — primary coding model
    "qwen3.6:35b|qwen3.6:35b-128k|131072|"                      # 128K ctx — large context, solo only
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b-32k:q6|32768|"      # 32K ctx  — primary coding model
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b-220k:q6|220000|"    # 220K ctx — large context, solo only
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b-220k:q6|8196|false" # 8K ctx — small context, no thinking
    
    # ── HF base alias (4B) ────────────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL|qwen3-4b-2507:q8||"  # ~5 GB
    
    # ── Backward-compat aliases ───────────────────────────────────────────────
    "qwen3-4b-2507:q8|qwen3-4b:q8||"
    
    # ── Community model aliases ───────────────────────────────────────────────
    "dengcao/Qwen3-14B:Q8_0|qwen3-14b:q8||"                          # ~15 GB
    "Qwen3-14B:q8|qwen3-14b:q8||"                                    # auto-registered short name → lowercase alias
    "dengcao/Qwen3-32B:Q5_K_M|qwen3-32b:q5||"                        # ~22 GB
    "Qwen3-32B:q5|qwen3-32b:q5||"                                    # auto-registered short name → lowercase alias
    "mfdoom/deepseek-r1-tool-calling:14b|deepseek-r1-tools:14b||"    # ~10 GB
    "mfdoom/deepseek-r1-tool-calling:32b|deepseek-r1-tools:32b||"    # ~20 GB
)