---
tags: [ai, llm, cli, local]
---

# Grok CLI

Conversational AI terminal tool powered by xAI's Grok models, built by Superagent AI (VibeKit). Supports file editing, bash integration, and tool use. Configured here to use **Ollama** as the local provider — no xAI API key needed.

> Not to be confused with **Groq** (groq.com) — a separate cloud inference API.

## Installation

```shell
npm install -g @vibe-kit/grok-cli
```

## Configuration (Ollama backend)

```shell
export GROKCLI_PROVIDER=ollama
export OLLAMA_BASE_URL=http://localhost:11434
```

Add to `~/.zshrc.d/_grok` (handled by `setup_grok.sh`).

Ensure Ollama is running with a tool-capable model:

```shell
ollama pull deepseek-r1-tools:8b
ollama serve
```

## Usage

```shell
grok
```

## References

- [npm package](https://www.npmjs.com/package/@vibe-kit/grok-cli)
- [GitHub repo](https://github.com/superagent-ai/grok-cli)
- [VibeKit docs](https://docs.vibekit.sh/agents/grok)
