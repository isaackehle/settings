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
# codestral:22b                         codestral-22b                         M1, M2
# qwen3-14b (stock)                     qwen3-14b                             M1, M2
# qwen3-4b:q4                           qwen3-4b-q4                           48GB, M1, M2
# deepseek-r1-tools:8b                  deepseek-r1-tools-8b                  48GB, M1, M2
# deepseek-r1:8b                        deepseek-r1-8b                        48GB, M1, M2
# qwen2.5-coder:7b                      qwen2.5-coder-7b                      all
# qwen2.5-coder:1.5b                    qwen2.5-coder-1.5b                    all
# nomic-embed-text                      nomic-embed-text                      all (embed)
#
# ==============================================

# M1/M2 16GB - Lightweight configuration
MODELS=(
    "qwen2.5-coder:7b"                            # ~5 GB   | Fast code tasks
    "qwen2.5-coder:1.5b"                          # ~1 GB   | Autocomplete
    "nomic-embed-text"                            # ~0.3 GB | Embeddings (Continue/RAG)
)

# ----------------------------------------------
# opencode
# ----------------------------------------------
declare -A OPENCODE_AGENTS=(
    [code]="qwen2.5-coder:7b"                                 # OpenCode #1 (IndexNow benchmark)
    [think]="deepseek-r1-tools:8b"                             # tradeoff analysis, debugging strategy
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

# ==============================================
# CUSTOM MODEL DEFINITIONS (pull base + ollama create)
# ==============================================
CUSTOM_MODELS=(
    # Format: "source|alias|num_ctx"
    
    # ── Community model aliases ───────────────────────────────────────────────
    "mfdoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b||" # ~5 GB
)

# ----------------------------------------------
# Ollama direct
# ----------------------------------------------
#   ollama list                                 all installed models
#   ollama ps                                   currently loaded + memory usage
#   ollama run <model>                          interactive shell with model
#   ollama stop <model>                         force-unload to free memory
#   OLLAMA_KEEP_ALIVE=0 ollama serve            unload models immediately when idle
# ----------------------------------------------
