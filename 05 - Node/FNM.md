---
tags: [node]
---

# FNM

Fast Node Manager — a faster, Rust-based alternative to NVM.

## Installation

```shell
brew install fnm
```

Add to `~/.zshrc`:

```shell
eval "$(fnm env --use-on-cd --shell zsh)"
```

## Usage

```shell
# Install the version specified in .nvmrc / .node-version
fnm install

# Use the installed version
fnm use

# Install a specific version
fnm install 20

# List installed versions
fnm list
```

## References

- [FNM on GitHub](https://github.com/Schniz/fnm)
