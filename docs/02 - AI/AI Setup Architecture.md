---
tags: [ai, llm, local, proxy, architecture]
---

# AI Setup Architecture

How the local AI stack fits together, which tools conflict, and recommended configurations by machine type.

## The Stack

Every client (VS Code extensions, terminal agents, AnythingLLM) talks to **one endpoint: LiteLLM on `:4000`**. LiteLLM routes to Ollama (or llama.cpp). Nothing points directly at Ollama except LiteLLM.

```
┌─────────────────────────────────────────────────────────┐
│  Clients                                                 │
│  Claude Code · Continue · Cline · OpenCode · Crush      │
│  AnythingLLM · Grok CLI · Windsurf                      │
└──────────────────────┬──────────────────────────────────┘
                       │ OpenAI-compatible  /  Anthropic API
                       ▼
              ┌─────────────────┐
              │   LiteLLM :4000 │  spend tracking, rate limits,
              │   (proxy)       │  model aliasing, format bridging
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │  Ollama :11434  │  primary inference engine
              │  (or llama.cpp) │  Metal-accelerated on Apple Silicon
              └─────────────────┘
```

**Why LiteLLM in the middle?**

- Claude Code speaks Anthropic API format. Ollama speaks OpenAI format. LiteLLM bridges them.
- One place to change models without touching every tool's config.
- Spend tracking shows which tools consume the most tokens.
- Lets you swap Ollama for llama.cpp, vLLM, or a cloud provider without reconfiguring clients.

See [[LiteLLM]] for the full install and start guide.

---

## Tool Conflict Map

### Local inference engines — pick ONE as primary

| Tool          | Port   | Best for                                  | Use on Apple Silicon?  |
| ------------- | ------ | ----------------------------------------- | ---------------------- |
| **Ollama** ✓  | 11434  | Easy model management, broad tool support | ✅ Primary              |
| **llama.cpp** | varies | Low-level, maximum control, Metal GPU     | ✅ Alternative          |
| **LM Studio** | 1234   | GUI model browser, easy discovery         | ⚠️ Optional (see below) |
| **vLLM**      | varies | High-throughput serving on CUDA GPUs      | ❌ No Metal support     |
| **GPT4All**   | —      | Privacy-first offline chatbot only        | ⚠️ Consumer-only        |

**Ollama vs llama.cpp:** Ollama uses llama.cpp under the hood. Use Ollama directly unless you need custom GGUF flags that Ollama's Modelfile can't express. Running both is redundant.

**Ollama vs LM Studio:** Both download and serve models, but LM Studio stores models separately — you end up with 20–40 GB of duplicates. If you want LM Studio's model browser, use it to discover models, then pull them in Ollama and disable LM Studio's server. Do not run both servers simultaneously.

**Ollama vs vLLM:** vLLM requires CUDA (NVIDIA). On Apple Silicon it falls back to CPU-only, which is slower than Ollama's Metal path. Leave vLLM for Linux/GPU boxes.

### Scaling and load balancing — situational

| Tool          | Port  | Purpose                                                             | When to use                        |
| ------------- | ----- | ------------------------------------------------------------------- | ---------------------------------- |
| **olol**      | 11435 | Ollama load balancer (round-robin across multiple Ollama instances) | Multiple Mac nodes only            |
| **exo**       | 52415 | Shards one large model across multiple Apple Silicon Macs           | 2+ Macs, want 70B+ model           |
| **OpenShell** | —     | Security sandbox for autonomous agents                              | When running untrusted agent tasks |

**olol vs exo:** They solve different problems. olol balances full-model instances across machines; exo splits one model's layers across machines. Neither conflicts with LiteLLM — LiteLLM can sit in front of either. For a single machine, you need neither.

**OpenShell** is not an LLM server. It wraps agents (Claude Code, Codex) in a K3s/Docker sandbox with policy-based network and filesystem restrictions. Complementary to everything else; use it when running automated agents unsupervised.

### Clients — can mostly coexist

| Tool        | Type                                   | Conflicts with                                     |
| ----------- | -------------------------------------- | -------------------------------------------------- |
| Continue    | VS Code autocomplete + chat            | Copilot (both do inline completions — disable one) |
| Cline       | VS Code autonomous agent               | Nothing — different from Continue                  |
| Windsurf    | Full IDE (VS Code fork)                | VS Code itself — pick one IDE                      |
| OpenCode    | Terminal multi-agent TUI               | Nothing                                            |
| Crush       | Terminal TUI                           | Nothing                                            |
| Codex       | Terminal sandboxed agent (OpenAI only) | Nothing locally                                    |
| Claude Code | Terminal agent                         | Nothing locally                                    |

**Continue vs GitHub Copilot:** Both inject inline autocomplete. Running them together causes doubled suggestions and CPU thrash. Disable one. Continue is preferred if you want local models; Copilot if you rely on cloud.

**Windsurf vs VS Code:** Windsurf *is* VS Code (Electron fork). Do not install both and try to use them simultaneously for the same project. Pick one.

---

## Recommended Configurations

### Option A — Local-first (recommended)

Everything routes through LiteLLM → Ollama.

```
Ollama :11434
  └── LiteLLM :4000
        ├── Claude Code         (ANTHROPIC_BASE_URL=http://localhost:4000)
        ├── Continue            (provider: openai, apiBase: http://localhost:4000/v1)
        ├── Cline               (provider: openai, baseUrl: http://localhost:4000/v1)
        ├── OpenCode            (provider: ollama or openai-compatible, base: :4000)
        ├── Crush               (provider: ollama, base: http://localhost:4000)
        └── AnythingLLM         (LLM provider: LiteLLM, base: http://localhost:4000)
```

**Startup order:** Ollama → LiteLLM → (everything else)

```shell
# 1. Ollama (usually auto-starts; verify)
curl -s http://localhost:11434/api/tags | jq .

# 2. LiteLLM
litellm --config ~/.config/litellm/config.yaml --port 4000 &

# 3. Verify
curl http://localhost:4000/health
```

### Option B — Hybrid (local + cloud fallback via LiteLLM)

Add OpenRouter as a fallback in `~/.config/litellm/config.yaml`:

```yaml
model_list:
  - model_name: claude-sonnet
    litellm_params:
      model: ollama/qwen3-coder-30b-32k-q5
      api_base: http://localhost:11434

  - model_name: claude-sonnet-fallback
    litellm_params:
      model: openrouter/anthropic/claude-sonnet-4-6
      api_key: os.environ/OPENROUTER_API_KEY

router_settings:
  routing_strategy: simple-shuffle
  fallbacks:
    - {"claude-sonnet": ["claude-sonnet-fallback"]}
```

### Option C — Multi-machine (olol or exo)

Two Macs on the same LAN:

```
LiteLLM :4000
  └── olol :11435 (load balancer)
        ├── Mac A: Ollama :11434
        └── Mac B: Ollama :11434
```

Or for a single very large model split across two Macs:

```
LiteLLM :4000
  └── exo :52415  (shards 70B model across both)
```

---

## Models by Machine Type

Models are defined in `scripts/models.sh`. The install script reads your machine profile and pulls the right set.

```shell
# Install models for your hardware profile
bash config/install-models.sh m5-48gb   # or m5-64gb, m1, m2
```

See [[Models]] for the full table and `scripts/models.sh` for exact model names per profile.

Quick reference:

| RAM   | Max model size       | Recommended primary    |
| ----- | -------------------- | ---------------------- |
| 16 GB | 8B (Q4)              | qwen2.5-coder:7b       |
| 32 GB | 14B (Q8) or 27B (Q4) | qwen3:14b              |
| 48 GB | 30B (Q5)             | qwen3-coder-30b-32k-q5 |
| 64 GB | 30B (Q6) + 70B solo  | qwen3-coder-30b-32k-q6 |

---

## Setup Checklist (new machine)

Everything except LiteLLM's Postgres container is handled by the interactive setup script:

```shell
cd ~/code/isaackehle/settings
bash config/setup_ai.sh
```

The menu covers: **ollama · models · vscode · windsurf · claude · opencode · continue · litellm · crush · exo · anythingllm**. Hardware is auto-detected — selecting `models` will pre-select the right profile (48 GB, 64 GB, or 16 GB) and offer install + prune in one step.

**One manual prerequisite — LiteLLM's Postgres container:**

LiteLLM needs a running Postgres instance for spend tracking and the web UI. Start it once before running `setup litellm`:

```shell
docker run -d \
  --name litellm-postgres \
  --restart unless-stopped \
  -e POSTGRES_DB=litellm_db \
  -e POSTGRES_USER=litellm \
  -e POSTGRES_PASSWORD=litellm \
  -p 5432:5432 \
  postgres:16
```

Then in the setup menu select `litellm` — it installs the proxy, deploys the config, and generates the Prisma client. See [[LiteLLM]] for full Postgres management commands.

**Recommended run order in the menu:**

1. `ollama` — install + start server
2. `models` — pull and alias the model stack for your hardware
3. `litellm` — install proxy + deploy config (requires Postgres above)
4. `vscode` or `windsurf` — IDE + extensions
5. `claude` — install CLI + deploy config
6. `opencode`, `continue`, `crush` — remaining terminal/editor agents
7. `anythingllm` — RAG UI (optional)

---

## VS Code Extensions Running Forever

This happens most often on a new Mac. Root causes and fixes:

**Most likely: VS Code doesn't inherit your shell environment.**
Open VS Code from the terminal so it picks up `PATH`, `ANTHROPIC_API_KEY`, and `ANTHROPIC_BASE_URL`:

```shell
code .
# or for a specific folder:
code ~/Projects/myrepo
```

Never launch VS Code from the Dock on a new machine until you've verified env vars are visible inside VS Code's integrated terminal.

**Second most likely: LiteLLM is not running.**
Continue and Cline point at `:4000`. If LiteLLM isn't up, every request hangs until timeout (often 5+ minutes). Verify before opening VS Code:

```shell
curl http://localhost:4000/health
```

If that fails, start LiteLLM first (or start it and restart the VS Code extension host: `Cmd+Shift+P → Developer: Restart Extension Host`).

**Ollama cold start:** The first request to a model that isn't loaded takes 30–60 seconds on large models. The extension waits. Send a warm-up request before using VS Code:

```shell
curl http://localhost:11434/api/generate \
  -d '{"model":"qwen3-coder-30b-32k-q5","prompt":"hi","stream":false}'
```

**Continue aggressive autocomplete:** Continue polls for completions on every keystroke. If the autocomplete model is large and slow, the extension queues up requests and appears frozen. Fix: use the 1.5B autocomplete model and reserve the large model for chat only (already set in `config/continue/`).

**Claude Code specifically:** Claude Code requires `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` to be set. If either is missing it retries indefinitely with no visible error. Always launch from a terminal that has sourced `~/.env.local`.

```shell
# Quick test
echo $ANTHROPIC_BASE_URL   # should print http://localhost:4000
echo $ANTHROPIC_API_KEY    # should print sk-local (or your key)
claude --version           # should respond immediately
```

See [[VS Code AI Extensions]] and [[LiteLLM]] for extension-specific configuration.

---

## AlexsJones/llmfit

[llmfit](https://github.com/AlexsJones/llmfit) estimates which models fit in your available RAM before you pull them, avoiding partial downloads and OOM crashes. Useful when evaluating new model releases.

```shell
pip install llmfit --break-system-packages

# Check what fits in your current available RAM
llmfit check --ram $(( $(sysctl -n hw.memsize) / 1024 / 1024 / 1024 ))

# Check a specific model before pulling
llmfit model qwen3-coder:30b
```

Pair this with the model-updater skill (see `skills/model-updater/SKILL.md`) to vet new model suggestions before installing them.

---

## References

- [[LiteLLM]]
- [[Ollama]]
- [[Models]]
- [[Local LLMs]]
- [[VS Code AI Extensions]]
- [[Coding Assistants]]
- [AlexsJones/llmfit](https://github.com/AlexsJones/llmfit)
- [LiteLLM Proxy docs](https://docs.litellm.ai/docs/proxy/quick_start)
- [Ollama API reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
