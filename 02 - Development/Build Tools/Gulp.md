---
tags: [development, build]
---

# <img src="https://github.com/gulpjs.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Gulp

Streaming build system using Node.js streams for custom build pipelines.

## Installation

```shell
npm install --save-dev gulp
```

## Configuration

`gulpfile.js`:

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

## Start / Usage

```shell
npx gulp          # Run default task
npx gulp styles   # Run specific task
npx gulp watch    # Watch mode
```

Key features: streams-based processing, thousands of plugins, series/parallel task composition.

## References

- [Gulp Documentation](https://gulpjs.com/)
