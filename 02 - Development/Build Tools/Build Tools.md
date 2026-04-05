---
tags: [development, build]
---

# Build Tools

Tools for automating the build process, bundling assets, and optimizing applications for production.

## Module Bundlers

### Webpack

A powerful and highly configurable module bundler for modern JavaScript applications.

**Installation:**
```bash
npm install --save-dev webpack webpack-cli
```

**Basic Configuration (`webpack.config.js`):**
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

**Key Features:**
- Code splitting and lazy loading
- Asset optimization (images, fonts, CSS)
- Development server with hot reloading
- Plugin ecosystem for customization

### Vite

See [[Vite]] for full setup and configuration.

### Rollup

A module bundler optimized for libraries and applications that use ES modules.

**Installation:**
```bash
npm install --save-dev rollup
```

**Configuration (`rollup.config.js`):**
```javascript
export default {
  input: 'src/main.js',
  output: {
    file: 'dist/bundle.js',
    format: 'cjs' // or 'esm', 'umd', etc.
  }
};
```

**Key Features:**
- Tree shaking (removes unused code)
- ES module focused
- Plugin system for extensibility
- Optimized for library development

### Parcel

A zero-configuration build tool that works out of the box.

**Installation:**
```bash
npm install --save-dev parcel
```

**Usage:**
```bash
npx parcel index.html  # Development server
npx parcel build index.html  # Production build
```

**Key Features:**
- **Zero Config** — Works without configuration files
- **Multi-language Support** — JS, TypeScript, CSS, HTML, etc.
- **Automatic Transformations** — Babel, PostCSS, etc.
- **Code Splitting** — Automatic optimization

## Task Runners

### Gulp

A streaming build system that uses Node.js streams for fast build pipelines.

**Installation:**
```bash
npm install --save-dev gulp
```

**Configuration (`gulpfile.js`):**
```javascript
const gulp = require('gulp');
const sass = require('gulp-sass');

function styles() {
  return gulp.src('src/styles/*.scss')
    .pipe(sass())
    .pipe(gulp.dest('dist/css'));
}

function watch() {
  gulp.watch('src/styles/*.scss', styles);
}

exports.styles = styles;
exports.watch = watch;
exports.default = gulp.series(styles, watch);
```

**Key Features:**
- **Streams-based** — Fast processing using Node.js streams
- **Plugin Ecosystem** — Thousands of plugins available
- **Task Composition** — Combine tasks in series/parallel
- **File Watching** — Automatic rebuilds on file changes

### Grunt

A JavaScript task runner that automates repetitive tasks like minification and compilation.

**Installation:**
```bash
npm install --save-dev grunt
```

**Configuration (`Gruntfile.js`):**
```javascript
module.exports = function(grunt) {
  grunt.initConfig({
    uglify: {
      my_target: {
        files: {
          'dist/js/app.min.js': ['src/js/*.js']
        }
      }
    },
    watch: {
      scripts: {
        files: ['src/js/*.js'],
        tasks: ['uglify'],
      },
    },
  });

  grunt.loadNpmTasks('grunt-contrib-uglify');
  grunt.loadNpmTasks('grunt-contrib-watch');
  grunt.registerTask('default', ['uglify']);
};
```

**Key Features:**
- **Configuration-based** — All tasks defined in config object
- **Plugin System** — Extensive plugin library
- **Multi-task** — Handle multiple files and destinations
- **Linting Integration** — Built-in JSHint support

## Build Tool Comparison

| Tool    | Best For          | Config | Performance | Learning |
| ------- | ----------------- | ------ | ----------- | -------- |
| Webpack | Complex apps      | High   | Good        | Steep    |
| Vite    | Modern apps       | Low    | Excellent   | Gentle   |
| Rollup  | Libraries         | Medium | Excellent   | Medium   |
| Parcel  | Quick projects    | None   | Good        | Gentle   |
| Gulp    | Custom workflows  | Medium | Excellent   | Medium   |
| Grunt   | Simple automation | High   | Good        | Gentle   |

## Additional Tools

### esbuild
Extremely fast JavaScript bundler written in Go.

```bash
npm install --save-dev esbuild
npx esbuild src/app.js --bundle --outfile=dist/app.js
```

### Turborepo
High-performance build system for monorepos.

```bash
npx create-turbo@latest
```

### NX
Smart, fast, and extensible build system.

```bash
npx nx@latest init
```

## Best Practices

1. **Choose the Right Tool** — Match tool complexity to project needs
2. **Use Source Maps** — For debugging bundled code
3. **Implement Code Splitting** — For better performance
4. **Optimize Assets** — Compress images, minify code
5. **Use Caching** — For faster rebuilds
6. **Monitor Bundle Size** — Prevent JavaScript bloat

## References

- [Webpack Documentation](https://webpack.js.org/)
- [Vite Guide](https://vitejs.dev/guide/)
- [Rollup Handbook](https://rollupjs.org/guide/en/)
- [Parcel Documentation](https://parceljs.org/)
- [Gulp Documentation](https://gulpjs.com/)
- [Grunt Documentation](https://gruntjs.com/)
- [Build Tools Comparison](https://webpack.js.org/comparison/)