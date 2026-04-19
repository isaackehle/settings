---
tags: [ai, llm, coding, productivity]
---

# <img src="https://github.com/google.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Google Gemini CLI

Open-source AI agent that brings Gemini directly into your terminal. Supports code generation, file operations, shell commands, web search, and MCP integrations.

## Installation

```shell
npm install -g @google/gemini-cli
```

Or use `npx @google/gemini-cli` to run without installing.

## Configuration

### Authentication

**Sign in with Google (free tier):**

```shell
gemini
# Choose "Sign in with Google" when prompted
```

**API Key:**

```shell
export GEMINI_API_KEY="your-key"
gemini
```

**Vertex AI (enterprise):**

```shell
export GOOGLE_API_KEY="your-key"
export GOOGLE_GENAI_USE_VERTEXAI=true
gemini
```

### MCP Server Integration

Configure in `~/.gemini/settings.json`:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

## Start / Usage

```shell
# Interactive mode in current directory
gemini

# Include specific directories
gemini --include-directories ../lib,../docs

# Use specific model
gemini -m gemini-2.5-flash

# Non-interactive (scripting)
gemini -p "Explain this codebase" --output-format json
```

**Key commands:**

- `/help` — Show available commands
- `/chat` — Switch to chat mode
- `@server` — Use MCP server

## Local Models via LiteLLM

Route Gemini CLI to local Ollama models through the [[LiteLLM]] proxy. LiteLLM translates the Gemini API format and maps model names via `model_group_alias`.

**Requirements:**
- LiteLLM proxy running on port 4000 (see [[LiteLLM]])
- Model with tool-calling support in its Ollama template (Qwen2.5 works; gemma3 does not)

```shell
# Start LiteLLM proxy
# litellm --config ~/.config/litellm/config.yaml --port 4000

# See ../setup_litellm.sh
launchctl start ai.litellm.proxy



# Point Gemini CLI at it (any dummy API key works)
export GOOGLE_GEMINI_BASE_URL="http://localhost:4000"
export GEMINI_API_KEY="sk-dummy"
gemini --sandbox=false
```

> `--sandbox=false` is required — the sandbox container does not inherit `GOOGLE_GEMINI_BASE_URL` ([known issue](https://github.com/google-gemini/gemini-cli/issues/2168)).

The LiteLLM config in this repo pre-configures aliases for all model names Gemini CLI uses internally:

```yaml
router_settings:
  model_group_alias:
    "gemini-2.5-pro":                     "qwen3.5:27b"
    "gemini-2.5-flash":                   "qwen3.5:27b"
    "gemini-2.5-flash-lite":              "qwen3-4b"
    "gemini-3-flash-preview":             "qwen3.5:27b"
    "gemini-3-flash-preview-customtools": "qwen3.5:27b"
    "gemini-3.1-pro-preview":             "qwen3-coder-30b-32k-q5"
    "gemini-3.1-pro-preview-customtools": "qwen3-coder-30b-32k-q5"
```

If you see `BadRequestError: There are no healthy deployments for this model`, add the missing model name to the alias map — Gemini CLI may use additional model names across versions.

## References

- [Gemini CLI Documentation](https://geminicli.com/docs/)
- [GitHub](https://github.com/google-gemini/gemini-cli)
- [NPM Package](https://www.npmjs.com/package/@google/gemini-cli)
