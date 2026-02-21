---
tags: [terminal]
---

# <img src="https://github.com/gnachman.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> iTerm2

A feature-rich terminal emulator for macOS, replacing the built-in Terminal app.

## Installation

```shell
brew install iterm2
```

## Configuration

### Starship prompt

Starship is a fast, customizable cross-shell prompt. Install and add it to your profile:

```shell
brew install starship
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
```

### Themes

Browse color schemes at [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes).

## Key Bindings

Configure in iTerm2 → Preferences → Profiles → Keys → Key Mappings.

| Action            | Shortcut | Type                 | Value  |
| ----------------- | -------- | -------------------- | ------ |
| Delete word       | `⌥ ⌫`    | Send Hex Code        | `0x17` |
| Delete line       | `⌥ ↑ ⌫`  | Send Hex Code        | `0x15` |
| Jump left (word)  | `⌥ ←`    | Send Escape Sequence | `b`    |
| Jump right (word) | `⌥ →`    | Send Escape Sequence | `f`    |

## References

- [iTerm2 Documentation](https://iterm2.com/documentation.html)
- [iTerm2 Shell Integration](https://iterm2.com/documentation-shell-integration.html)
- [iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
