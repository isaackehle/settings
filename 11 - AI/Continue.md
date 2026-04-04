---
tags: [ai, coding, productivity]
---

# <img src="https://github.com/continuedev.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Continue

Open-source AI code assistant for VS Code and JetBrains that connects to local models or commercial APIs.

## Installation

VS Code: Install the `Continue.continue` extension from the Marketplace.

## Configuration

### Ollama Connection

1. Ensure Ollama is running locally (`ollama serve`)
2. Pull a model: `ollama pull llama3.2`
3. Create `~/.continue/config.json`:

```json
{
  "models": [
    {
      "title": "Ollama",
      "provider": "ollama",
      "model": "llama3.2",
      "apiBase": "http://localhost:11434"
    }
  ]
}
```

### Multiple Models

```json
{
  "models": [
    {
      "title": "Qwen Coder",
      "provider": "ollama",
      "model": "qwen3.2-coder:7b"
    },
    {
      "title": "Codestral",
      "provider": "openai",
      "model": "codestral-latest",
      "apiKey": "YOUR_API_KEY"
    }
  ],
  "tabAutocompleteModel": {
    "provider": "ollama",
    "model": "qwen3.2-coder:7b"
  }
}
```

### Other Providers

- **Anthropic:** `provider: "anthropic"`, `model: "claude-sonnet-4-20250514"`
- **OpenAI:** `provider: "openai"`, `model: "gpt-4o"`
- **Google Gemini:** `provider: "google-gemini"`, `model: "gemini-2.5-pro-preview-06-05"`
- **LM Studio:** `provider: "lmstudio"`, `model: "local-model"`

## Start / Usage

1. Open VS Code command palette (`Cmd+Shift+P`)
2. Type `Continue: Focus` to open the sidebar
3. Use `Cmd+L` to chat with the model
4. Use `Tab` for autocomplete suggestions

## References

- [Continue.dev](https://www.continue.dev/)
- [Documentation](https://docs.continue.dev/)
- [GitHub](https://github.com/continuedev/continue)
