---
tags: [ai, coding, productivity, ide, vscode]
---

# Windsurf

AI-native IDE from Codeium, built on VS Code. Includes **Cascade** — an agentic AI that can read, write, and run code across your entire codebase. Also includes inline autocomplete (formerly Codeium).

- **Website:** [codeium.com/windsurf](https://codeium.com/windsurf)

## Installation

```shell
brew install --cask windsurf
```

## Config Files

| File | Location | Purpose |
| --- | --- | --- |
| `argv.json` | `~/.windsurf/argv.json` | Launch arguments (crash reporter, hardware accel) |
| `codeium-config.json` | `~/.codeium/config.json` | Disables telemetry |

Both are deployed by `setup_windsurf.sh`.

## Ollama Integration

Windsurf can use local Ollama models for autocomplete and chat:

1. Open **Windsurf Settings** → **AI** → **Autocomplete**
2. Set provider to **OpenAI Compatible**
3. Set base URL: `http://localhost:11434/v1`
4. Set model: e.g. `qwen2.5-coder:7b`

For Cascade (chat/agents), use the built-in Codeium Credits or connect an Anthropic/OpenAI key in settings.

## Key Features

- **Cascade** — agentic AI with full codebase context, terminal access, and multi-file edits
- **Inline autocomplete** — fast next-line and multi-line suggestions
- **MCP support** — connect Model Context Protocol servers
- **VS Code compatible** — most extensions work

## References

- [Windsurf docs](https://docs.codeium.com/windsurf/getting-started)
- [Cascade docs](https://docs.codeium.com/windsurf/cascade)
- [Codeium GitHub](https://github.com/Exafunction/codeium)
