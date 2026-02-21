---
tags: [terminal]
---

# iTerm2

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

Browse color schemes at [iterm2colorschemes.com](http://iterm2colorschemes.com/).

## Key Bindings

Configure in iTerm2 → Preferences → Profiles → Keys → Key Mappings.

| Action | Shortcut | Type | Value |
|---|---|---|---|
| Delete word | `⌥ ⌫` | Send Hex Code | `0x17` |
| Delete line | `⌥ ↑ ⌫` | Send Hex Code | `0x15` |
| Jump left (word) | `⌥ ←` | Send Escape Sequence | `b` |
| Jump right (word) | `⌥ →` | Send Escape Sequence | `f` |

## References

- [iTerm2 + Oh My Zsh guide](https://catalins.tech/improve-mac-terminal/)
- [Use ⌥← and ⌥→ to jump words in iTerm2](https://coderwall.com/p/h6yfda/use-and-to-jump-forwards-backwards-words-in-iterm-2-on-os-x)
- [8 iTerm plugins to boost productivity](https://udaraw.com/iterm-plugins/)
