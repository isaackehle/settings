---
tags: [development, frontend, vue]
---

# <img src="https://github.com/nuxt.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Nuxt.js

The intuitive Vue.js framework for building universal and SPA applications.

## Installation

```shell
npx nuxi@latest init my-nuxt-app
cd my-nuxt-app
npm install
```

## Key Features

- **File-based routing** — Automatic routes from file structure
- **Server-side rendering** — SSR out of the box
- **Static site generation** — Generate static sites
- **Vue ecosystem** — Full Vue.js compatibility
- **Auto-imports** — No need to import composables

## Project Structure

```
my-nuxt-app/
├── pages/          # File-based routing
├── components/     # Vue components
├── layouts/        # Layout templates
├── plugins/        # Vue plugins
├── middleware/     # Route middleware
├── store/          # Vuex store (optional)
└── nuxt.config.ts  # Configuration
```

## Usage

```vue
<!-- pages/index.vue -->
<template>
  <div>
    <h1>Welcome to Nuxt.js</h1>
    <NuxtLink to="/about">About</NuxtLink>
  </div>
</template>

<script setup>
// Auto-imported composables
const { $fetch } = useNuxtApp()
</script>
```

## References

- [Nuxt.js Documentation](https://nuxt.com/docs)
- [Nuxt.js GitHub](https://github.com/nuxt/nuxt)