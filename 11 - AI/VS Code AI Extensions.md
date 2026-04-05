---
tags: [ai, coding, productivity]
---

# VS Code AI Extensions

VS Code extensions that bring AI coding assistance directly into the editor.

## <img src="https://github.com/github.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> GitHub Copilot

The industry standard AI pair programmer for VS Code, JetBrains, and Neovim.

- **VS Code Extension:** `GitHub.copilot`
- **CLI:** `gh copilot` (requires GitHub CLI)

```shell
gh extension install github/gh-copilot
```

## <img src="https://github.com/continuedev.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Continue.dev

[Continue](https://www.continue.dev/) is an open-source AI code assistant for VS Code and JetBrains that can connect to local models or commercial APIs.

- **VS Code Extension:** `Continue.continue`
- See [[Continue]] for full configuration with Ollama.

## <img src="https://github.com/cline.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Claude Dev / Cline

[Cline](https://github.com/cline/cline) is an autonomous coding agent for your IDE that can create and edit files and run commands.

- **VS Code Extension:** `saoudrizwan.claude-dev`

## Built-in Chat (BYOK)

VS Code supports Bring Your Own Key (BYOK) to replace the default chat with custom models including Ollama.

### Configuration

1. Run **Chat: Manage Language Models** from command palette (`Cmd+Shift+P`)
2. Add **OpenAI Compatible** provider
3. Set the base URL: `http://localhost:11434/v1` (Ollama)

### Settings (`settings.json`)

```json
{
  "github.copilot.chat.model": "ollama",
  "github.copilot.chat.customOAIModels": {
    "ollama": {
      "endpoint": "http://localhost:11434/v1",
      "model": "qwen3.2-coder:7b"
    }
  }
}
```

> **Note:** These settings may show as "Unknown Configuration Setting" in the VS Code settings editor — this is expected as they are marked *(Experimental)*. They still function correctly.

### Ollama Setup

```shell
# Ensure Ollama is running
ollama serve

# Pull a coding model
ollama pull qwen3.2-coder:7b
```

Note: BYOK chat works with custom models, but completions (inline suggestions) still require GitHub Copilot.

## <img src="https://github.com/ollama.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Ollama VS Code Integration

VS Code has native integration with Ollama — no separate extension needed. Works with GitHub Copilot Chat to provide local model selection.

### Quick Setup

```shell
ollama launch vscode
```

This will recommend models and configure VS Code automatically. Select **Local** at the bottom of the Copilot Chat panel.

### Manual Setup

1. Open **Copilot Chat** sidebar
2. Click the settings gear icon
3. Click **Add Models** → select **Ollama**
4. Click **Unhide** to show your Ollama models

### Requirements

- Ollama v0.18.3+
- VS Code 1.113+
- GitHub Copilot Chat extension 0.41.0+
- GitHub Copilot Free or paid (required for model selector)

### Models

Use a coding model for best results:

```shell
ollama pull qwen3.2-coder:7b
ollama pull deepseek-coder:6.7b
ollama pull codestral:22b
```

See: [[Ollama]]
