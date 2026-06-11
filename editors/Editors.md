---
tags: [editors]
---

# <img src="https://github.com/microsoft.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Editors

Code editors and IDEs available via Homebrew.

## Installation

| Tool                                                | Command                                  |
| --------------------------------------------------- | ---------------------------------------- |
| [Araxis Merge](https://www.araxis.com/merge/)       | `brew install --cask araxis-merge`       |
| [Cursor](https://cursor.com/)                       | `brew install --cask cursor`             |
| [Helix](https://helix-editor.com/)                  | `brew install helix`                     |
| [IntelliJ IDEA CE](https://www.jetbrains.com/idea/) | `brew install --cask intellij-idea-ce`   |
| [MacVim](https://macvim.org/macvim/)                | `brew install --cask macvim`             |
| [Obsidian](https://obsidian.md/)                    | `brew install --cask obsidian`           |
| [PyCharm CE](https://www.jetbrains.com/pycharm/)    | `brew install --cask pycharm-ce`         |
| [Sublime Text](https://www.sublimetext.com/)        | `brew install --cask sublime-text`       |
| [VS Code](https://code.visualstudio.com/)           | `brew install --cask visual-studio-code` |
| [WebStorm](https://www.jetbrains.com/webstorm/)     | `brew install --cask webstorm`           |
| [Devin](https://devin.ai/)                          | `brew install --cask devin`              |
| [Zed](https://zed.dev/)                             | `brew install --cask zed`                |

## Configuration

### Helix

```bash
# Set as default editor
export EDITOR=hx
export VISUAL=hx
```

### Vim (`~/.vimrc`)

```vim
filetype plugin indent on
syntax on
set term=xterm-256color
```

### Helix (`~/.config/helix/config.toml`)

```toml
theme = "catppuccin_mocha"

[editor]
line-number = "relative"
mouse = false
```

### Cursor

Cursor is VS Code-based with built-in AI pair programming.

```shell
# Open files with the Cursor CLI
cursor <path>
```

**Ollama Integration:** Settings (Cmd+Shift+J) → Models → OpenAI Base URL → `http://localhost:11434/v1`, API Key: `sk-local`

Config path: `~/Library/Application Support/Cursor/User/settings.json`

### Kilo Code

VS Code/Cursor extension for agentic coding with multi-agent mode support.

```shell
# Install extension
code --install-extension kilohealth.kilo-code
```

Config deploys from profile to `~/.kilo/kilo.jsonc`

**Ollama:** Base URL `http://localhost:11434/v1`, API Key `sk-local`

## Start / Usage

Start: Open the app from Applications.

## References

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [Vim cheat sheet](https://vim.rtorr.com/)
- [Helix Documentation](https://docs.helix-editor.com/)
- [Cursor Documentation](https://docs.cursor.com/)
- [Kilo Code Docs](https://kilocode.ai/docs)
- [Devin Desktop Docs](https://docs.devin.ai/desktop)
