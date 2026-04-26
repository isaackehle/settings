---
tags: [development, build, monorepo]
---

# <img src="https://github.com/vercel.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Turborepo

High-performance build system for JavaScript/TypeScript monorepos. Caches task outputs locally and remotely to avoid redundant work.

## Installation

```shell
# New monorepo
npx create-turbo@latest

# Add to existing repo
npm install --save-dev turbo
```

## Configuration

`turbo.json` at the repo root:

```json
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": [".next/**", "dist/**"]
    },
    "test": {
      "dependsOn": ["^build"]
    },
    "lint": {},
    "dev": {
      "cache": false,
      "persistent": true
    }
  }
}
```

## Start / Usage

```shell
turbo build          # Build all packages
turbo test           # Test all packages
turbo lint           # Lint all packages
turbo dev            # Start all dev servers
turbo build --filter=web        # Run only for a specific package
turbo build --filter=web...     # Run for package and its dependencies
```

## Remote Caching

Connect to Vercel Remote Cache to share build artifacts across machines and CI:

```shell
npx turbo login
npx turbo link
```

## Workspace Structure

```text
my-monorepo/
├── apps/
│   ├── web/          # Next.js app
│   └── docs/         # Docs site
├── packages/
│   ├── ui/           # Shared component library
│   └── utils/        # Shared utilities
├── package.json
└── turbo.json
```

`package.json` at root:

```json
{
  "workspaces": ["apps/*", "packages/*"]
}
```

## References

- [Turborepo Docs](https://turbo.build/repo/docs)
- [Turborepo GitHub](https://github.com/vercel/turborepo)
