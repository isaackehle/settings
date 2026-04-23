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
| [Windsurf](https://windsurf.com/)                   | `brew install --cask windsurf`           |
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

## Start / Usage

Start: Open the app from Applications.

## References

- [VS Code Documentation](https://code.visualstudio.com/docs)
- [Vim cheat sheet](https://vim.rtorr.com/)
- [Helix Documentation](https://docs.helix-editor.com/)
