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
# Ollama name (colon form)              LiteLLM model_name (dash form)        Machines
# ──────────────────────────────────────────────────────────────────────────────────────
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

# M5 Max 48GB - Standard configuration
MODELS_M5_48GB=(
    # Custom aliases built via CUSTOM_MODELS_48GB below:
    #   qwen3-coder-30b-32k:q5
    #   qwen3-coder-30b-220k:q5
    #   qwen3-4b:q4
    #   qwen3-14b:q5
    #   deepseek-r1-tools:8b

    "qwen3.5:27b"                                        # ~20 GB | Writing, docs, cover letters

    "deepseek-r1:8b"                                     # ~5 GB  | Reasoning, chat-only (no tools)

    "codestral:22b"                                      # ~14 GB | Code apply/insert, light coding

    "qwen2.5-coder:7b"                                   # ~5 GB  | Fast code tasks
    "qwen2.5-coder:1.5b"                                 # ~1 GB  | Autocomplete

    "nomic-embed-text"                                   # ~0.3 GB| Embeddings (Continue/RAG)
)

# M5 Max 64GB - Extended configuration
MODELS_M5_64GB=(
    # Custom aliases built via CUSTOM_MODELS_64GB below:
    #   qwen3-coder-30b-a3b:q6   (HF base — pulled once, ~26 GB)
    #   qwen3-coder-30b-32k:q6   (32K ctx alias)
    #   qwen3-coder-30b-220k:q6  (220K ctx alias)
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

# M1/M2/M3 16GB - Optimized for smaller memory
MODELS_16GB=(
    # Custom aliases built via CUSTOM_MODELS_16GB below:
    #   deepseek-r1-tools:8b

    "qwen3:14b"                                         # ~10 GB | General purpose coding + chat (Q4_K_M)

    "deepseek-r1:8b"                                    # ~5 GB  | Reasoning, chat-only (no tools)

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
# Config: scripts/opencode/opencode.jsonc → ~/.config/opencode/config.jsonc
# Invoke agents with: /agent <name>  or select in sidebar
# Switch model mid-session: Ctrl+M or sidebar model picker
# Use qwen3-coder-30b-220k:q5 manually when you need >32K context
# ----------------------------------------------
# 48GB agent map
# Note: opencode [code] agent uses qwen3.5:27b — #1 on OpenCode IndexNow benchmark.
# The qwen3-coder-30b-32k:q5 model is available in the model picker for manual selection.
declare -A OPENCODE_AGENTS_48GB=(
    [code]="qwen3.5:27b"                                          # OpenCode #1 (IndexNow benchmark); switch to qwen3-coder-30b-32k:q5 via picker
    [think]="deepseek-r1-tools:8b"                                # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-14b:q5"                                     # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q4"                                          # next steps, task breakdown, routing
)

# 64GB agent map
# Note: opencode [code] agent uses qwen3.5:27b — #1 on OpenCode IndexNow benchmark.
# The qwen3-coder-30b-32k:q6 model is available in the model picker for manual selection.
declare -A OPENCODE_AGENTS_64GB=(
    [code]="qwen3.5:27b"                                          # OpenCode #1 (IndexNow benchmark); switch to qwen3-coder-30b-32k:q6 via picker
    [think]="deepseek-r1-tools:32b"                               # tradeoff analysis, debugging strategy, scoring
    [write]="qwen3.5:27b"                                         # resumes, cover letters, docs, polished prose
    [research]="qwen3-32b:q5"                                     # codebase/web investigation — saves to Obsidian Research/
    [plan]="qwen3-4b:q8"                                          # next steps, task breakdown, routing
)

# 16GB agent map (shared for M1 MacBook + M2 Mac mini)
declare -A OPENCODE_AGENTS_16GB=(
    [code]="qwen3:14b"                                            # editing, refactoring, debugging (stock Q4_K_M)
    [think]="deepseek-r1-tools:8b"                               # tradeoff analysis, debugging strategy
    [write]="qwen3:14b"                                           # writing/docs (shared with coding slot)
    [research]="qwen3:14b"                                        # research (shared — only one large model fits)
    [plan]="qwen3-4b:q4"                                          # next steps, task breakdown, routing
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
    [chat]="qwen3-coder-30b-32k:q5"                  # chat panel + inline edit (Ctrl+I)
    [chat_alt]="qwen3.5:27b"                         # manual model switch in chat
    [apply]="codestral:22b"                          # applying suggested code to file
    [autocomplete]="qwen2.5-coder:1.5b"              # inline completions (default)
    [autocomplete_heavy]="qwen2.5-coder:7b"          # switch manually for complex files
    [embed]="nomic-embed-text"                       # @codebase semantic search
)

# 64GB Continue roles
declare -A CONTINUE_ROLES_64GB=(
    [chat]="qwen3-coder-30b-32k:q6"                  # chat panel + inline edit (Ctrl+I)
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
CLINE_MODEL_48GB="qwen3-coder-30b-32k:q5"   # set in Cline UI

# 64GB
CLINE_MODEL_64GB="qwen3-coder-30b-32k:q6"   # set in Cline UI

# 16GB
CLINE_MODEL_16GB="qwen3:14b"

# ----------------------------------------------
# Claude Code
# Config: claude_code/config.json → ~/.claude/settings.json (global) or .claude/settings.json (project)
# Requires LiteLLM on port 4000 — translates Anthropic API format → Ollama OpenAI format
# Quick ref:
#   /model qwen3-coder-30b-32k:q5    switch to coding model
#   /model deepseek-r1-tools:8b      switch to reasoning model
#   /model qwen3.5:27b               switch to writing model
#   /model qwen3-14b:q5              switch to research model
#   /model qwen3-4b:q4               switch to planning model
# ----------------------------------------------
# 48GB — Claude Code model mapping
CLAUDE_CODE_SONNET_48GB="qwen3-coder-30b-32k:q5"            # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU_48GB="qwen3-4b:q4"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS_48GB="qwen3-coder-30b-220k:q5"             # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# 64GB — Claude Code model mapping
CLAUDE_CODE_SONNET_64GB="qwen3-coder-30b-32k:q6"            # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU_64GB="qwen3-4b:q8"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS_64GB="qwen3-coder-30b-220k:q6"             # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)

# 16GB
CLAUDE_CODE_SONNET_16GB="qwen3:14b"                         # ANTHROPIC_DEFAULT_SONNET_MODEL
CLAUDE_CODE_HAIKU_16GB="qwen3-4b:q4"                        # ANTHROPIC_DEFAULT_HAIKU_MODEL — planning, routing
CLAUDE_CODE_OPUS_16GB="qwen3:14b"                           # ANTHROPIC_DEFAULT_OPUS_MODEL — large context (solo)


# RAM	Recommended Model	Pull Command	Performance Notes
# 8GB	Qwen2.5-Coder 7B	ollama pull qwen2.5-coder:7b	~76% HumanEval; best for tight budgets.
# 16GB	Qwen2.5-Coder 14B	ollama pull qwen2.5-coder:14b	~85% HumanEval; excellent for multi-file tasks.
# 24GB	Devstral Small 2	ollama pull devstral-small-2	68% SWE-bench Verified; strong on single GPU.
# 32GB+	Qwen3-Coder 30B	ollama pull qwen3-coder:30b	256K context; ideal for complex agentic workflows.
# 64GB+	Qwen3 Coder Next	ollama pull qwen3-coder-next	70.6% SWE-bench Verified; exceptional tool use.

# ----------------------------------------------
# LiteLLM
# Config: scripts/litellm/config.yaml → ~/.config/litellm/config.yaml
# Bridges Claude Code (Anthropic format) to Ollama (OpenAI format)
# Setup: uv tool install 'litellm[proxy]'
# Note: drop_params: true in config silently drops Anthropic-specific params Ollama rejects
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
# Format: "base_url|alias_name|modelfile_filename"
# install_custom_models in install_models.sh processes these:
#   - pulls each unique base_url once
#   - runs: ollama create <alias_name> -f <modelfiles_dir>/<modelfile_filename>
# Modelfiles live in modelfiles/ at repo root.
#
# Alias naming conventions:
#   HuggingFace GGUFs:  <model>-<size>-<ctx>-<quant>   e.g. qwen3-coder-30b-32k:q5
#   Ollama community:   <model>-<size>-<quant>          e.g. qwen3-14b:q5
#   Tool-calling:       <family>-tools:<size>           e.g. deepseek-r1-tools:8b

CUSTOM_MODELS_48GB=(
    # Format: "source|alias|num_ctx"  (num_ctx empty = model default)
    # HF base aliases must come before derived aliases that reference them.

    # ── HF base aliases ───────────────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q5_K_XL|qwen3-coder-30b-a3b:q5|"  # ~21 GB
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M|qwen3-4b-2507:q4|"                # ~3 GB

    # ── Derived context aliases ───────────────────────────────────────────────
    "qwen3-coder-30b-a3b:q5|qwen3-coder-30b-32k:q5|32768"   # ~25 GB loaded
    "qwen3-coder-30b-a3b:q5|qwen3-coder-30b-220k:q5|220000" # ~38 GB — solo only

    # ── Backward-compat aliases ───────────────────────────────────────────────
    "qwen3-4b-2507:q4|qwen3-4b:q4|"

    # ── Community model aliases ───────────────────────────────────────────────
    "dengcao/Qwen3-14B:Q5_K_M|qwen3-14b:q5|"                  # ~12 GB
    "Qwen3-14B-Q5_K_M|qwen3-14b:q5|"                          # auto-registered short name → lowercase alias
    "mfdoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b|" # ~5 GB
)

CUSTOM_MODELS_64GB=(
    # Format: "source|alias|num_ctx"
    # HF base aliases must come before derived aliases that reference them.
    # ollama pull is idempotent — re-running won't re-download if already cached.

    # ── HF base alias (30B coder) ─────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:UD-Q6_K_XL|qwen3-coder-30b-a3b:q6|"  # ~26 GB

    # ── Context-window aliases (derived from base above) ──────────────────────
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b-32k:q6|32768"    # 32K ctx  — primary coding model
    "qwen3-coder-30b-a3b:q6|qwen3-coder-30b-220k:q6|220000"  # 220K ctx — large context, solo only

    # ── HF base alias (4B) ────────────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q8_K_XL|qwen3-4b-2507:q8|"  # ~5 GB

    # ── Backward-compat aliases ───────────────────────────────────────────────
    "qwen3-4b-2507:q8|qwen3-4b:q8|"

    # ── Community model aliases ───────────────────────────────────────────────
    # Ollama auto-registers a capitalized short name alongside each community pull
    # (e.g. dengcao/Qwen3-14B:Q8_0 also appears as Qwen3-14B:q8 in ollama list).
    # The extra entries below let prune recognise those names as expected,
    # and re-alias them to lowercase for consistent referencing.
    "dengcao/Qwen3-14B:Q8_0|qwen3-14b:q8|"                      # ~15 GB
    "Qwen3-14B:q8|qwen3-14b:q8|"                                 # auto-registered short name → lowercase alias
    "dengcao/Qwen3-32B:Q5_K_M|qwen3-32b:q5|"                    # ~22 GB
    "Qwen3-32B:q5|qwen3-32b:q5|"                                 # auto-registered short name → lowercase alias
    "mfdoom/deepseek-r1-tool-calling:14b|deepseek-r1-tools:14b|" # ~10 GB
    "mfdoom/deepseek-r1-tool-calling:32b|deepseek-r1-tools:32b|" # ~20 GB
)

CUSTOM_MODELS_16GB=(
    # Format: "source|alias|num_ctx"
    # HF base aliases must come before derived aliases that reference them.

    # ── HF base aliases ───────────────────────────────────────────────────────
    "hf.co/unsloth/Qwen3-4B-Instruct-2507-GGUF:UD-Q4_K_M|qwen3-4b-2507:q4|"  # ~3 GB

    # ── Backward-compat aliases ───────────────────────────────────────────────
    "qwen3-4b-2507:q4|qwen3-4b:q4|"

    # ── Community model aliases ───────────────────────────────────────────────
    "mfdoom/deepseek-r1-tool-calling:8b|deepseek-r1-tools:8b|" # ~5 GB
)

# ----------------------------------------------
# Ollama direct
#   ollama list                              all installed models
#   ollama ps                                currently loaded + memory usage
#   ollama run qwen3-coder-30b-32k:q5        interactive shell with model
#   ollama run qwen3-coder-30b-32k:q6        interactive shell with model
#   ollama stop <model>                      force-unload to free memory
#   OLLAMA_KEEP_ALIVE=0 ollama serve         unload models immediately when idle
# ----------------------------------------------
