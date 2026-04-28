---
tags: [ai, coding, productivity, vscode]
---

# <img src="https://github.com/github.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> GitHub Copilot

Industry standard AI pair programmer for VS Code, JetBrains, and Neovim.

- **VS Code Extension:** `GitHub.copilot`
- **CLI:** `gh copilot` (requires GitHub CLI)

## Installation

```shell
gh extension install github/gh-copilot
```

Install the VS Code extension from the Marketplace: search **GitHub Copilot**.

## Ollama Integration (Local Models)

VS Code has native Ollama integration — no separate extension needed.

1. Open **Copilot Chat** sidebar
2. Click the settings gear icon
3. Click **Add Models** → select **Ollama**
4. Click **Unhide** to show your Ollama models

**Requirements:** Ollama v0.18.3+, VS Code 1.113+, GitHub Copilot Chat extension 0.41.0+

Models are installed per machine profile via `docs/02 - AI/install-models.sh`. Use the Copilot Chat model picker to select the Ollama model after enabling the integration.

Recommended chat model per profile (matches Cline primary):

| Profile         | Chat model               | Ollama alias |
| --------------- | ------------------------ | ------------ |
| macbook-m1-16gb | `qwen3:14b`              | `primary`    |
| macmini-m2-16gb | `qwen3:14b`              | `primary`    |
| macbook-m2-32gb | `qwen3-coder-30b:q5-32k` | `coding`     |
| macbook-m5-48gb | `qwen3-coder-30b:q5-32k` | `coding`     |
| macbook-m5-64gb | `qwen3-coder-30b:q6-32k` | `coding`     |

## BYOK (Bring Your Own Key)

Replace the default chat with any OpenAI-compatible model:

1. Run **Chat: Manage Language Models** (`Cmd+Shift+P`)
2. Add **OpenAI Compatible** provider
3. Set base URL: `http://localhost:11434/v1` (for Ollama)

Or via `settings.json` (substitute the model for your profile — see table above):

```json
{
  "github.copilot.chat.model": "ollama",
  "github.copilot.chat.customOAIModels": {
    "ollama": {
      "endpoint": "http://localhost:11434/v1",
      "model": "qwen3-coder-30b:q5-32k"
    }
  }
}
```

> BYOK works for chat; inline completions still require a paid GitHub Copilot subscription.

## References

- [GitHub Copilot](https://github.com/features/copilot)
- [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
- [gh copilot docs](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)
