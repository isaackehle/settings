---
tags: [development, build]
---

# Build Tools

Tools for bundling assets, running tasks, and optimizing applications for production.

## Module Bundlers

| Tool | Best For | Config | Performance |
| --- | --- | --- | --- |
| [[Grunt]] | Simple automation | High | Good |
| [[Gulp]] | Custom workflows | Medium | Excellent |
| [[Parcel]] | Quick projects | None | Good |
| [[Rollup]] | Libraries | Medium | Excellent |
| [[Turborepo]] | Monorepos | Low | Excellent |
| [[Vite]] | Modern apps | Low | Excellent |
| [[Webpack]] | Complex apps | High | Good |

## Additional Tools

### esbuild

Extremely fast JavaScript bundler written in Go.

```shell
npm install --save-dev esbuild
npx esbuild src/app.js --bundle --outfile=dist/app.js
```

### NX

Smart, extensible build system.

```shell
npx nx@latest init
```

## References

- [Webpack](https://webpack.js.org/)
- [Vite](https://vite.dev/)
- [Rollup](https://rollupjs.org/)
- [Parcel](https://parceljs.org/)
- [Gulp](https://gulpjs.com/)
- [Grunt](https://gruntjs.com/)
