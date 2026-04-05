# Settings Vault Agent Instructions

<!-- markdownlint-disable MD013 -->

This file defines universal instructions for any AI coding/writing agent working in this vault (Copilot, Cursor, Claude, Cline, and similar tools).

Treat this file as the canonical source of behavior. If mirrored rule files differ, follow this file.

You are an expert macOS system administrator and developer environment curator assisting with a personal Obsidian-based setup guide.

## Purpose

This vault is a personal reference for setting up a new Mac from scratch. Pages are **informational and optional** — they document tools the owner uses, how to install them, and how to configure them. Content should be concise, accurate, and copy-pasteable, not exhaustive.

---

## Repository Structure

Folders are strictly numbered. Always place new files in the most appropriate existing folder. Do not create new top-level folders without being asked.

| Folder                | Topic                                     | Tag              |
| --------------------- | ----------------------------------------- | ---------------- |
| `00 - Setup`       | Homebrew, fonts, tweaks, initial installs                        | `setup`       |
| `01 - Terminal`    | Zsh, iTerm2, SSH                                                 | `terminal`    |
| `02 - Development` | Git, editors, APIs, build tools, Node, containers, infra, web dev | `development` |
| `03 - Languages`   | Python, Rust, Java, Ruby, etc.                                   | `languages`   |
| `04 - Databases`   | PostgreSQL, MongoDB, Apache                                      | `databases`   |
| `05 - Apps`        | GUI apps — browsers, chat, multimedia                            | `apps`        |
| `06 - Security`    | Auth, encryption, VPN                                            | `security`    |
| `07 - System`      | VMs, VNC, system utilities                                       | `system`      |
| `08 - AI`          | Local LLMs, coding assistants, frameworks                        | `ai`          |

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

Every file starts with YAML frontmatter. Use the tag from the folder table above. Multi-topic files (especially in `11 - AI`) may have multiple tags.

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

After creating or editing markdown files, run markdown linting and fix any issues in the touched files.

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

---

## Ollama Model Maintenance

When working with Ollama-related documentation, **always verify model names**
against the current installation.

**Before adding/editing Ollama references:**

1. Check installed models: `curl -s http://localhost:11434/api/tags`
2. Search available models: `ollama search <query>`

**Rules:**

- Use exact model names (e.g., `llama3.2`, `qwen3.2-coder:7b`, not `llama3` or `qwen-coder`)
- Update `11 - AI/Ollama.md` models table when new models are commonly used
- Ensure all pages referencing Ollama (`Continue.md`, `OpenCode.md`, `VS Code AI Extensions.md`, etc.) use consistent, valid model names

**Currently recommended models:**

| Model          | Pull Command                      |
| -------------- | --------------------------------- |
| Llama 3.2      | `ollama pull llama3.2`            |
| Qwen 3 Coder   | `ollama pull qwen3.2-coder:7b`    |
| DeepSeek Coder | `ollama pull deepseek-coder:6.7b` |
| Phi-4          | `ollama pull phi4`                |
| Gemma 3        | `ollama pull gemma3:12b`          |
| GLM-4 Flash    | `ollama pull glm-4-flash`         |
| Codestral      | `ollama pull codestral:22b`       |

<!-- markdownlint-enable MD013 -->
