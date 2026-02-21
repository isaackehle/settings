---
tags: [ai, coding, productivity]
---

# AI Coding Assistants

Tools to integrate AI directly into your development workflow.

## <img src="https://github.com/github.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> GitHub Copilot

The industry standard AI pair programmer. Integrates directly into VS Code, JetBrains, and Neovim.

- **VS Code Extension:** `GitHub.copilot`
- **CLI:** `gh copilot` (requires GitHub CLI)

```shell
gh extension install github/gh-copilot
```

## <img src="https://github.com/getcursor.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Cursor

[Cursor](https://cursor.sh/) is an AI-first code editor built as a fork of VS Code. It features deep codebase understanding and an integrated AI chat.

```shell
brew install --cask cursor
```

## <img src="https://github.com/continuedev.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Continue.dev

[Continue](https://continue.dev/) is an open-source AI code assistant for VS Code and JetBrains. It allows you to connect to local models (like Ollama) or commercial APIs (OpenAI, Anthropic).

- **VS Code Extension:** `Continue.continue`

## <img src="https://github.com/cline.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Claude Dev / Cline

[Cline](https://github.com/cline/cline) (formerly Claude Dev) is an autonomous coding agent right in your IDE that can create and edit files, run commands, and more.

- **VS Code Extension:** `saoudrizwan.claude-dev`

## Open Source & Terminal-Based Assistants

### <img src="https://github.com/charmbracelet.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenCode / Crush

[Crush](https://github.com/charmbracelet/crush) (formerly OpenCode) is a powerful terminal-based AI coding assistant by Charm. It provides a beautiful TUI, supports multiple LLMs, and integrates with LSPs and MCPs for deep context.

```shell
brew install charmbracelet/tap/crush
```

### <img src="https://github.com/OpenInterpreter.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Open Interpreter

[Open Interpreter](https://github.com/OpenInterpreter/open-interpreter) lets LLMs run code (Python, Javascript, Shell, and more) locally on your computer. You can chat with it in your terminal to control your computer.

```shell
pip install open-interpreter
interpreter
```

### <img src="https://github.com/paul-gauthier.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Aider

[Aider](https://github.com/paul-gauthier/aider) is an AI pair programming tool in your terminal. It works well with local models and commercial APIs, and directly commits changes to your git repo.

```shell
pip install aider-chat
aider
```

### <img src="https://github.com/TabbyML.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tabby

[Tabby](https://github.com/TabbyML/tabby) is an open-source, self-hosted AI coding assistant. It's a great alternative to GitHub Copilot if you want to keep your code completely private.

```shell
# Run via Docker
docker run -it -p 8080:8080 -v $HOME/.tabby:/data tabbyml/tabby serve --model StarCoder-1B
```

### <img src="https://github.com/All-Hands-AI.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenHands (formerly OpenDevin)

[OpenHands](https://github.com/All-Hands-AI/OpenHands) is an open-source platform for AI software developers that can autonomously write code, fix bugs, and ship features.

```shell
# Run via Docker
docker run -it --pull=always -e WORKSPACE_MOUNT_PATH=$(pwd) -v /var/run/docker.sock:/var/run/docker.sock -p 3000:3000 ghcr.io/all-hands-ai/openhands:main
```
