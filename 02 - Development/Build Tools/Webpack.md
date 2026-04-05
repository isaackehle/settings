---
tags: [development, build]
---

# <img src="https://github.com/webpack.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Webpack

Powerful, highly configurable module bundler for modern JavaScript applications.

## Installation

```shell
npm install --save-dev webpack webpack-cli
```

## Configuration

`webpack.config.js`:

```javascript
const path = require('path');

module.exports = {
  entry: './src/index.js',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
  },
  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: /node_modules/,
        use: 'babel-loader',
      },
    ],
  },
};
```

## Start / Usage

```shell
npx webpack              # Build once
npx webpack --watch      # Watch mode
npx webpack serve        # Dev server with HMR
```

Key features: code splitting, lazy loading, asset optimization, extensive plugin ecosystem.

## References

- [Webpack Documentation](https://webpack.js.org/)
- [Webpack Comparison](https://webpack.js.org/comparison/)
