---
tags: [ai, coding, productivity]
---

# <img src="https://github.com/charmbracelet.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Crush

[Crush](https://github.com/charmbracelet/crush) is a terminal-based AI coding assistant by Charm. It provides a TUI, supports multiple LLMs, and integrates with LSPs and MCPs for deep context.

```shell
brew install charmbracelet/tap/crush
```

## Configuration

Crush config lives at `~/.config/crush/crush.json`. Deploy the machine-specific config via the setup script, or copy manually:

```shell
cp config/<machine>/crush/crush.json ~/.config/crush/crush.json
```

All configs point at LiteLLM on `:4000` so model changes only need updating in one place.

### LiteLLM provider (all machines)

```json
{
  "$schema": "https://charm.land/crush.json",
  "providers": {
    "litellm": {
      "name": "LiteLLM (local)",
      "type": "openai-compat",
      "base_url": "http://localhost:4000/v1",
      "api_key": "sk-local",
      "models": [
        {
          "id": "qwen3-coder-30b-32k:q6",
          "name": "Qwen3 Coder 30B (32k)",
          "context_window": 32768,
          "default_max_tokens": 8192
        }
      ]
    }
  },
  "default_provider": "litellm",
  "default_model": "qwen3-coder-30b-32k:q6"
}
```

The `api_key` value must match your `LITELLM_MASTER_KEY` env var (default: `sk-local`).

### LSPs

```json
{
  "$schema": "https://charm.land/crush.json",
  "lsp": {
    "go": {
      "command": "gopls",
      "env": {
        "GOTOOLCHAIN": "go1.24.5"
      }
    },
    "typescript": {
      "command": "typescript-language-server",
      "args": ["--stdio"]
    },
    "nix": {
      "command": "nil"
    }
  }
}
```

### MCPs

Crush supports MCP servers via stdio, http, or sse transport:

```json
{
  "$schema": "https://charm.land/crush.json",
  "mcp": {
    "filesystem": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/mcp-server.js"],
      "timeout": 120,
      "disabled": false
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "headers": {
        "Authorization": "Bearer $GH_PAT"
      }
    }
  }
}
```

## Start / Usage

```shell
crush
```

LiteLLM must be running first:

```shell
curl http://localhost:4000/health   # verify before launching crush
```

## References

- [Crush](https://github.com/charmbracelet/crush)
- [Charm docs](https://charm.sh/)
- [[LiteLLM]]
- [[AI Setup Architecture]]
