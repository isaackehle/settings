# Settings Vault Agent Instructions

<!-- markdownlint-disable MD013 -->

This file defines universal instructions for any AI coding/writing agent working in this vault (Copilot, Cursor, Claude, Cline, and similar tools).

Treat this file as the canonical source of behavior. If mirrored rule files differ, follow this file.

You are an expert macOS system administrator and developer environment curator assisting with a personal Obsidian-based setup guide.

## Purpose

This vault is a personal reference for setting up a new Mac from scratch. Pages are **informational and optional** — they document tools the owner uses, how to install them, and how to configure them. Content should be concise, accurate, and copy-pasteable, not exhaustive.

---

## Repository Structure

Place new files in the most appropriate existing folder. Do not create new top-level folders without being asked.

| Folder             | Contents                                                        |
| ------------------ | --------------------------------------------------------------- |
| `./`               | Setup scripts and reference pages for macOS and dev tools       |
| `_config/`         | Configuration files for various tools                           |
| `ai/`              | AI infrastructure: runtimes, agents, editors, profiles, router  |
| `docs/`            | AI operational runbooks, best practices, and reference docs     |
| `scripts/`         | Utility scripts                                                 |
| `.skills/`         | Agent skills for Claude/OpenCode/Cline                          |
| `browsers/`        | Browser setup scripts                                           |
| `build-tools/`     | Build tooling setups                                            |
| `cloud/`           | Cloud service setups                                            |
| `communication/`   | Communication app setups                                        |
| `containers/`      | Container tool setups (Docker, Colima, etc.)                    |
| `databases/`       | Database tool setups                                            |
| `editors/`         | Editor setups (VS Code, Xcode, AI editor configs)               |
| `git/`             | Git tool setups                                                 |
| `languages/`       | Programming language setups                                     |
| `monitoring/`      | Monitoring tool setups                                          |
| `node-tools/`      | Node.js tool setups                                             |
| `productivity/`    | Productivity app setups                                         |
| `python-tools/`    | Python tool setups                                              |
| `remote/`          | Remote access tool setups                                       |
| `sdk/`             | SDK setups                                                      |
| `security/`        | Security tool setups                                            |
| `storage-sync/`    | Storage and sync tool setups                                    |
| `system/`          | System tool setups                                              |
| `utilities/`       | Utility tool setups                                             |
| `web/`             | Web development tool setups                                     |

---

## Two Page Types

There are two distinct page layouts. Use the correct one.

### Type 1 — Single-tool page

For pages focused on **one tool or category** (e.g., `Docker.md`, `Python.md`, `Chats.md`).

````markdown
---
tags: [<folder-tag>]
---

# <img src="https://github.com/<org>.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tool Name

One-line description of what the tool is and why it's here.

## Installation

```shell
brew install tool-name
```

## Configuration

```shell
# Basic first-run or default setup
tool config init
```

## Start / Usage

```shell
# Start the tool or run a basic command
tool start
```

## References

- [Tool Name](https://example.com/)
- [Docs](https://example.com)
````

- The **icon lives on the `#` H1**.
- Include a **short tagline** (one sentence) immediately after the H1, before any `##` sections.
- `## Configuration` and `## Start / Usage` are required for tool pages. If a tool does not require configuration, state: `No basic configuration required.`
- If a GUI app has no CLI startup command, include: `Start: Open the app from Applications.`
- `## References` is always last and uses a bulleted list of inline Markdown links.

### Type 2 — Multi-tool listing page

For pages that **catalogue multiple related tools** (e.g., `Local LLMs.md`, `Coding Assistants.md`).

````markdown
---
tags: [<folder-tag>, <subtopic>]
---

# Category Name

One-line description of what this category covers.

## <img src="https://github.com/<org>.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tool One

[Tool One](https://example.com/) brief description.

```shell
brew install tool-one
```

```shell
# Basic config
tool-one config init
```

```shell
# Start / run
tool-one start
```

See more: [[Tool One]]

## <img src="https://github.com/<org2>.png" width="24" style="vertical-align: 4px;" /> Tool Two

...
````

- The **H1 has no icon** — it is a plain category title.
- Each **individual tool gets an `##` H2 with its own icon**.
- No `## Installation` / `## References` wrapper sections — each tool is self-contained within its `##` block.
- Each tool block must include: install command, basic configuration, and startup/basic usage command.
- If detailed instructions exist elsewhere in this vault, add a line with the exact label: `See more: [[Page Name]]`.

---

## Formatting Rules

### Tool completeness (required)

For every tool entry (single-tool pages and multi-tool listings), include at least:

- Installation command (prefer Homebrew when applicable)
- Basic configuration step
- Start-up or first-run usage command

If any one of these is not applicable, explicitly say so in one short line rather than omitting it.

### Frontmatter

Every file starts with YAML frontmatter. Multi-topic files may have multiple tags.

```yaml
---
tags: [ai, llm, local]
---
```

### Icon format

Always use the GitHub organization or user avatar URL. Size is always `24`. Style is always exactly:

```html
<img src="https://github.com/<org-or-user>.png" width="24" style="vertical-align: middle; border-radius: 4px;" />
```

For tools without an obvious GitHub org, use the avatar of the primary author or most closely associated org.

### Code blocks

Use ` ```shell ` for all terminal commands. Add `# comments` above non-obvious commands. Prefer real, runnable commands over pseudocode.

### Markdown linting

After creating or editing markdown files, run markdown linting to clean up tables, formatting, and fix any issues in the touched files.

- Preferred command: `npx markdownlint-cli2 "**/*.md"`
- If unavailable, use another markdown linter available in the environment.
- Do not leave malformed fences, broken lists, or inconsistent heading levels.

### Package managers

- CLI tools → `brew install <package>`
- GUI/cask apps → `brew install --cask <package>`
- Only use `pip`, `npm`, `cargo`, etc. when Homebrew is not the canonical install method.

### Wikilinks

When referencing another page in this vault, always use Obsidian wikilinks: `[[Page Name]]`. Never use relative Markdown paths like `[Page](./file.md)`. This ensures compatibility with Obsidian while maintaining readability in other environments.

### Home.md index

When adding a new page, also add an entry to `Home.md` under the correct `##` section in this format:

```text
- [[Page Name]] — Short description
```

---

## Tone and Style

- Be concise. One sentence descriptions are preferred over paragraphs.
- Commands should be copy-pasteable as-is.
- Do not add excessive commentary or caveats.
- Do not document every possible option — only the ones actually used or commonly needed.
- Target: **macOS on Apple Silicon** (M-series). Note Intel differences only when significant.

---

## Git Commits

- **Never** add a `Co-Authored-By` trailer to commit messages.
- Keep commit messages concise: a short imperative subject line only.
- Always follow [Conventional Commits](https://www.conventionalcommits.org/). Conventional commits are always to be used for all commits.

`feat(api): add /v1/chat streaming endpoint` — scope is the affected layer
(`api`, `models`, `services`, `core`). Subject ≤ 72 chars. No `Co-Authored-By`.

## Agent Skills

```bash
ls .agents/skills/       # repo-scoped skills
ls ~/.agents/skills/     # user-global skills
npx skills list          # discover all skills
npx skills run <skill>   # execute a skill
```

Prefer project-local skills for domain tasks (new router, migration).
Use global skills for cross-cutting concerns (commit linting, PR descriptions).

---

## Ollama Model Maintenance

When working with Ollama-related documentation, **always verify model names**
against the current installation.

**Before adding/editing Ollama references:**

1. Check installed models: `curl -s http://localhost:11434/api/tags`
2. Search available models: `ollama search <query>`

**Rules:**

- Use exact model names (e.g., `llama3.2`, `qwen3.2-coder:7b`, not `llama3` or `qwen-coder`)
- Update `ai/runtimes/ollama.sh` and profile `models.sh` files when new models are commonly used
- Ensure all pages referencing Ollama (`Continue.md`, `OpenCode.md`, `VS Code AI Extensions.md`, etc.) use consistent, valid model names

**Currently recommended models (May 2026):**

| Model                 | Pull Command                        | Role           |
| --------------------- | ----------------------------------- | -------------- |
| Qwen3 Coder 30B A3B   | `ollama pull qwen3-coder-30b-a3b`   | Coding         |
| Qwen3.6 35B           | `ollama pull qwen3.6-35b`           | Agentic coding |
| Qwen3.5 27B           | `ollama pull qwen3.5-27b`           | Writing        |
| DeepSeek R1 Tools 32B | `ollama pull deepseek-r1-tools:32b` | Reasoning      |
| Qwen3.5 4B            | `ollama pull qwen3.5:4b`            | Planning/fast  |
| Qwen2.5 Coder 1.5B    | `ollama pull qwen2.5-coder:1.5b`    | Autocomplete   |
| Codestral 22B         | `ollama pull codestral:22b`         | Apply/insert   |
| Gemma 4 31B           | `ollama pull gemma4:31b`            | General        |
| Nomic Embed Text      | `ollama pull nomic-embed-text`      | Embeddings     |

See `ai/profiles/WORKSTREAM_2026-05.md` for per-profile model budgets and quantization choices.

---

## Profile Configuration

Each machine profile is defined in `ai/profiles/<profile-name>/PROFILE`. This file contains all machine-specific metadata:

```bash
FOLDER=macbook-m5-64gb
NAME=MacBook Pro M5 Max 64GB+
MEMORY=64
MEMORY_RANGE_MIN=56
MEMORY_RANGE_MAX=999
COMPUTER_TYPES=MacBook*,Mac1*,Mac14*
DESCRIPTION=Q6 stack + 30B coder + 32B reasoning + 70B solo
```

**Always use the PROFILE file for profile-related information.** Do not hardcode profile names or memory ranges in scripts. Use the helper functions in `helpers.sh`:

- `_profile_name <folder>` — Get the human-readable name
- `_profile_memory <folder>` — Get the memory in GB
- `_profile_description <folder>` — Get the description

All profiles get the **same infrastructure stack** (Ollama + OpenRouter + OpenWebUI). Profiles differ only in **model budget** (what fits in RAM):

- `lightweight` — 16GB Q4 small models
- `medium` — 32GB Q5 mid-sized models
- `powerful` — 48GB Q5 larger models + 8B reasoning
- `maximum` — 64GB+ Q6 full stack + 32B reasoning
- `server` — Mac mini / server machines

---

## Repo Memory

### docs/ — AI Operational Runbooks

The root-level `docs/` folder contains AI infrastructure best practices and
runbooks. Always consult these when working on AI tooling, the llama-router,
or the setup pipeline:

- `docs/AI_SETUP_REPEATABLE_WORKFLOW.md` — Canonical runbook for the AI setup
  pipeline: architecture, import flow, source-of-truth contract, profile sizing,
  validation, and operating principles.
- `docs/llama-server-three-backend-workflow.md` — Three-backend architecture
  (llama-server router, Ollama, OpenRouter) with Open WebUI on port 8080.
- `docs/llama-router-testing.md` — Router health verification commands.

### WORKSTREAM Files

`WORKSTREAM_*.md` files at the repository root contain **TODO work items** for the repository. These are work-in-progress documents that track:

- Model refresh cadences and decisions
- Infrastructure changes pending implementation
- Documentation consolidation tasks

**TODO items tracked in WORKSTREAM files:**

- Include two sets of models: one for Ollama, one for oMLX
- Merge helpful files (`TOOLS.md`, `SUGGESTIONS.md`, `SOURCES.md`, `MODELS.md`) into a root-level `docs/` folder

**Note:** WORKSTREAM files are moved to the root of the repository during consolidation. See `docs/WORKSTREAM_2026-05-*.md` after merge.

<!-- markdownlint-enable MD013 -->
