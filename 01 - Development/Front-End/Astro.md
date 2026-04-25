---
tags: [development, frontend]
---

# <img src="https://github.com/withastro.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Astro

Build faster websites with less client-side JavaScript using component islands architecture.

## Installation

```shell
npm create astro@latest my-astro-site
cd my-astro-site
npm install
npm run dev
```

## Key Features

- **Component Islands** — Partial hydration for optimal performance
- **Multi-framework** — Use React, Vue, Svelte, Solid, etc.
- **Zero JS by default** — Only hydrate interactive components
- **Static-first** — Optimized for static site generation
- **Content collections** — Type-safe content management

## Project Structure

```
my-astro-site/
├── src/
│   ├── components/  # UI components
│   ├── layouts/     # Page layouts
│   ├── pages/       # File-based routing
│   └── content/     # Content collections
├── public/          # Static assets
└── astro.config.mjs # Configuration
```

## Usage

```astro
---
// src/pages/index.astro
import Layout from '../layouts/Layout.astro';
import Card from '../components/Card.jsx'; // React component
---

<Layout title="My Astro Site">
  <h1>Welcome to Astro</h1>

  <!-- Static HTML -->
  <p>This loads instantly</p>

  <!-- Interactive island -->
  <Card client:load />
</Layout>
```

## References

- [Astro Documentation](https://docs.astro.build/)
- [Astro GitHub](https://github.com/withastro/astro)