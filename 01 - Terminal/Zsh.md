---
tags: [terminal]
---

# <img src="https://github.com/ohmyzsh.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Zsh

Zsh is the default shell on macOS. Oh My Zsh adds themes, plugins, and quality-of-life improvements.

## Installation

```shell
brew install zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

## Configuration

Recommended plugins in `~/.zshrc`:

```shell
plugins=(git bundler macos rake ruby)
```

## Theme

[powerlevel10k](https://github.com/romkatv/powerlevel10k) is a fast, feature-rich theme with an interactive setup wizard.

```shell
brew install powerlevel10k
echo 'source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc
```

Then restart the terminal to run the configuration wizard.

## References

- [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh)
- [Theme Gallery](https://github.com/ohmyzsh/ohmyzsh/wiki/themes)
- [powerlevel10k](https://github.com/romkatv/powerlevel10k)
