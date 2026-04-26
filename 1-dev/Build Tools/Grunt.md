---
tags: [development, build]
---

# <img src="https://github.com/gruntjs.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Grunt

Configuration-based JavaScript task runner for automating repetitive tasks.

## Installation

```shell
npm install --save-dev grunt grunt-cli
```

## Configuration

`Gruntfile.js`:

```javascript
module.exports = function(grunt) {
  grunt.initConfig({
    uglify: {
      my_target: {
        files: {
          'dist/js/app.min.js': ['src/js/*.js'],
        },
      },
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

## Start / Usage

```shell
npx grunt          # Run default task
npx grunt uglify   # Run specific task
```

Key features: configuration-driven, extensive plugin library, multi-task and multi-file support.

## References

- [Grunt Documentation](https://gruntjs.com/)
