---
tags: [development, frontend, svelte]
---

# <img src="https://github.com/sveltejs.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> SvelteKit

The fastest way to build Svelte apps with a focus on developer experience and performance.

## Installation

```shell
npm create svelte@latest my-app
cd my-app
npm install
npm run dev
```

## Key Features

- **Compiler-first** — No virtual DOM, direct DOM updates
- **File-based routing** — Automatic routing from file structure
- **SSR/SSG** — Server-side rendering and static generation
- **TypeScript support** — Built-in TypeScript integration
- **Fast development** — Hot module replacement

## Project Structure

```
my-app/
├── src/
│   ├── routes/      # File-based routing (+page.svelte)
│   ├── components/  # Reusable components
│   ├── lib/         # Utilities and stores
│   └── app.html     # HTML template
├── static/          # Static assets
└── svelte.config.js # Configuration
```

## Usage

```svelte
<!-- src/routes/+page.svelte -->
<script>
  let count = 0;
</script>

<h1>SvelteKit Counter</h1>
<button on:click={() => count++}>
  Count: {count}
</button>

<style>
  button {
    background: #ff3e00;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
  }
</style>
```

## References

- [SvelteKit Documentation](https://kit.svelte.dev/)
- [SvelteKit GitHub](https://github.com/sveltejs/kit)