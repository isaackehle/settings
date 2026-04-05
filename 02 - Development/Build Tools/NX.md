---
tags: [development, build, monorepo]
---

# <img src="https://github.com/nrwl.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> NX

Smart, extensible build system for monorepos. Supports incremental builds, task caching, code generation, and integrations for React, Angular, Next.js, Node, and more.

## Installation

```shell
# New monorepo
npx create-nx-workspace@latest

# Add to existing repo
npx nx@latest init
```

## Configuration

`nx.json` at the repo root:

```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "targetDefaults": {
    "build": {
      "cache": true,
      "dependsOn": ["^build"],
      "outputs": ["{projectRoot}/dist"]
    },
    "test": {
      "cache": true
    },
    "lint": {
      "cache": true
    }
  },
  "defaultBase": "main"
}
```

## Start / Usage

```shell
nx build my-app              # Build a project
nx test my-app               # Test a project
nx lint my-app               # Lint a project
nx serve my-app              # Serve a project
nx graph                     # Visualize project dependency graph
nx affected --target=build   # Only run for affected projects
nx show projects             # List all projects
```

### Generators

```shell
nx generate @nx/react:app my-app          # Generate a React app
nx generate @nx/node:lib my-lib           # Generate a Node library
nx generate @nx/react:component MyComp   # Generate a component
```

## Remote Caching (Nx Cloud)

```shell
npx nx connect   # Connect to Nx Cloud for remote caching
```

## Workspace Structure

```text
my-workspace/
├── apps/
│   └── my-app/
├── libs/
│   └── shared-ui/
├── nx.json
└── package.json
```

## NX vs Turborepo

| Feature | NX | Turborepo |
| --- | --- | --- |
| Remote caching | Nx Cloud (free tier) | Vercel (free tier) |
| Code generators | Yes | No |
| Affected detection | Yes | Yes |
| Plugin ecosystem | Large | Small |
| Config complexity | Medium | Low |

## References

- [NX Docs](https://nx.dev/)
- [NX GitHub](https://github.com/nrwl/nx)
- [Nx Cloud](https://nx.app/)
