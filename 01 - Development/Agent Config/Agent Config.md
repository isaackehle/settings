---
tags: [development, ai, agents]
---

# Agent Config

AGENTS.md templates for bootstrapping AI agent instructions in new repositories.

The `AGENTS.md` standard provides a single, canonical configuration file that governs AI coding agent behavior across a repository. Adopted by 60,000+ projects under the Linux Foundation's Agentic AI Foundation, it is supported by Claude Code, Codex, Cursor, Copilot, Cline, Gemini CLI, and OpenCode. One file replaces scattered tool-specific configs — symlink it to each tool's expected path and every agent reads the same rules.

## Monorepo Root

Root-level template for multi-stack repos. Covers cross-cutting rules and progressive disclosure to subdirectory configs.

See more: [[AGENTS.md Monorepo Root]]

## Next.js + TypeScript Frontend

Frontend template for Next.js 15 / React 19 / TypeScript projects.

See more: [[AGENTS.md Next.js TypeScript]]

## Python + FastAPI Backend

Backend template for Python / FastAPI / Pydantic projects with LLM integration.

See more: [[AGENTS.md Python FastAPI]]

## Embedded / Edge ML

Template for embedded systems and edge ML projects (Raspberry Pi, Arduino, TFLite).

See more: [[AGENTS.md Embedded Edge ML]]

## Usage

1. Copy the relevant template to your repo root as `AGENTS.md`.
2. Fill in the placeholder sections (Purpose, Project Structure, Non-Obvious Patterns).
3. Optionally symlink for tool-specific files:

```shell
ln -sf AGENTS.md CLAUDE.md
mkdir -p .cursor && ln -sf ../AGENTS.md .cursor/rules
mkdir -p .github && ln -sf ../../AGENTS.md .github/copilot-instructions.md
ln -sf AGENTS.md .windsurfrules
```

## Skills CLI

```shell
npx skills find <query>
npx skills add <owner/repo@skill-name>
```
