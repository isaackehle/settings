---
tags: [development]
---

# <img src="https://github.com/vitejs.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Vite

A modern frontend build tool and dev server with very fast startup.

## Installation

```shell
npm create vite@latest my-app
cd my-app
npm install
```

## Configuration

No basic configuration required. Vite auto-detects the framework from your project.

Optional `vite.config.ts`:

```ts
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    outDir: 'dist',
  },
})
```

## Start / Usage

```shell
npm run dev      # Start dev server (instant startup, HMR)
npm run build    # Production build via Rollup
npm run preview  # Preview production build locally
```

**Key features:**
- Native ES modules in dev — no bundling, instant startup
- Hot Module Replacement without page refresh
- Rollup-based production builds with tree shaking

## References

- [Vite](https://vite.dev/)
- [Vite Guide](https://vite.dev/guide/)
- [Vite Config Reference](https://vite.dev/config/)