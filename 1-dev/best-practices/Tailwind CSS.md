---
tags: [development, css]
---

# <img src="https://github.com/tailwindlabs.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tailwind CSS

A utility-first CSS framework for rapid UI development.

## Installation

```shell
npm install -D tailwindcss
npx tailwindcss init
```

## Configuration

Update `tailwind.config.js`:

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {},
  },
  plugins: [],
}
```

Add to your CSS:

```css
@tailwind base;
@tailwind components;
@tailwind utilities;
```

## Usage

Use utility classes in your HTML/JSX:

```html
<div class="bg-blue-500 text-white p-4 rounded">Hello World</div>
```

## References

- [Tailwind CSS](https://tailwindcss.com/)