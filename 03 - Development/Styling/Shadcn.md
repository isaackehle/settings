---
tags: [development, css, react]
---

# <img src="https://github.com/shadcn-ui.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Shadcn/ui

Beautifully designed components built with Radix UI and Tailwind CSS.

## Prerequisites

- [[Tailwind CSS]] — Required for styling
- React project

## Installation

```shell
npx shadcn-ui@latest init
```

## Usage

Add components to your project:

```shell
npx shadcn-ui@latest add button
npx shadcn-ui@latest add input
```

Use in your components:

```jsx
import { Button } from "@/components/ui/button"

export function MyComponent() {
  return <Button>Click me</Button>
}
```

## References

- [Shadcn/ui](https://ui.shadcn.com/)