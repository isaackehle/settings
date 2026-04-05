---
tags: [development, css]
---

# <img src="https://github.com/postcss.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> PostCSS

A tool for transforming CSS with JavaScript plugins.

## Installation

```shell
npm install -D postcss postcss-cli
```

## Usage

Create a `postcss.config.js`:

```js
module.exports = {
  plugins: [
    require('autoprefixer'),
    require('cssnano')
  ]
}
```

Process CSS:

```shell
npx postcss input.css -o output.css
```

## References

- [PostCSS](https://postcss.org/)