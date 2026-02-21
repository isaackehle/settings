---
tags: [setup]
---

# <img src="https://github.com/Homebrew.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Homebrew

macOS's missing package manager. Used to install CLI tools and GUI apps (via Cask).

## Installation

```shell
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install commonly useful GNU tools:

```shell
brew install coreutils moreutils findutils
```

## Usage

```shell
# Update Homebrew and all packages
brew update && brew upgrade

# Check for issues
brew doctor

# Remove old cached versions
brew cleanup
```

## References

- [Homebrew](https://brew.sh/)
- [Homebrew Cask Upgrade](https://github.com/buo/homebrew-cask-upgrade)
