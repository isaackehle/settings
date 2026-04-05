---
tags: [ai, coding, productivity, vscode]
---

# <img src="https://github.com/cline.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Cline

Autonomous AI coding agent for VS Code that can create and edit files, run terminal commands, use a browser, and call MCP tools.

- **VS Code Extension:** `saoudrizwan.claude-dev`

## Installation

Install from the VS Code Marketplace: search **Cline** or install `saoudrizwan.claude-dev`.

## Configuration

Cline settings live in the extension panel (click the gear icon). Each provider requires an API key or a local endpoint.

### Anthropic (Claude)

1. Open the Cline panel → **Settings**
2. Set **API Provider** to `Anthropic`
3. Paste your `ANTHROPIC_API_KEY`
4. Choose a model (e.g. `claude-sonnet-4-6`)

Recommended models:

| Model               | Use case                    |
| ------------------- | --------------------------- |
| `claude-opus-4-6`   | Complex tasks, best quality |
| `claude-sonnet-4-6` | Balanced speed and quality  |
| `claude-haiku-4-5`  | Fast, lightweight tasks     |

### Ollama (Local Models)

1. Ensure Ollama is running: `ollama serve`
2. Set **API Provider** to `OpenAI Compatible`
3. Set **Base URL** to `http://localhost:11434/v1`
4. Leave **API Key** blank (or enter any string)
5. Set **Model ID** to the model name (e.g. `qwen2.5-coder:7b`)

```shell
# Pull a capable coding model first
ollama pull qwen2.5-coder:7b
ollama pull deepseek-r1:14b
```

> Local models work best for simpler edits. Complex agentic tasks (multi-file refactors, test generation) benefit from a frontier model.

### OpenCode / OpenAI Compatible

Any server that exposes an OpenAI-compatible `/v1` endpoint works:

| Tool             | Base URL                    |
| ---------------- | --------------------------- |
| Ollama           | `http://localhost:11434/v1` |
| LM Studio        | `http://localhost:1234/v1`  |
| vLLM             | `http://localhost:8000/v1`  |
| llama.cpp server | `http://localhost:8080/v1`  |

Set **API Provider** → `OpenAI Compatible`, then fill in the base URL and model ID.

### OpenAI

1. Set **API Provider** to `OpenAI`
2. Paste your `OPENAI_API_KEY`
3. Set **Model** to e.g. `gpt-4o` or `o3`

### Google Gemini

1. Set **API Provider** to `Google Gemini`
2. Paste your `GEMINI_API_KEY`
3. Set **Model** to e.g. `gemini-2.5-pro`

## Key Features

- **Autonomous agent** — reads files, edits code, runs shell commands, and browses the web
- **MCP support** — connect Model Context Protocol servers for custom tools
- **Checkpoints** — every task creates a git snapshot; revert with one click
- **Plan mode** — review the agent's plan before it executes
- **Browser use** — Cline can open URLs and interact with web pages

## Usage Tips

- Use **Plan mode** (`Shift+Click` the submit button) to preview what Cline will do before it runs
- Grant **Auto-approve** only to trusted operations (reads are safer than writes/commands)
- For large refactors, start a fresh task per logical unit to keep context focused
- Combine with `[[Continue]]` for autocomplete; use Cline for agentic tasks

## References

- [Cline GitHub](https://github.com/cline/cline)
- [Cline Docs](https://docs.cline.bot/)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev)
- [MCP support](https://docs.cline.bot/mcp/what-is-mcp)
