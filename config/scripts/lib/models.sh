#!/usr/bin/env bash

# ==============================================
# MODEL LISTS BY HARDWARE PLATFORM
# ==============================================

# M5 Max 48GB - Standard configuration
# M5 Max 48GB - Base configuration
MODELS_M5_48GB=(
    # qwen3-coder-30b-32k and qwen3-coder-30b-220k are local aliases — see CUSTOM_MODELS_48GB below
    # qwen3-4b-q4 is a local alias — see CUSTOM_MODELS_48GB below

    "qwen3.5:27b"                                        # ~20 GB | Writing, docs, cover letters

    "dengcao/Qwen3-14B:Q5_K_M"                           # ~12 GB | Research / read-only analysis

    "mfdoom/deepseek-r1-tool-calling:8b"                 # ~5 GB  | Reasoning + tool calls
    "deepseek-r1:8b"                                     # ~5 GB  | Reasoning, chat-only (no tools)

    "codestral:22b"                                      # ~14 GB | Code apply/insert, light coding

    "qwen2.5-coder:7b"                                   # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                                 # ~1 GB  | Autocomplete

    "nomic-embed-text"                                   # ~0.3 GB| Embeddings (Continue/RAG)
)

# M5 Max 64GB - Extended configuration
MODELS_M5_64GB=(
    # qwen3-coder-30b-32k and qwen3-coder-30b-220k are local aliases — see CUSTOM_MODELS_64GB below
    # qwen3-4b-q8 is a local alias — see CUSTOM_MODELS_64GB below

    "qwen3.5:27b"                                       # ~20 GB | Writing, docs, cover letters

    "dengcao/Qwen3-14B:Q8_0"                            # ~15 GB | Research / read-only analysis (high quality)
    "dengcao/Qwen3-32B:Q5_K_M"                          # ~22 GB | Research / read-only analysis (larger)

    "mfdoom/deepseek-r1-tool-calling:14b"               # ~10 GB | Reasoning + tool calls
    "mfdoom/deepseek-r1-tool-calling:32b"               # ~20 GB | Reasoning + tool calls (larger)
    "deepseek-r1:14b"                                   # ~10 GB | Reasoning, chat-only (no tools)

    "codestral:22b-v0.1-q8_0"                           # ~23 GB | Code apply/insert, light coding

    "qwen2.5-coder:7b"                                  # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                                # ~1 GB  | Autocomplete

    "nomic-embed-text"                                  # ~0.3 GB| Embeddings (Continue/RAG)

    "llama3.3:70b"                                      # ~43 GB | General purpose (large, solo use only)
)

# M1/M2/M3 16GB - Optimized for smaller memory
MODELS_16GB=(
    "qwen3:14b"                                         # ~10 GB | General purpose coding + chat (Q4_K_M)

    "deepseek-r1:8b"                                    # ~5 GB  | Reasoning, chat-only (no tools)
    "mfdoom/deepseek-r1-tool-calling:8b"                # ~5 GB  | Reasoning + tool calls

    "qwen2.5-coder:7b"                                  # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                                # ~1 GB  | Autocomplete

    "nomic-embed-text"                                  # ~0.3 GB| Embeddings (Continue/RAG)
)

# Memory rule of thumb (M5 Max 48GB):
# code + think can coexist (~30 GB). Code + write pushes ~45 GB — fine, but nothing else
# large should be loaded. Ollama evicts after 5 min idle.

# ==============================================
# TOOL ROLE MAPPINGS
# ==============================================

# ----------------------------------------------
# opencode
# Config: scripts/configs/opencode.jsonc → ~/.config/opencode/config.jsonc
# Invoke agents with: /agent <name>  or select in sidebar
# Switch model mid-session: Ctrl+M or sidebar model picker
# Use qwen3-coder-30b-220k manually when you need >32K context
# ----------------------------------------------
# 48GB agent map
declare -A OPENCODE_AGENTS_48GB=(
    [code]="qwen3-coder-30b-32k"                                  # editing, refactoring, debugging, tool calls — UD-Q5_K_XL
    [think]="mfdoom/deepseek-r1-tool-calling:8b"                  # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                         # resumes, cover letters, docs, polished prose
    [research]="dengcao/Qwen3-14B:Q5_K_M"                         # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b-q4"     # next steps, task breakdown, routing
)

# 64GB agent map
declare -A OPENCODE_AGENTS_64GB=(
    [code]="qwen3-coder-30b-32k"                                  # editing, refactoring, debugging, tool calls — UD-Q6_K_XL
    [think]="mfdoom/deepseek-r1-tool-calling:14b"                 # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                         # resumes, cover letters, docs, polished prose
    [research]="dengcao/Qwen3-32B:Q5_K_M"                         # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b-q8" # next steps, task breakdown, routing
)

# ----------------------------------------------
# Continue (VS Code)
# Config: ~/.continue/config.yaml
# Roles determine which model is used automatically
# Quick ref:
#   Ctrl+L          open chat panel
#   Ctrl+I          inline edit (select code first)
#   Ctrl+Shift+R    quick refactor
#   @codebase       semantic search across repo
#   @file           include specific file in context
#   @docs           include indexed docs
# ----------------------------------------------
# 48GB Continue roles
declare -A CONTINUE_ROLES_48GB=(
    [chat]="qwen3-coder-30b-32k"                     # chat panel + inline edit (Ctrl+I) — UD-Q5_K_XL
    [chat_alt]="qwen3.5:27b"                         # manual model switch in chat
    [apply]="codestral:22b"                          # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

# 64GB Continue roles
declare -A CONTINUE_ROLES_64GB=(
    [chat]="qwen3-coder-30b-32k"                     # chat panel + inline edit (Ctrl+I) — UD-Q6_K_XL
    [chat_alt]="qwen3.5:27b"                         # manual model switch in chat
    [apply]="codestral:22b-v0.1-q8_0"                # applying suggested code to file (Q8_0, highest quality)
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

# ----------------------------------------------
# Cline (VS Code)
# Config: sidebar → gear → API Provider: Ollama, Base URL: http://localhost:11434
# Autonomous agent — plans and executes multi-step tasks with tool calls
# Task history: ~/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/
# Quick ref:
#   Ctrl+Shift+P → "Cline: Open"   open Cline panel
#   "New Task"                      start a new autonomous task
#   Approve / Reject                review each tool call before it runs
#   Resume Task                     continue a previous task from history
# ----------------------------------------------
# 48GB
CLINE_MODEL_48GB="qwen3-coder-30b-32k"    # set in Cline UI — UD-Q5_K_XL weights

# 64GB
CLINE_MODEL_64GB="qwen3-coder-30b-32k"    # set in Cline UI — UD-Q6_K_XL weights

# ----------------------------------------------
# Claude Code
# Config: scripts/configs/claude_code.json → ~/.claude/settings.json (global) or .claude/settings.json (project)
# Requires LiteLLM on port 4000 — translates Anthropic API format → Ollama OpenAI format
# Quick ref:
#   /model qwen3-coder-30b-32k                                  switch to coding model
#   /model mfdoom/deepseek-r1-tool-calling:8b                   switch to reasoning model
#   /model qwen3.5:27b                                          switch to writing model
#   /model dengcao/Qwen3-14B:Q5_K_M                             switch to research model
#   /model qwen3-4b-q4     switch to planning model
# ----------------------------------------------
# 48GB — Claude Code model mapping
CLAUDE_CODE_SONNET_48GB="qwen3-coder-30b-32k"               # ANTHROPIC_DEFAULT_SONNET_MODEL — UD-Q5_K_XL
CLAUDE_CODE_HAIKU_48GB="qwen3-4b-q4"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS_48GB="qwen3-coder-30b-220k"                # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# 64GB — Claude Code model mapping
CLAUDE_CODE_SONNET_64GB="qwen3-coder-30b-32k"               # ANTHROPIC_DEFAULT_SONNET_MODEL — UD-Q6_K_XL
CLAUDE_CODE_HAIKU_64GB="qwen3-4b-q8"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing UD-Q8_K_XL
CLAUDE_CODE_OPUS_64GB="qwen3-coder-30b-220k"                # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# ----------------------------------------------
# LiteLLM
# Config: scripts/configs/litellm.yaml → ~/.config/litellm/config.yaml
# Bridges Claude Code (Anthropic format) to Ollama (OpenAI format)
# Setup: pip install litellm
# Note: drop_params: true in config silently drops Anthropic-specific params (e.g. betas) Ollama rejects
# Start before launching Claude Code — must be up when Claude Code initializes
# Quick ref:
#   litellm --config ~/.config/litellm/config.yaml --port 4000    start proxy
#   litellm --config ~/.config/litellm/config.yaml --port 4000 &  background
#   curl http://localhost:4000/health                              verify running
#   curl http://localhost:4000/v1/models                           list routed models
# ----------------------------------------------

# ==============================================
# CUSTOM MODEL DEFINITIONS (pull base + ollama create)
# ==============================================
# Format: "base_hf_url|alias_name|modelfile_filename"
# install_custom_models in install-models.sh processes these:
#   - pulls each unique base_hf_url once
#   - runs: ollama create <alias_name> -f <modelfiles_dir>/<modelfile_filename>
# Modelfiles live in scripts/modelfiles/

CUSTOM_MODELS_48GB=(
    # Qwen3-Coder-30B — UD-Q5_K_XL base (~21 GB loaded)
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL|qwen3-coder-30b-32k|qwen3-coder-30b-32k-UD-Q5_K_XL.txt"   # num_ctx 32768
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL|qwen3-coder-30b-220k|qwen3-coder-30b-220k-UD-Q5_K_XL.txt" # num_ctx 220000 (solo use only)

    # Qwen3-4B — UD-Q4_K_M base (~3 GB loaded)
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M|qwen3-4b-q4|qwen3-4b-UD-Q4_K_M.txt"
)

CUSTOM_MODELS_64GB=(
    # Qwen3-Coder-30B — UD-Q6_K_XL base (~26 GB loaded, higher quality)
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL|qwen3-coder-30b-32k|qwen3-coder-30b-32k-UD-Q6_K_XL.txt"   # num_ctx 134217728
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL|qwen3-coder-30b-220k|qwen3-coder-30b-220k-UD-Q6_K_XL.txt" # num_ctx 220000 (solo use only)

    # Qwen3-4B — UD-Q8_K_XL base (~5 GB loaded, highest quality)
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL|qwen3-4b-q8|qwen3-4b-UD-Q8_K_XL.txt"
)

# ----------------------------------------------
# Ollama direct
#   ollama list                          all installed models
#   ollama ps                            currently loaded + memory usage
#   ollama run qwen3-coder-30b-32k       interactive shell with model
#   ollama stop <model>                  force-unload to free memory
#   OLLAMA_KEEP_ALIVE=0 ollama serve     unload models immediately when idle
# ----------------------------------------------

