---
tags: [ai, llm]
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

## References

- [Gemini CLI Documentation](https://geminicli.com/docs/)
- [GitHub](https://github.com/google-gemini/gemini-cli)
- [NPM Package](https://www.npmjs.com/package/@google/gemini-cli)
