---
tags: [development, build]
---

# <img src="https://github.com/rollup.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Rollup

Module bundler optimized for libraries and ES module output.

## Installation

```shell
npm install --save-dev rollup
```

## Configuration

`rollup.config.js`:

```javascript
export default {
  input: 'src/main.js',
  output: {
    file: 'dist/bundle.js',
    format: 'esm', // or 'cjs', 'umd', 'iife'
  },
};
```

## Start / Usage

```shell
npx rollup --config          # Build using config file
npx rollup --config --watch  # Watch mode
```

Key features: tree shaking, ES module output, optimized for library development.

## References

- [Rollup Handbook](https://rollupjs.org/guide/en/)
