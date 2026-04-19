---
tags: [ai, coding, productivity, terminal]
---

# <img src="https://opencode.ai/favicon.ico" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenCode

Terminal-based AI coding assistant with TUI, supporting multiple LLMs, LSPs, and MCP integrations.

## Installation

```shell
brew install anomalyco/tap/opencode

# or via script
curl -fsSL https://opencode.ai/install | bash
```

## Configuration

Config file: `~/.config/opencode/opencode.json`

### Ollama (Local Models)

Ensure Ollama is running (`ollama serve`), then:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3.2-coder": {
          "name": "qwen3.2-coder:7b"
        }
      }
    }
  }
}
```

### OpenRouter

```json
{
  "provider": {
    "openrouter": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OpenRouter",
      "options": {
        "baseURL": "https://openrouter.ai/api/v1",
        "apiKey": "sk-or-..."
      },
      "models": {
        "claude-sonnet": {
          "name": "anthropic/claude-sonnet-4-6"
        }
      }
    }
  }
}
```

## Start / Usage

```shell
opencode
```

**Key commands:**

- `/connect` — Connect to a provider
- `/model` — Switch model
- `/help` — Show help

## References

- [OpenCode](https://opencode.ai/)
- [Ollama Integration](https://docs.ollama.com/integrations/opencode)

See also: [[Crush]]
