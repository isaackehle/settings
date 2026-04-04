---
tags: [ai, coding, productivity]
---

# AI Coding Assistants

Tools to integrate AI directly into your development workflow.

## Configuration

No basic configuration required.

Common first-run configuration:

- Sign in to your provider account.
- Select your default model/provider in extension settings.

## Start / Usage

- VS Code extensions: open VS Code and use the extension sidebar/chat panel.
- Cursor: Start: Open the app from Applications.

```shell
gh copilot suggest "explain this function"
```

See more: [[VS Code AI Extensions]]

## Open Source & Terminal-Based Assistants

### <img src="https://github.com/charmbracelet.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenCode / Crush

[OpenCode / Crush](https://github.com/charmbracelet/crush) is a powerful terminal-based AI coding assistant by Charm. It provides a beautiful TUI, supports multiple LLMs, and integrates with LSPs and MCPs for deep context.

```shell
brew install charmbracelet/tap/crush
```

No basic configuration required.

```shell
crush
```

See more: [[OpenCode]]

### <img src="https://github.com/OpenInterpreter.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Open Interpreter

[Open Interpreter](https://github.com/OpenInterpreter/open-interpreter) lets LLMs run code (Python, Javascript, Shell, and more) locally on your computer. You can chat with it in your terminal to control your computer.

```shell
pip install open-interpreter
interpreter
```

### <img src="https://github.com/Aider-AI.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Aider

[Aider](https://github.com/Aider-AI/aider) is an AI pair programming tool in your terminal. It works well with local models and commercial APIs, and directly commits changes to your git repo.

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

### <img src="https://github.com/OpenHands.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenHands (formerly OpenDevin)

[OpenHands](https://github.com/OpenHands/OpenHands) is an open-source platform for AI software developers that can autonomously write code, fix bugs, and ship features.

```shell
# Run via Docker
docker run -it --pull=always -e WORKSPACE_MOUNT_PATH=$(pwd) -v /var/run/docker.sock:/var/run/docker.sock -p 3000:3000 ghcr.io/all-hands-ai/openhands:main
```
