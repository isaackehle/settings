---
tags: [node]
---

# <img src="https://github.com/volta-cli.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Volta

Fast, reliable Node.js version manager. Pins Node and package manager versions per project automatically.

## Installation

```shell
curl https://get.volta.sh | bash
# or
brew install volta

volta setup
```

## Usage

```shell
# Install Node and Yarn globally
volta install node
volta install yarn

# Pin versions for a project (writes to package.json)
volta pin node@20
volta pin yarn@1
```

## References

- [Volta](https://volta.sh/)
- [Volta on GitHub](https://github.com/volta-cli/volta)
