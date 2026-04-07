---
tags: [development, ai, agents]
---

# [Project Name] — Frontend Agent Instructions

> **Canonical agent config.** This file overrides tool-specific files (`CLAUDE.md`, `.cursorrules`, `.github/copilot-instructions.md`, `.windsurfrules`). Those files are symlinks — edit this one.

## Purpose

<!-- Replace with your project description -->

---

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Next.js 15 (App Router) |
| UI runtime | React 19 |
| Language | TypeScript (strict) |
| Package manager | pnpm |
| Node | 22.x (`.nvmrc` or `mise`) |
| Styling | Tailwind CSS v4 · Chakra UI v3 (pick one or both) |
| Data / ORM | Drizzle ORM (if the frontend owns DB access) |
| Platform | macOS Apple Silicon (`darwin/arm64`) |

---

## Key Commands

```bash
pnpm install          # install deps (frozen lockfile in CI)
pnpm dev              # start dev server (localhost:3000)
pnpm build            # production build
pnpm typecheck        # tsc --noEmit
pnpm lint             # eslint + prettier --check
pnpm test             # vitest run
pnpm test src/foo     # run a single file / pattern
```

---

## Project Structure

```
.
├── app/                  # Next.js App Router — layouts, pages, route handlers
│   ├── (marketing)/      # route groups
│   └── api/              # Route Handlers (not Pages /api)
├── components/           # shared UI — colocate tests alongside components
├── lib/                  # pure utilities, shared logic, server-only helpers
├── hooks/                # client-side React hooks
├── styles/               # global CSS / Tailwind base
├── public/               # static assets
└── drizzle/              # schema + migrations (if applicable)
```

<!-- Extend or replace the tree above to match your repo layout -->

---

## Non-Obvious Patterns

<!-- Add project-specific gotchas here. Examples kept as prompts: -->

- **Server Components by default.** Only add `"use client"` when you need browser APIs, event handlers, or client state. Justify it in a comment.
- **Route Handlers, not Pages API.** All API endpoints live in `app/api/**/route.ts` and export named HTTP-method functions (`GET`, `POST`, …).
- **`server-only` guard.** Import `server-only` at the top of any module that must never reach the client bundle.
- **Data fetching.** Prefer `fetch` with Next.js cache tags over client-side fetching in RSCs. Use `unstable_cache` for non-`fetch` data sources.
- **Environment variables.** Public vars are prefixed `NEXT_PUBLIC_`. Secret vars are accessed only in server contexts; never read them in Client Components.
- **Tailwind / Chakra coexistence.** If using both, Chakra's `ColorModeProvider` must wrap below `<html>` in the root layout.

---

## Code Style

<!-- markdownlint-disable MD013 -->
- **Named exports only** — no default exports except `page.tsx`, `layout.tsx`, `error.tsx`, `loading.tsx`, and `route.ts` (Next.js file conventions).
- **`const` arrow functions** for all components and utilities: `export const MyComponent = () => { … }`.
- **Absolute imports** via `@/` (configured in `tsconfig.json` `paths`). Never use `../../../`.
- **File length.** Keep files under 200 lines. Extract when they grow beyond that.
- **No `any`.** Use `unknown` + type guards or define explicit types. `@ts-ignore` requires a TODO comment with a ticket reference.
- **Prefer composition.** Small, single-responsibility components over large monoliths.
<!-- markdownlint-enable MD013 -->

---

## Testing Rules

- **Runner:** Vitest + React Testing Library (`@testing-library/react`).
- **Deterministic.** No `Math.random()`, no `Date.now()` without mocking (`vi.useFakeTimers()`).
- **Isolated.** Each test is self-contained — no shared mutable state between tests.
- **Mock externals.** Network calls → `msw`. Module mocks → `vi.mock()`. Never hit real endpoints in unit tests.
- **Coverage.** Aim for meaningful assertions, not coverage %. Don't test implementation details.
- **Test file location.** Colocate: `components/Button/Button.test.tsx` next to `Button.tsx`.

---

## Git Commits

- Follow **Conventional Commits**: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`.
- Scope is optional but encouraged: `feat(auth): add OAuth callback route`.
- **No `Co-Authored-By` trailers.** Do not add authorship lines attributing commits to AI tools.
- Keep the subject line under 72 characters.
- One logical change per commit. Squash fixups before opening a PR.

---

## Agent Skills

<!-- markdownlint-disable MD013 -->
Skills extend agent behaviour with reusable, version-controlled instructions.

**Skill directories (checked in order):**

1. `.agents/skills/` — project-scoped skills committed to this repo
2. `~/.agents/skills/` — user-scoped global skills on this machine

**CLI:**

```bash
npx skills list                          # show installed skills
npx skills add vercel-react-best-practices
npx skills add frontend-design
npx skills add web-design-guidelines
npx skills add shadcn
```

**Suggested skills for this stack:** `vercel-react-best-practices`, `frontend-design`, `web-design-guidelines`, `shadcn`

<!-- Add or remove skills that apply to this project -->
<!-- markdownlint-enable MD013 -->

---

## Boundaries

| Tier | Actions |
|---|---|
| ✅ **Allowed** | Read any file · run `lint`, `typecheck`, `test` · create or modify files under `app/`, `components/`, `lib/`, `hooks/`, `styles/` |
| ⚠️ **Ask first** | Install or remove dependencies · delete files · rename/move directories · open PRs or push to remote |
| 🚫 **Never** | Read or write secrets / `.env.local` · `git push --force` · modify `dist/`, `.next/`, `out/`, or generated type files |

---

## Modular Overrides

Subdirectory `AGENTS.md` files narrow scope for specific areas:

- `components/AGENTS.md` — component conventions, design-token usage, a11y rules
- `app/api/AGENTS.md` — Route Handler patterns, auth middleware, error response shapes
- `lib/AGENTS.md` — utility constraints, server-only guards, shared type contracts

<!-- Create these files as the codebase grows; they inherit from this root file -->

---

## Tool-Specific Symlinks

All tools read from this canonical file via symlinks. Do not edit the symlink targets directly.

<!-- markdownlint-disable MD013 -->
| File | Symlink target | Tool |
|---|---|---|
| `CLAUDE.md` | `AGENTS.md` | Claude Code |
| `.cursor/rules` | `../AGENTS.md` | Cursor |
| `.github/copilot-instructions.md` | `../../AGENTS.md` | GitHub Copilot |
| `.windsurfrules` | `AGENTS.md` | Windsurf |
<!-- markdownlint-enable MD013 -->

```bash
# Run once after cloning to wire up all symlinks
ln -sf AGENTS.md CLAUDE.md
mkdir -p .cursor && ln -sf ../AGENTS.md .cursor/rules
mkdir -p .github && ln -sf ../../AGENTS.md .github/copilot-instructions.md
ln -sf AGENTS.md .windsurfrules
```
