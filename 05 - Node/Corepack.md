---
tags: [node]
---

# <img src="https://github.com/nodejs.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Corepack

Built-in Node.js tool (since v16.9) that manages package managers (npm, yarn, pnpm) per project, ensuring teams use consistent versions.

## Installation

Corepack ships with Node.js. Enable it:

```shell
corepack enable
```

Or install via Homebrew if needed:

```shell
brew install corepack
```

## Usage

```shell
# Activate a specific package manager version
corepack prepare pnpm@latest --activate
corepack prepare yarn@4 --activate
```

Projects declare their package manager in `package.json`:

```json
{
  "packageManager": "pnpm@9.0.0"
}
```

## References

- [Corepack documentation](https://nodejs.org/api/corepack.html)
