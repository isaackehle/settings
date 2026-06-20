# Deprecated Tools

Tools that were part of the setup at some point but are no longer used.
Kept here so future-Isaac knows why they're gone and doesn't reinstall them.

---

## Kilocode

- **Removed:** 2026-06-20
- **Was:** VS Code fork with built-in AI coding agent (open-source Roo Code derivative)
- **Why removed:** Superseded by OpenCode (terminal-native, works over SSH, no Electron overhead) and Claude Code. Kilocode required a GUI/VS Code window on each machine; OpenCode runs anywhere the terminal does, which fits the headless DS9 workflow better. Kilo's MCP/model routing was also duplicating config already managed in `ai/profiles/`.
- **Config removed:** `.kilo/` directory (agent-manager.json, rules/, plans/, node_modules)
- **Decision doc:** `ai/docs/decisions/opencode-go-vs-zen-vs-openrouter.md`

---

## llama-server `--models-preset` router

- **Removed:** 2026-06-20
- **Was:** Native llama.cpp multi-model router — single `llama-server` process with `--models-preset` flag switching models on demand
- **Why removed:** Unstable under load; single-process failure took down all models. Replaced by **llama-swap** (mostlygeek/llama-swap), which runs one `llama-server` process per model, manages TTL-based unloading, and proxies requests to remote machines for models too large to run locally.
- **LaunchAgent removed:** `org.kehle.llama-router.plist`
- **Replaced by:** `com.kehle.llama-swap.plist` + `ai/profiles/*/llama-swap.yaml`
- **Install doc:** `ai/runtimes/install-llama-swap.sh`

---

## Ollama (as primary inference runtime)

- **Removed:** 2026-06-20 (config still present but being phased out)
- **Was:** Primary local LLM server; `ollama serve` + pull-based model management
- **Why replaced:** llama.cpp / llama-swap gives more control over quantization, context size, KV cache type, and flash-attn flags. Ollama abstracts these away. For the 64GB M5 Max running 30–80B models, those knobs matter. Ollama remains as a fallback and for tools that only speak the Ollama API.
- **Profiles still present** in `ai/profiles/*/ollama/` for compatibility

---

## LiteLLM proxy

- **Removed:** ~2026-05 (config remnants cleaned up 2026-06-20)
- **Was:** Python-based LLM proxy for unified OpenAI-compatible API across providers
- **Why removed:** Added latency, required a DB, and broke on model-name mismatches. llama-swap + direct OpenRouter fallback in tool configs achieves the same routing without a Python intermediary.

---

_Add new entries at the top when retiring a tool._
