#!/opt/homebrew/bin/bash

# ==============================================
# MODEL LISTS BY HARDWARE PLATFORM
# ==============================================
#
# When adding, removing, or renaming models here, also update:
#
#   config/profile.d/_obsidian     vault alias — per-machine model selection
#   scripts/*/grok/grok.json       grok CLI model list — LiteLLM dash-form names
#   scripts/*/litellm/litellm.yaml model_name entries + router_settings aliases
#   scripts/*/continue/config.yaml model: fields for LiteLLM-routed models
#   scripts/*/claude/settings.json ANTHROPIC_DEFAULT_*_MODEL env vars
#   scripts/*/opencode/opencode.jsonc model IDs in provider.ollama.models + agents
#
# Model name conventions:
#   Ollama / opencode direct (port 11434): colon form  e.g. qwen3-32b:q5
#   LiteLLM-routed (port 4000):            dash form   e.g. qwen3-32b-q5
#   (continue, claude, grok all go through LiteLLM → dash form)
#
# ==============================================
# OLLAMA ↔ LITELLM NAME MAPPING
# ==============================================
#
# Ollama name (colon form)              LiteLLM model_name (dash form)       Machines
# ──────────────────────────────────────────────────────────────────────────────────────
# qwen3.6:35b-8k                       qwen3.6-35b-8k                        64GB
# qwen3.6:35b-128k                     qwen3.6-35b-128k                      64GB
# qwen3.6:35b-8k                       qwen3.6-35b-8k                        48GB
# qwen3.6:35b-128k                     qwen3.6-35b-128k                      48GB
# qwen3-coder-30b-32k:q6               qwen3-coder-30b-32k-q6                64GB
# qwen3-coder-30b-220k:q6              qwen3-coder-30b-220k-q6               64GB
# qwen3-coder-30b-32k:q5               qwen3-coder-30b-32k-q5                48GB
# qwen3-coder-30b-220k:q5              qwen3-coder-30b-220k-q5               48GB
# codestral:22b-v0.1-q8_0              codestral-22b-v0.1-q8_0               64GB
# codestral:22b                        codestral-22b                         48GB, M1, M2
# qwen3-32b:q5                         qwen3-32b-q5                          64GB
# qwen3-14b:q8                         qwen3-14b-q8                          64GB
# qwen3-14b:q5                         qwen3-14b-q5                          48GB
# qwen3-14b (stock)                    qwen3-14b                             M1, M2
# qwen3.5:27b                          qwen3.5-27b                           48GB, 64GB
# qwen3-4b:q8                          qwen3-4b-q8                           64GB
# qwen3-4b:q4                          qwen3-4b-q4                           48GB, M1, M2
# deepseek-r1-tools:32b                deepseek-r1-tools-32b                 64GB
# deepseek-r1-tools:14b                deepseek-r1-tools-14b                 64GB, 48GB
# deepseek-r1-tools:8b                 deepseek-r1-tools-8b                  48GB, M1, M2
# deepseek-r1:14b                      deepseek-r1-14b                       64GB
# deepseek-r1:8b                       deepseek-r1-8b                        48GB, M1, M2
# llama3.3:70b                         llama3.3-70b                          64GB
# qwen2.5-coder:7b                     qwen2.5-coder-7b                      all
# qwen2.5-coder:1.5b                   qwen2.5-coder-1.5b                    all
# nomic-embed-text                     nomic-embed-text                      all (embed)
#
# ==============================================

# M2 Max 32GB - Standard configuration
MODELS=(
    "qwen3-14b"                                  # ~9 GB  | Writing, docs, cover letters
    "deepseek-r1:8b"                             # ~5 GB  | Reasoning, chat-only (no tools)
    "codestral:22b"                              # ~14 GB | Code apply/insert, light coding
    "qwen2.5-coder:7b"                            # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                         # ~1 GB  | Autocomplete
    "nomic-embed-text"                            # ~0.3 GB| Embeddings (Continue/RAG)
)

# ----------------------------------------------
# opencode
# ----------------------------------------------
declare -A OPENCODE_AGENTS=(
    [code]="qwen3-14b"                                          # OpenCode #1 (IndexNow benchmark)
    [think]="deepseek-r1-tools:8b"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3-14b"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-14b"                                      # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q4"                                          # next steps, task breakdown, routing
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
CLAUDE_CODE_HAIKU="qwen3-4b:q4"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS="codestral:22b"             # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# ==============================================
# CUSTOM MODEL DEFINITIONS (pull base + ollama create)
# ==============================================
CUSTOM_MODELS=(
    # Format: "source|alias|num_ctx"
    # HF base aliases must come before derived aliases that reference them.
    
    # ── HF base aliases ───────────────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M|qwen3-4b-2507:q4||"                 # ~3 GB
    
    # ── Derived context aliases ───────────────────────────────────────────────
    # No specific context aliases for M2_32GB in original file
    
    # ── Backward-compat aliases ───────────────────────────────────────────────
    "qwen3-4b-2507:q4|qwen3-4b:q4||"
    
    # ── Community model aliases ───────────────────────────────────────────────
    "mfdoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b||" # ~5 GB
)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run qwen3.6-35b-32k:q5               interactive shell with model
#   ollama run qwen3.6-35b-32k:q6               interactive shell with model
#   ollama run qwen3-coder-30b-32k:q5           interactive shell with model
#   ollama run qwen3-coder-30b-32k:q6           interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=0 ollama serve            unload models immediately when idle
# ----------------------------------------------