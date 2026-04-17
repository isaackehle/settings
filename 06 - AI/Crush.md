---
tags: [ai, coding, productivity]
---

# <img src="https://github.com/charmbracelet.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Crush

[Crush](https://github.com/charmbracelet/crush) is a powerful terminal-based AI coding assistant by Charm. It provides a beautiful TUI, supports multiple LLMs, and integrates with LSPs and MCPs for deep context.

```shell
brew install charmbracelet/tap/crush
```

No basic configuration required.

```shell
crush
```

## Configuration

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

### LSPs
Crush can use LSPs for additional context to help inform its decisions, just like you would. LSPs can be added manually like so:

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

Crush also supports Model Context Protocol (MCP) servers through three transport types: stdio for command-line servers, http for HTTP endpoints, and sse for Server-Sent Events. Environment variable expansion is supported using $(echo $VAR) syntax.

```json
{
  "$schema": "https://charm.land/crush.json",
  "mcp": {
    "filesystem": {
      "type": "stdio",
      "command": "node",
      "args": ["/path/to/mcp-server.js"],
      "timeout": 120,
      "disabled": false,
      "disabled_tools": ["some-tool-name"],
      "env": {
        "NODE_ENV": "production"
      }
    },
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/",
      "timeout": 120,
      "disabled": false,
      "disabled_tools": ["create_issue", "create_pull_request"],
      "headers": {
        "Authorization": "Bearer $GH_PAT"
      }
    },
    "streaming-service": {
      "type": "sse",
      "url": "https://example.com/mcp/sse",
      "timeout": 120,
      "disabled": false,
      "headers": {
        "API-Key": "$(echo $API_KEY)"
      }
    }
  }
}
```

### LM Studio (Local Models)

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
    },
    "ollama": {
      "name": "ollama",
      "base_url": "http://localhost:11434/v1/",
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

```json
{
  "providers": {
    "anthropic": {
      "api_key": "sk-ant-..."
    },
    "openai": {
      "api_key": "sk-..."
    }
  }
}
```

## Start / Usage

```shell
# Crush
crush
```

## References

- [Crush](https://github.com/charmbracelet/crush)
- [Charm docs](https://charm.sh/)
