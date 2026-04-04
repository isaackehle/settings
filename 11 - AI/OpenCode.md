---
tags: [ai, coding, productivity]
---

# <img src="https://github.com/charmbracelet.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenCode / Crush

Terminal-based AI coding assistant with TUI, supporting multiple LLMs, LSPs, and MCP integrations.

## Installation

```shell
# Crush (Charm)
brew install charmbracelet/tap/crush

# OpenCode (AnomalyCo)
brew install anomalyco/tap/opencode

# Or via script
curl -fsSL https://opencode.ai/install | bash
```

## Configuration

### Ollama (Local Models)

Ensure Ollama is running (`ollama serve`), then configure:

**OpenCode** (`~/.config/opencode/opencode.json`):

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

**Crush** (`~/.config/crush/crush.json`):

```json
{
  "providers": {
    "ollama": {
      "name": "Ollama",
      "base_url": "http://localhost:11434/v1/",
      "type": "openai-compat",
      "models": [
        {
          "name": "Qwen 3 30B",
          "id": "qwen3:30b-a3b",
          "context_window": 256000,
          "default_max_tokens": 20000
        }
      ]
    }
  }
}
```

### LM Studio (Local Models)

**Crush** (`~/.config/crush/crush.json`):

```json
{
  "providers": {
    "lmstudio": {
      "name": "LM Studio",
      "base_url": "http://localhost:1234/v1/",
      "type": "openai-compat",
      "models": [
        {
          "name": "Qwen 3 30B",
          "id": "qwen/qwen3-30b-a3b-2507",
          "context_window": 256000
        }
      ]
    }
  }
}
```

### Cloud Providers

**Anthropic (Claude):**

```json
{
  "providers": {
    "anthropic": {
      "api_key": "sk-ant-..."
    }
  }
}
```

**OpenAI:**

```json
{
  "providers": {
    "openai": {
      "api_key": "sk-..."
    }
  }
}
```

## Start / Usage

```shell
# OpenCode
opencode

# Crush
crush

# Connect to provider interactively
/connect
```

**Key commands:**

- `/connect` — Connect to a provider
- `/help` — Show help
- `/model` — Switch model

## References

- [OpenCode](https://opencode.ai/)
- [Crush](https://github.com/charmbracelet/crush)
- [Ollama Integration](https://docs.ollama.com/integrations/opencode)
- [Charm docs](https://charm.sh/)
