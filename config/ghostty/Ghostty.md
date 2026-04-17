---
tags: [terminal, productivity, macos]
---

# Ghostty

Fast, native macOS terminal emulator written in Zig. GPU-accelerated, supports splits, tabs, and shell integration. Drop-in replacement for iTerm2 or Wezterm with lower latency.

- **Website:** [ghostty.org](https://ghostty.org)
- **Config reload:** `Cmd+Shift+,` (no restart needed)

## Installation

```shell
brew install --cask ghostty
```

## Config Location

`~/.config/ghostty/config`

The file in this repo is deployed there by `setup_ghostty.sh`.

## Key Settings (this config)

| Setting              | Value                                          | Notes                                     |
| -------------------- | ---------------------------------------------- | ----------------------------------------- |
| `font-family`        | `JetBrainsMono Nerd Font`                      | Nerd Font variant required for icons      |
| `font-size`          | `14`                                           |                                           |
| `theme`              | `light:Catppuccin Latte,dark:Catppuccin Mocha` | Auto-follows macOS appearance             |
| `background-opacity` | `0.92`                                         | Slight transparency                       |
| `background-blur`    | `20`                                           | macOS vibrancy blur                       |
| `shell-integration`  | `zsh`                                          | Enables cursor shape, sudo prompts, title |

## Keybindings (this config)

| Keybind                       | Action                         |
| ----------------------------- | ------------------------------ |
| `Cmd+D`                       | Split right                    |
| `Cmd+Shift+D`                 | Split down                     |
| `Cmd+Shift+Enter`             | New window                     |
| `Cmd+Alt+←/→/↑/↓`             | Navigate splits                |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab            |
| `Cmd+Backspace`               | Delete word (backward)         |
| `Cmd+S`                       | tmux session list (`Ctrl-a s`) |

## References

- [Ghostty docs](https://ghostty.org/docs)
- [Config reference](https://ghostty.org/docs/config/reference)
- [Catppuccin themes](https://github.com/catppuccin/ghostty)
