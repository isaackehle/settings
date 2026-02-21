---
tags: [node]
---

# <img src="https://github.com/nvm-sh.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> NVM

Node Version Manager — install and switch between multiple Node.js versions.

## Installation

```shell
brew install nvm
mkdir ~/.nvm
```

Add to `~/.zshrc`:

```shell
export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh
```

## Usage

```shell
# Install latest LTS
nvm install --lts

# Use a specific version
nvm install 20
nvm use 20

# Set default
nvm alias default 20

# Verify
node --version
```

## References

- [NVM on GitHub](https://github.com/nvm-sh/nvm)
