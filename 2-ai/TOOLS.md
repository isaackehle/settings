---
tags: [ai, index, reference]
---

# AI Tools Reference

Comprehensive reference for all AI tools in this setup. Install scripts live in each tool's subfolder (`2-ai/<tool>/<tool>.sh`) and are orchestrated by `setup-ai.sh` one level up. Machine-specific configs live in `profiles/<machine>/<tool>/`.

## Contents

- [AI Tools Reference](#ai-tools-reference)
  - [Contents](#contents)
  - [Infrastructure](#infrastructure)
    - [Ollama](#ollama)
    - [oMLX](#omlx)
  - [Local LLM Server Architectures](#local-llm-server-architectures)
    - [Architecture Options](#architecture-options)
    - [Recommended: Ollama Direct](#recommended-ollama-direct)
    - [Starting the Stack](#starting-the-stack)
    - [OpenWebUI](#openwebui)
    - [Olol](#olol)
    - [Exo](#exo)
  - [Local Runtimes](#local-runtimes)
    - [LM Studio](#lm-studio)
    - [GPT4All](#gpt4all)
    - [Llama.cpp](#llamacpp)
    - [vLLM](#vllm)
  - [Terminal Coding Agents](#terminal-coding-agents)
    - [Claude Code](#claude-code)
    - [OpenCode](#opencode)
    - [Crush](#crush)
    - [Aider](#aider)
    - [Gemini CLI](#gemini-cli)
    - [Grok CLI](#grok-cli)
    - [Open Interpreter](#open-interpreter)
    - [OpenHands](#openhands)
    - [OpenShell](#openshell)
    - [Codex](#codex)
  - [VS Code Extensions](#vs-code-extensions)
    - [VS Code](#vs-code)
    - [Cline](#cline)
    - [Continue](#continue)
    - [GitHub Copilot](#github-copilot)
    - [Kilo Code](#kilo-code)
      - [Config Structure](#config-structure)
      - [Model per Mode (agents)](#model-per-mode-agents)
      - [Agent Permissions](#agent-permissions)
      - [Model Selection by Agent](#model-selection-by-agent)
      - [Memory-Based Guidelines](#memory-based-guidelines)
      - [Common Issues to Check](#common-issues-to-check)
      - [Validation](#validation)
    - [Windsurf](#windsurf)
  - [Self-Hosted Assistants](#self-hosted-assistants)
    - [AnythingLLM](#anythingllm)
    - [Tabby](#tabby)
  - [APIs \& Services](#apis--services)
    - [OpenRouter](#openrouter)
    - [Groq](#groq)
    - [Perplexity](#perplexity)
    - [Hugging Face](#hugging-face)
  - [Image Generation](#image-generation)
    - [Automatic1111](#automatic1111)
    - [Draw Things](#draw-things)
  - [Frameworks \& Libraries](#frameworks--libraries)
    - [LangChain](#langchain)
    - [LlamaIndex](#llamaindex)
    - [PyTorch](#pytorch)

---

## Infrastructure

### Ollama

Local LLM manager for Apple Silicon. Handles model downloads and serves an OpenAI-compatible API on `:11434`. Used by most tools in this setup as the model source.

```shell
brew install ollama
brew services start ollama
ollama list   # list installed models
```

**Model registration** — GGUFs are downloaded to `/usr/local/lib/llama-models/` via the `hf` CLI, then registered in Ollama using `FROM hf.co/<repo>:<filename>` in the Modelfile. This is critical: using a bare local GGUF path (`FROM /path/to/file.gguf`) causes Ollama to drop the embedded chat template and lose tool-calling support. The `FROM hf.co/...` reference causes Ollama to fetch its own metadata so templates and capabilities are correctly set.

Registration is handled automatically by `setup_ai.sh` → Install/update local models.

All tools route through **Ollama** (`:11434/v1` OpenAI-compatible endpoint) directly. Cloud models via OpenRouter provider blocks natively in each tool — no proxy required.

- [ollama.com](https://ollama.com) · [docs](https://ollama.com/docs) · `2-ai/ollama.sh`

---

### oMLX

MLX-native LLM inference server with continuous batching and tiered KV caching for Apple Silicon. Managed from the macOS menu bar. Drop-in replacement for Ollama with built-in admin dashboard, model downloader, and a native macOS app.

Requires macOS 15.0+ (Sequoia) and Apple Silicon.

```shell
brew tap jundot/omlx https://github.com/jundot/omlx
brew install omlx

# Run as a background service
brew services start omlx
```

```shell
# Start server with a model directory
omlx serve --model-dir ~/models

# Or download the macOS app from Releases for a GUI experience
# https://github.com/jundot/omlx/releases

# API at http://localhost:8000/v1 (OpenAI-compatible)
# Admin dashboard at http://localhost:8000/admin
```

```shell
brew update && brew upgrade omlx   # Upgrade to latest
brew services info omlx             # Check service status
```

**Key features:** Continuous batching · Tiered KV cache (RAM hot + SSD cold) · Multi-model serving with LRU eviction and pinning · Admin dashboard with real-time monitoring, chat, benchmarking · Built-in HuggingFace model downloader · Vision-language model support · Tool calling & structured output · One-click integrations for OpenCode, Claude Code, Copilot, and more.

- [omlx.ai](https://omlx.ai) · [github.com/jundot/omlx](https://github.com/jundot/omlx) · `2-ai/omlx.sh`

---

## Local LLM Server Architectures

Choose the architecture that matches your setup. All configurations support hybrid local + cloud via OpenRouter.

### Architecture Options

| Architecture              | Components                                | Best For                             |
| ------------------------- | ----------------------------------------- | ------------------------------------ |
| **Ollama only**           | Ollama `:11434`                           | Default — direct, no proxy           |
| **oMLX**                  | oMLX `:8000`                              | MLX-native, menu bar, tiered cache   |
| **Ollama + OpenWebUI**    | Ollama `:11434` + OpenWebUI `:8080`       | Chat UI for humans                   |
| **LMStudio**              | LMStudio `:1234`                          | Prefer GUI over CLI                  |
| **LMStudio + OpenRouter** | LMStudio + cloud models                   | GUI-first, cloud fallback            |
| **llama.cpp server**      | llama-server `:8080`                      | Custom quantization, max performance |
| **vLLM**                  | vLLM `:8000`                              | Linux server, NVIDIA GPU             |
| **Olol (load balancer)**  | Olol `:11435` + multiple Ollama instances | Multi-machine inference              |
| **Exo (distributed)**     | Exo `:52415`                              | Split model across machines          |

### Recommended: Ollama Direct

```
┌─────────────────────────────────────────────────────────┐
│              Agents (OpenCode, Claude Code, etc.)       │
│                            ↓                            │
│               http://localhost:11434/v1                 │
│                            ↓                            │
│  ┌──────────────────────────────────────────────────┐   │
│  │                    Ollama                        │   │
│  │  - Model serving                  ───────────    │   │
│  │  - OpenAI-compatible API              │   │      │   │
│  │  - Cloud models via tool-native       │   │      │   │
│  │    OpenRouter provider blocks         │   │      │   │
│  └───────────────────────────────────────┴───┴──────┘   │
│                            ↓                            │
│                   ┌──────────────────┐                  │
│                   │ OpenWebUI        │                  │
│                   │ :8080 (optional) │                  │
│                   │ (human chat UI)  │                  │
│                   └──────────────────┘                  │
└─────────────────────────────────────────────────────────┘
```

**Why this stack:**

- Single endpoint for all agents
- No proxy overhead (no LiteLLM)
- Cloud models via tool-native OpenRouter providers
- Optional UI for human use

### Starting the Stack

```shell
# 1. Start Ollama (background service)
brew services start ollama

# 2. Start OpenWebUI (optional, for human chat)
# See 2-ai/openwebui.sh
```

---

### OpenWebUI

Web UI for local LLMs. Connects to Ollama for human-friendly chat interface.

**Prerequisites:** Docker, Ollama running.

```shell
# Using Docker
docker run -d --name openwebui \
  -p 8080:8080 \
  -v openwebui:/app/backend/data \
  --add-host=host.docker.internal:host-gateway \
  ghcr.io/open-webui/open-webui:main

# Or use the setup script
bash 2-ai/openwebui.sh setup
```

**Connect to Ollama:**

1. Open http://localhost:8080
2. Settings → Admin Settings → Connections
3. Add API URL: `http://host.docker.internal:11434/v1`

- [docs.openwebui.com](https://docs.openwebui.com) · `2-ai/openwebui.sh`

---

### Olol

Ollama load balancer. Routes requests round-robin across multiple Ollama backends on different machines. Each backend runs the full model independently.

> Different from Exo — olol distributes traffic, Exo splits model layers.

```shell
npm install -g https://github.com/K2/olol.git
```

Config at `~/.config/olol/config.json`:

```json
{
  "port": 11435,
  "backends": [
    { "url": "http://127.0.0.1:11434", "name": "local" },
    { "url": "http://192.168.1.100:11434", "name": "mac-studio" }
  ]
}
```

```shell
olol --config ~/.config/olol/config.json
# Point tools at http://localhost:11435/v1
```

- [github.com/K2/olol](https://github.com/K2/olol) · `2-ai/olol/olol.sh`

---

### Exo

Distributed inference that splits a single large model's layers across multiple Apple Silicon Macs. No primary/secondary distinction — all nodes run the same command and discover each other via mDNS.

> Different from Olol — exo shards one model, Olol load-balances across full copies.

**Prerequisites:** Xcode, uv, node, Rust nightly, macmon (pinned fork for M5).

```shell
brew install uv node
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup toolchain install nightly
cargo install --git https://github.com/vladkels/macmon --rev a1cd06b6cc0d5e61db24fd8832e74cd992097a7d macmon --force

git clone https://github.com/exo-explore/exo
cd exo/dashboard && npm install && npm run build && cd ..
```

```shell
# Run on each Mac — same command everywhere
uv run exo

# Dashboard + API at http://localhost:52415/
```

Exposes OpenAI, Anthropic, and Ollama-compatible APIs on `:52415`.

- [github.com/exo-explore/exo](https://github.com/exo-explore/exo) · `2-ai/exo/exo.sh`

---

## Local Runtimes

### LM Studio

Native macOS GUI for discovering and running local LLMs. Exposes an OpenAI-compatible server on `:1234`.

```shell
brew install --cask lm-studio
```

Start: Open from Applications → enable the local server under the API tab.

- [lmstudio.ai](https://lmstudio.ai) · [docs](https://docs.lmstudio.ai) · `2-ai/lmstudio/lmstudio.sh`

---

### GPT4All

Privacy-focused local chatbot app. Runs entirely offline, no internet required.

```shell
brew install --cask gpt4all
```

Start: Open from Applications.

- [nomic.ai/gpt4all](https://www.nomic.ai/gpt4all) · [github](https://github.com/nomic-ai/gpt4all) · `2-ai/gpt4all/gpt4all.sh`

---

### Llama.cpp

Apple Silicon-optimized inference library for GGUF models. Reads GGUF files directly — chat templates (including tool calling) are taken from the GGUF metadata with no conversion step, so tool support works natively.

Build from source at `~/code/llama.cpp` for M-series optimizations:

```shell
git clone https://github.com/ggerganov/llama.cpp ~/code/llama.cpp
cd ~/code/llama.cpp
cmake -B build -DCMAKE_BUILD_TYPE=Release -DGGML_METAL=ON   -DGGML_BLAS=ON -DGGML_BLAS_VENDOR=Apple   -DCMAKE_C_FLAGS="-march=native" -DCMAKE_CXX_FLAGS="-march=native"
cmake --build build --config Release -j$(sysctl -n hw.logicalcpu)
```

Use `2-ai/llama-cpp.sh` to serve models by role — each role has a dedicated port:

| Role      | Port | Profile model (64GB)          |
|-----------|------|-------------------------------|
| fast      | 8011 | qwen3:4b                      |
| general   | 8012 | qwen3.5-27b:q4                |
| coder     | 8013 | qwen3-coder-30b-a3b:q6        |
| heavy     | 8014 | qwen3-coder-next-80b:q4       |
| reasoning | 8015 | deepseek-r1:32b               |

```shell
# Serve a role (uses GGUF directly from $(GGUF_DIR))
MACHINE_PROFILE=macbook-m5-64gb 2-ai/llama-cpp.sh serve heavy
MACHINE_PROFILE=macbook-m5-64gb 2-ai/llama-cpp.sh serve coder

# Inspect what would be served
MACHINE_PROFILE=macbook-m5-64gb 2-ai/llama-cpp.sh inspect heavy
```

Tool configs (OpenCode, KiloCode, etc.) point at Ollama by default. llama.cpp ports are listed as additional providers in each tool's config for when native tool calling is preferred.

- [github.com/ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp) · `2-ai/llama-cpp.sh`

---

### vLLM

High-throughput LLM serving engine. Best on Linux + NVIDIA GPU; macOS support is CPU-only (slow for large models).

```shell
uv pip install vllm
# or
pip install vllm
```

```shell
python3 -m vllm.entrypoints.openai.api_server --model <model>
# API at http://localhost:8000/v1
```

Docker is recommended on macOS:

```shell
docker run --runtime nvidia --gpus all -p 8000:8000 vllm/vllm-openai:latest --model <model>
```

- [vllm.ai](https://vllm.ai) · [docs](https://docs.vllm.ai) · `2-ai/vllm/vllm.sh`

---

## Terminal Coding Agents

### Claude Code

Anthropic's agentic coding CLI. Reads, writes, and runs code in your terminal.

**Install via curl only** (npm/Homebrew installs are deprecated):

```shell
npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
curl -fsSL https://claude.ai/install.sh | bash
```

Profile config (`profiles/<machine>/claude/settings.json`) is deployed to `~/.claude/settings.json`. Routes through Ollama on `:11434`.

- [docs.anthropic.com/claude-code](https://docs.anthropic.com/en/docs/claude-code) · `2-ai/claude/claude.sh`

---

### OpenCode

Terminal TUI coding agent with multi-provider support, LSP integration, and MCP tools.

```shell
brew install anomalyco/tap/opencode
# or
curl -fsSL https://opencode.ai/install | bash
```

Config deployed from `profiles/<machine>/opencode/opencode.jsonc` → `~/.config/opencode/opencode.jsonc`. Single config file per profile — Ollama-only, no variants needed.

Agents and their assigned models (64GB profile):

| Agent    | Model                        | Purpose                        |
|----------|------------------------------|--------------------------------|
| code     | qwen3-coder-next-80b:q4      | Implementation, refactoring    |
| local    | qwen3-coder-30b-a3b:q6       | Offline/sensitive work         |
| think    | deepseek-r1:32b              | Reasoning, tradeoffs           |
| write    | qwen3.5-27b:q4               | Docs, summaries, prose         |
| research | qwen3-coder-30b-a3b:q6       | Evidence gathering             |
| plan     | qwen3:4b                     | Fast planning, routing         |

```shell
opencode          # interactive TUI
opencode "task"   # one-shot
```

- [opencode.ai](https://opencode.ai) · `2-ai/opencode/opencode.sh`

---

### Crush

Terminal TUI coding assistant by Charm. Supports LSPs, MCPs, and multiple LLM providers.

```shell
brew install charmbracelet/tap/crush
```

Config deployed from `profiles/<machine>/crush/crush.json` → `~/.config/crush/crush.json`. All profiles point at Ollama on `:11434/v1`.

```shell
crush
```

- [github.com/charmbracelet/crush](https://github.com/charmbracelet/crush) · `2-ai/crush/crush.sh`

---

### Aider

AI pair programmer in your terminal. Keeps every change in git — every session is fully auditable.

```shell
brew install aider
# or
uv tool install aider-chat
```

Config deployed from `profiles/<machine>/aider/aider.conf.yml` → `~/.aider.conf.yml`. All models route through Ollama (`ollama_chat/<model>` format).

```shell
aider                          # interactive session in current git repo
aider path/to/file.py          # start with a file
aider --message "refactor X"   # one-shot

# Key in-session commands
/add <file>     /drop <file>    /diff    /undo    /ask <question>
```

- [aider.chat](https://aider.chat) · [config reference](https://aider.chat/docs/config/aider_conf.html) · `2-ai/aider/aider.sh`

---

### Gemini CLI

Google's open-source terminal agent. Supports code generation, file operations, web search, and MCP integrations.

```shell
npm install -g @google/gemini-cli
```

Config deployed from `profiles/<machine>/gemini/settings.json` → `~/.gemini/settings.json`. Routes through Ollama for local models.

```shell
gemini                            # interactive
gemini -p "explain this codebase" # non-interactive
gemini -m gemini-2.5-flash        # specific model
```

Auth: `gemini` → choose "Sign in with Google" (free tier), or set `GEMINI_API_KEY`.

- [github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) · `2-ai/gemini/gemini.sh`

---

### Grok CLI

Terminal AI tool by Superagent AI (VibeKit), powered by local Ollama models. Not to be confused with Groq (cloud inference API).

```shell
npm install -g @vibe-kit/grok-cli
```

Configured to use Ollama backend:

```shell
export GROKCLI_PROVIDER=ollama
export OLLAMA_BASE_URL=http://localhost:11434
ollama pull MFDoom/deepseek-r1-tool-calling:latest
```

Profile config (`profiles/<machine>/grok/grok.json`) is deployed by the setup script.

```shell
grok
```

- [github.com/superagent-ai/grok-cli](https://github.com/superagent-ai/grok-cli) · `2-ai/grok/grok.sh`

---

### Open Interpreter

Terminal agent that writes and executes code (Python, JS, shell), manages files, and can control your computer.

```shell
uv tool install open-interpreter
# or
pip install open-interpreter
```

```shell
interpreter                      # interactive
interpreter -y "list .py files"  # one-shot, auto-approve
interpreter --safe_mode ask      # confirm every shell command

# Local model via Ollama
interpreter --api_base http://localhost:11434/v1 --api_key ollama \
  --model qwen3-coder-30b-a3b:q5-32k
```

- [openinterpreter.com](https://openinterpreter.com) · [docs](https://docs.openinterpreter.com) · `2-ai/open-interpreter/open_interpreter.sh`

---

### OpenHands

Autonomous AI software development agent. Writes code, runs tests, fixes bugs, and operates a terminal end-to-end. Runs in Docker.

**Prerequisites:** Docker (Rancher Desktop or Colima), Ollama on `:11434`, uv.

```shell
# Install uv if needed
curl -LsSf https://astral.sh/uv/install.sh | sh

# Setup: install CLI
bash 2-ai/open-hands.sh setup

# Start web UI on :3000
bash 2-ai/open-hands.sh start
```

Or run directly:

```shell
# With current directory mounted
openhands serve --mount-cwd
```

Local model config in the web UI Settings:

- Provider: `OpenAI` · Base URL: `http://host.docker.internal:11434/v1` · API Key: `ollama`

Config persisted at `~/.openhands/`.

- [docs.openhands.dev](https://docs.openhands.dev) · `2-ai/open-hands.sh`

---

### OpenShell

NVIDIA's sandboxed runtime for running autonomous AI agents safely. Wraps Claude Code, OpenCode, Codex, etc. in an isolated container with YAML policies controlling filesystem, network, and process access.

```shell
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh
# or
uv tool install -U openshell
```

**Prerequisite:** Docker running locally.

```shell
openshell sandbox create -- claude     # Claude Code in sandbox
openshell sandbox create -- opencode   # OpenCode in sandbox
openshell sandbox create -- codex      # Codex in sandbox
openshell sandbox list                 # view running sandboxes
openshell sandbox connect [name]       # SSH into sandbox
```

- [github.com/NVIDIA/OpenShell](https://github.com/NVIDIA/OpenShell) · `2-ai/openshell/openshell.sh`

---

### Codex

OpenAI's CLI coding agent. Powered by the `codex-1` model (o3 family). Requires `OPENAI_API_KEY`.

```shell
npm install -g @openai/codex
```

```shell
codex                                          # interactive
codex "add input validation to login form"     # one-shot
codex --approval-mode full-auto "refactor X"   # no prompts
```

Approval modes: `suggest` (default, shows diff) · `auto-edit` (applies file edits, asks for shell) · `full-auto` (no prompts, sandboxed).

- [github.com/openai/codex](https://github.com/openai/codex) · `2-ai/codex/codex.sh`

---

## VS Code Extensions

### VS Code

Microsoft's open-source editor. Primary host for Cline, Roo Code, Kilo Code, Continue, GitHub Copilot, and Cursor extensions.

```shell
brew install --cask visual-studio-code
```

Install AI extensions:

```shell
code --install-extension saoudrizwan.claude-dev   # Cline
code --install-extension RooVetGit.roo-cline      # Roo Code
code --install-extension continue.continue         # Continue
code --install-extension GitHub.copilot            # GitHub Copilot
```

Each extension's config is deployed from its own profile folder (e.g., `profiles/<machine>/cline/`).

- [code.visualstudio.com](https://code.visualstudio.com) · `2-ai/vscode/vscode.sh`

---

### Cline

Autonomous AI coding agent extension for VS Code. Creates and edits files, runs terminal commands, uses a browser, and calls MCP tools.

**Extension ID:** `saoudrizwan.claude-dev`

Config (`profiles/<machine>/cline/settings.jsonc`) configures the Ollama endpoint. Set in the Cline sidebar:

- API Provider: `OpenAI Compatible`
- Base URL: `http://localhost:11434/v1`
- API Key: `ollama`
- Model: your profile's `CLINE_MODEL`

Key features: autonomous agent mode, MCP support, git checkpoints, plan mode, browser use.

- [cline.bot](https://cline.bot) · [github](https://github.com/cline/cline) · `2-ai/cline/cline.sh`

---

### Continue

Open-source AI code assistant for VS Code and JetBrains. Chat, inline edit, autocomplete, and codebase indexing.

**Extension ID:** `Continue.continue`

Config deployed from `profiles/<machine>/continue/config.yaml` → `~/.continue/config.yaml`. All models route through Ollama direct (`provider: ollama`).

| Shortcut | Action                     |
| -------- | -------------------------- |
| `Cmd+L`  | Open chat / send selection |
| `Tab`    | Accept autocomplete        |
| `Cmd+I`  | Inline edit                |

- [continue.dev](https://www.continue.dev) · [docs](https://docs.continue.dev) · `2-ai/continue/continue.sh`

---

### GitHub Copilot

Industry standard AI pair programmer. Native Ollama integration in VS Code 1.113+ — no extra extension needed.

**Extension ID:** `GitHub.copilot`

```shell
gh extension install github/gh-copilot   # CLI
```

**Ollama integration (VS Code):** Copilot Chat sidebar → gear icon → Add Models → Ollama → Unhide. Requires Ollama v0.18.3+, VS Code 1.113+, Copilot Chat 0.41.0+.

Inline completions require a paid Copilot subscription; Ollama works for chat.

- [github.com/features/copilot](https://github.com/features/copilot) · `2-ai/github-copilot/github_copilot.sh`

---

### Kilo Code

AI coding agent extension for VS Code and Windsurf. Multi-agent architecture with mode-specific models and configurable permissions.

**Extension ID:** `kilohealth.kilo-code`

Config deployed from `profiles/<machine>/kilocode/kilo.jsonc` → `~/.kilo/kilo.jsonc`. All models route through Ollama on `:11434/v1`.

```shell
code --install-extension kilohealth.kilo-code
```

#### Config Structure

| Field                | Purpose                      | Example                  |
| -------------------- | ---------------------------- | ------------------------ |
| `model`              | Default model (fallback)     | `qwen3-coder-30b-a3b:q5` |
| `small_model`        | Lightweight tasks, summaries | `qwen2.5-coder:7b`       |
| `autocomplete_model` | Inline code completion       | `qwen2.5-coder:1.5b`     |

#### Model per Mode (agents)

| Agent         | Purpose                              | Profile Model Selection             |
| ------------- | ------------------------------------ | ----------------------------------- |
| `code`        | Implementation, editing, refactoring | Largest available coder model       |
| `ask`         | Q&A, code explanation, context       | Same as code (read-only)            |
| `debug`       | Error diagnosis, bug tracing         | Reasoning model (DeepSeek R1 Tools) |
| `description` | MR/PR descriptions                   | Small/fast model                    |
| `plan`        | Planning, next steps, breakdowns     | Small/fast model                    |
| `think`       | Reasoning, tradeoffs, analysis       | Reasoning model (DeepSeek R1 Tools) |
| `write`       | Docs, summaries, polished prose      | Larger context model (Qwen3.5/3.6)  |
| `summary`     | Commit messages, session summaries   | Smallest model                      |

#### Agent Permissions

Each agent has its own permission set:

- `bash`: `ask` (prompt), `allow` (auto), `deny` (blocked)
- `edit`: same options
- `glob`, `grep`, `list`, `read`, `webfetch`: typically `allow`

#### Model Selection by Agent

| Agent           | Recommended Model                                         | Avoid                            |
| --------------- | --------------------------------------------------------- | -------------------------------- |
| **code**        | Largest model available (e.g., `qwen3-coder-30b-q5-128k`) | Small models — needs capacity    |
| **ask**         | Same as code (read-only, needs comprehension)             | Small models                     |
| **debug**       | `deepseek-r1-tools-*` (better for reasoning)              | General models                   |
| **think**       | `deepseek-r1-tools-*` (better for reasoning)              | General models                   |
| **write**       | `qwen3.5-27b-q5-256k` or `qwen3.6-35b-256k`               | Main code model — different task |
| **plan**        | Small/fast model (e.g., `qwen3-4b-q8-256k`)               | Large models — just routing      |
| **description** | Small/fast model                                          | Large models — just summaries    |
| **summary**     | Small model (e.g., `qwen2.5-coder-7b-q4-32k`)             | Large — just commit messages     |

#### Memory-Based Guidelines

| RAM      | Default Model             | Write Model        | Fast/Plan  |
| -------- | ------------------------- | ------------------ | ---------- |
| **64GB** | `qwen3-coder-next-80b:q4` | `qwen3.5-27b:q4`   | `qwen3:4b` |
| **48GB** | `qwen3-coder-30b-a3b:q5`  | `qwen3.5-27b:q4`   | `qwen3:4b` |
| **32GB** | `qwen3-coder-30b-a3b:q5`  | `qwen3.5-27b:q4`   | `qwen3:4b` |
| **16GB** | `qwen3:14b`               | `qwen2.5-coder:7b` | `qwen3:4b` |

**Config:** Single `kilo.jsonc` per profile, Ollama-only. Model list grouped by purpose (role), not by context window size. Each role has a base alias (default context) and one `+long` variant for large sessions.

#### Common Issues to Check

1. **Context size mismatch** — top-level `model` must match agent `model` context (e.g., both `128k`)
2. **Missing permissions** — all agents need `grep` in permissions
3. **Wrong model for task** — write agent should not use code model
4. **Cloud models unavailable** — verify cloud models (e.g., `kimi-k2.6`) are actually accessible

#### Validation

After editing any `kilo.jsonc`:

- Verify JSON is valid (no trailing commas)
- Ensure all referenced models exist in the `provider.ollama.models` list
- Check agent models are defined in the profile's models.sh

- [kilocode.ai](https://kilocode.ai) · [docs](https://kilocode.ai/docs) · `2-ai/kilocode.sh`

---

### Windsurf

AI-native IDE from Codeium, built on VS Code. Includes **Cascade** — an agentic AI with full codebase context, terminal access, and multi-file edits.

```shell
brew install --cask windsurf
```

Profile config deploys `argv.json` and `codeium-config.json`. Local Ollama models for autocomplete: Settings → AI → Autocomplete → OpenAI Compatible → `http://localhost:11434/v1`.

- [codeium.com/windsurf](https://codeium.com/windsurf) · `2-ai/windsurf/windsurf.sh`

---

## Self-Hosted Assistants

### AnythingLLM

Local RAG and chat UI. Use Ollama as the model provider — no separate model downloads needed.

```shell
brew install --cask anythingllm
```

Configuration (in app):

1. Settings → LLM Preference → Ollama → `http://127.0.0.1:11434`
2. Settings → Embedding Preference → Ollama → `http://127.0.0.1:11434` → `nomic-embed-text`
3. Settings → Vector Database → LanceDB (built-in)

```shell
# Pull embedding model if missing
ollama pull nomic-embed-text
```

- [anythingllm.com](https://anythingllm.com) · [docs](https://docs.anythingllm.com) · `2-ai/anythingllm/anythingllm.sh`

---

### Tabby

Self-hosted AI coding assistant focused on code completion. IDE plugin connects to your Tabby server.

```shell
brew install tabbyml/tabby/tabby
```

```shell
# Start server (Apple Silicon Metal)
tabby serve --model TabbyML/StarCoder-1B --device metal

# Health check
curl http://localhost:8080/v1/health
```

Models are downloaded automatically on first run. Recommended models:

| Model                        | RAM  | Quality                |
| ---------------------------- | ---- | ---------------------- |
| `TabbyML/StarCoder-1B`       | ~2GB | Fast autocomplete      |
| `TabbyML/CodeLlama-7B`       | ~7GB | Better quality         |
| `TabbyML/DeepseekCoder-6.7B` | ~7GB | Strong code completion |

IDE plugins: VS Code and JetBrains — search "Tabby", set server URL to `http://localhost:8080`.

- [tabby.tabbyml.com](https://tabby.tabbyml.com) · [docs](https://tabby.tabbyml.com/docs) · `2-ai/tabby/tabby.sh`

---

## APIs & Services

### OpenRouter

Unified API gateway giving access to hundreds of models through a single OpenAI-compatible endpoint. One key for Claude, GPT, Gemini, Llama, Mistral, and more.

```shell
export OPENROUTER_API_KEY="sk-or-..."
```

Base URL: `https://openrouter.ai/api/v1` — drop-in replacement for OpenAI SDK.

```python
from openai import OpenAI
client = OpenAI(base_url="https://openrouter.ai/api/v1", api_key=os.environ["OPENROUTER_API_KEY"])
response = client.chat.completions.create(model="anthropic/claude-sonnet-4-6", messages=[...])
```

Used in profile configs as the cloud fallback provider. Model IDs use `provider/model` format (e.g., `moonshot/kimi-k2.6`).

- [openrouter.ai](https://openrouter.ai) · [models](https://openrouter.ai/models) · `2-ai/openrouter/openrouter.sh`

---

### Groq

Cloud LLM inference API with extremely fast token generation via custom LPU hardware. Free tier available.

```shell
export GROQ_API_KEY="gsk_..."
```

No official CLI — used via API key in LiteLLM, Continue, OpenCode, etc.

| Model                            | Best for           |
| -------------------------------- | ------------------ |
| `llama-3.3-70b-versatile`        | General purpose    |
| `qwen-3-32b`                     | Reasoning + coding |
| `llama-4-scout-17b-16e-instruct` | Fast, multilingual |

Profile config deploys `local-settings.json` for the Groq Code CLI.

- [console.groq.com](https://console.groq.com) · [docs](https://console.groq.com/docs) · `2-ai/groq/groq.sh`

---

### Perplexity

AI search with real-time web grounding. Returns cited, up-to-date answers sourced from the web. OpenAI-compatible API.

```shell
export PERPLEXITY_API_KEY="pplx-..."
```

Base URL: `https://api.perplexity.ai`

| Model                 | Best for                          |
| --------------------- | --------------------------------- |
| `sonar`               | Fast, cheap web-grounded answers  |
| `sonar-pro`           | Complex queries, follow-ups       |
| `sonar-reasoning-pro` | Multi-step reasoning + web search |
| `sonar-deep-research` | Exhaustive research reports       |

```shell
curl https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "sonar-pro", "messages": [{"role": "user", "content": "Latest Rust release?"}]}'
```

- [docs.perplexity.ai](https://docs.perplexity.ai) · `2-ai/perplexity/perplexity.sh`

---

### Hugging Face

Hub for sharing models and datasets. GGUFs are downloaded to `/usr/local/lib/llama-models/` via the `hf` CLI (replaces the deprecated `huggingface-cli`).

```shell
uv tool install "huggingface_hub[hf_xet,cli]"
hf auth login   # get token at huggingface.co/settings/tokens
```

```shell
# Download a specific GGUF file
hf download Qwen/Qwen3-4B-GGUF Qwen3-4B-Q4_K_M.gguf --local-dir /usr/local/lib/llama-models/
```

Model downloads are managed automatically by `setup_ai.sh` → Install/update local models, which reads `GGUF_SOURCES` and `GGUF_REMOTE_FILENAMES` from each profile's `models.sh`.

- [huggingface.co](https://huggingface.co) · [CLI docs](https://huggingface.co/docs/huggingface_hub/guides/cli) · `2-ai/huggingface.sh`

---

## Image Generation

### Automatic1111

Feature-rich web UI for Stable Diffusion. Supports txt2img, img2img, inpainting, ControlNet, LoRA, and hundreds of extensions.

**Prerequisites:** Python 3.10+, git.

```shell
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui
./webui.sh   # first run installs deps and downloads base model
```

Web UI at `http://localhost:7860`. Place models (`.safetensors`) in `models/Stable-diffusion/`.

```shell
./webui.sh --api                 # enable REST API
./webui.sh --skip-torch-cuda-test  # required on macOS MPS
```

API: `POST http://localhost:7860/sdapi/v1/txt2img`

- [github.com/AUTOMATIC1111](https://github.com/AUTOMATIC1111/stable-diffusion-webui) · `2-ai/automatic1111/automatic1111.sh`

---

### Draw Things

Native macOS/iOS app for on-device image generation. Runs Stable Diffusion, FLUX, and other models via Core ML and MPS. No Python setup required.

Install from [App Store](https://apps.apple.com/us/app/draw-things-ai-generation/id6444050820) or [drawthings.ai](https://drawthings.ai).

Models downloaded in-app. Popular: FLUX.1 [schnell] (fast), FLUX.1 [dev] (quality), SDXL, SD 1.5.

**API server:** Settings → API Server → Enable → `http://localhost:7860` (Automatic1111-compatible).

- [drawthings.ai](https://drawthings.ai) · `2-ai/draw-things/draw_things.sh`

---

## Frameworks & Libraries

### LangChain

Framework for building LLM-powered applications. Chains, agents, tools, and retrieval.

```shell
pip install langchain
```

- [langchain.com](https://www.langchain.com) · [docs](https://docs.langchain.com) · [github](https://github.com/langchain-ai/langchain) · `2-ai/langchain/langchain.sh`

---

### LlamaIndex

Data framework for connecting custom data sources to LLMs. Primary tool for building RAG pipelines.

```shell
pip install llama-index
```

- [llamaindex.ai](https://www.llamaindex.ai) · [docs](https://docs.llamaindex.ai) · [github](https://github.com/run-llama/llama_index) · `2-ai/llamaindex/llamaindex.sh`

---

### PyTorch

Standard ML framework. Supports Metal Performance Shaders (MPS) for GPU acceleration on Apple Silicon.

```shell
pip install torch torchvision torchaudio
```

```python
import torch
print(torch.backends.mps.is_available())  # True on Apple Silicon
device = torch.device("mps")
```

- [pytorch.org](https://pytorch.org) · [MPS backend](https://pytorch.org/docs/stable/notes/mps.html) · `2-ai/pytorch/pytorch.sh`
