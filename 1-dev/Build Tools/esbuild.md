---
tags: [development, build]
---

# <img src="https://github.com/evanw.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> esbuild

Extremely fast JavaScript and TypeScript bundler written in Go. Orders of magnitude faster than Webpack or Rollup for large codebases.

## Installation

```shell
npm install --save-dev esbuild
```

## Configuration

No config file required for basic use. For complex setups, use a build script:

```javascript
// build.mjs
import * as esbuild from 'esbuild'

await esbuild.build({
  entryPoints: ['src/app.ts'],
  bundle: true,
  outfile: 'dist/app.js',
  platform: 'node',       // or 'browser'
  format: 'esm',          // or 'cjs', 'iife'
  minify: true,
  sourcemap: true,
})
```

## Start / Usage

```shell
# Bundle to a file
npx esbuild src/app.ts --bundle --outfile=dist/app.js

# Watch mode
npx esbuild src/app.ts --bundle --outfile=dist/app.js --watch

# Dev server
npx esbuild src/app.ts --bundle --servedir=public

# Minified production build
npx esbuild src/app.ts --bundle --minify --outfile=dist/app.min.js
```

Key features: sub-second builds, TypeScript/JSX built in, tree shaking, source maps, no config required.

## References

- [esbuild Docs](https://esbuild.github.io/)
- [esbuild GitHub](https://github.com/evanw/esbuild)
