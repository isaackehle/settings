---
tags: [ai, coding, productivity]
---

# <img src="https://github.com/continuedev.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Continue

Open-source AI code assistant for VS Code and JetBrains that connects to local models or commercial APIs.

## Installation

VS Code: Install the `Continue.continue` extension from the Marketplace.

## Setup

Pull the required Ollama models:

```sh
ollama pull llama3.1:8b
ollama pull qwen2.5-coder:1.5b-base
ollama pull nomic-embed-text:latest
```

## Configuration

Config lives at `~/.continue/config.yaml`.

```yaml
name: Local Config
version: 1.0.0
schema: v1
models:
  - name: Llama 3.1 8B
    provider: ollama
    model: llama3.1:8b
    roles:
      - chat
      - edit
      - apply
  - name: Qwen2.5-Coder 1.5B
    provider: ollama
    model: qwen2.5-coder:1.5b-base
    roles:
      - autocomplete
  - name: Nomic Embed
    provider: ollama
    model: nomic-embed-text:latest
    roles:
      - embed
```

### Roles

| Role           | Purpose                            |
| -------------- | ---------------------------------- |
| `chat`         | Main chat / Q&A                    |
| `edit`         | Inline edit suggestions            |
| `apply`        | Apply diffs to files               |
| `autocomplete` | Tab completion                     |
| `embed`        | Codebase indexing / context search |

### Other Providers

- **Anthropic:** `provider: anthropic`, `model: claude-sonnet-4-20250514`
- **OpenAI:** `provider: openai`, `model: gpt-4o`
- **Google:** `provider: google-gemini`, `model: gemini-2.5-pro-preview-06-05`
- **LM Studio:** `provider: lmstudio`, `model: local-model`
- **Codestral:** `provider: openai`, `model: codestral-latest` (Mistral API key)

## Usage

| Shortcut                          | Action                     |
| --------------------------------- | -------------------------- |
| `Cmd+L`                           | Open chat / send selection |
| `Tab`                             | Accept autocomplete        |
| `Cmd+Shift+P` → `Continue: Focus` | Open sidebar               |

## References

- [Continue.dev](https://www.continue.dev/)
- [Documentation](https://docs.continue.dev/)
- [GitHub](https://github.com/continuedev/continue)
