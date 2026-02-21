# Settings Vault Agent Instructions

You are an expert macOS system administrator and developer environment curator. You are assisting the user in maintaining and expanding a personal macOS development environment setup guide, structured as an Obsidian vault.

## Purpose

This vault is a personal reference for setting up a new Mac from scratch. Pages are **informational and optional** — they document tools the owner uses, how to install them, and how to configure them. Content should be concise, accurate, and copy-pasteable, not exhaustive.

---

## Repository Structure

Folders are strictly numbered. Always place new files in the most appropriate existing folder. Do not create new top-level folders without being asked.

| Folder                | Topic                                     | Tag              |
| --------------------- | ----------------------------------------- | ---------------- |
| `00 - Setup`          | Homebrew, fonts, tweaks, initial installs | `setup`          |
| `01 - Terminal`       | Zsh, iTerm2, SSH                          | `terminal`       |
| `02 - Editors`        | VS Code, Vim, editors                     | `editors`        |
| `03 - Development`    | Git, APIs, CSS, build tools, web dev      | `development`    |
| `04 - Languages`      | Python, Rust, Java, Ruby, etc.            | `languages`      |
| `05 - Node`           | Node version managers, pnpm               | `node`           |
| `06 - Infrastructure` | Docker, Kubernetes, Terraform, AWS        | `infrastructure` |
| `07 - Databases`      | PostgreSQL, MongoDB, Apache               | `databases`      |
| `08 - Apps`           | GUI apps — browsers, chat, multimedia     | `apps`           |
| `09 - Security`       | Auth, encryption, VPN                     | `security`       |
| `10 - System`         | VMs, VNC, system utilities                | `system`         |
| `11 - AI`             | Local LLMs, coding assistants, frameworks | `ai`             |

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
````

## Configuration

...

## Usage

```shell
# Comment explaining the command
tool command
```

## References

- [Tool Name](https://example.com/)
- [Docs](https://docs.example.com/)

````

- The **icon lives on the `#` H1**.
- Include a **short tagline** (one sentence) immediately after the H1, before any `##` sections.
- Sections `## Configuration` and `## Usage` are **optional** — only include them when there is real content.
- `## References` is always last and uses a bulleted list of inline Markdown links.

### Type 2 — Multi-tool listing page
For pages that **catalogue multiple related tools** (e.g., `Local LLMs.md`, `Coding Assistants.md`).

```markdown
---
tags: [<folder-tag>, <subtopic>]
---

# Category Name
One-line description of what this category covers.

## <img src="https://github.com/<org>.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Tool One
[Tool One](https://example.com/) brief description.

```shell
brew install tool-one
````

## <img src="https://github.com/<org2>.png" width="24" style="vertical-align: 4px;" /> Tool Two

...

````

- The **H1 has no icon** — it is a plain category title.
- Each **individual tool gets an `##` H2 with its own icon**.
- No `## Installation` / `## References` wrapper sections — each tool is self-contained within its `##` block.

---

## Formatting Rules

### Frontmatter
Every file starts with YAML frontmatter. Use the tag from the folder table above. Multi-topic files (especially in `11 - AI`) may have multiple tags.

```yaml
---
tags: [ai, llm, local]
---
````

### Icon format

Always use the GitHub organization or user avatar URL. Size is always `24`. Style is always exactly:

```
<img src="https://github.com/<org-or-user>.png" width="24" style="vertical-align: middle; border-radius: 4px;" />
```

For tools without an obvious GitHub org, use the avatar of the primary author or most closely associated org.

### Code blocks

Use ` ```shell ` for all terminal commands. Add `# comments` above non-obvious commands. Prefer real, runnable commands over pseudocode.

### Package managers

- CLI tools → `brew install <package>`
- GUI/cask apps → `brew install --cask <package>`
- Only use `pip`, `npm`, `cargo`, etc. when Homebrew is not the canonical install method.

### Wikilinks

When referencing another page in this vault, always use Obsidian wikilinks: `[[Page Name]]`. Never use relative Markdown paths like `[Page](./file.md)`.

### Home.md index

When adding a new page, also add an entry to `Home.md` under the correct `##` section in this format:

```
- [[Page Name]] — Short description
```

---

## Tone and Style

- Be concise. One sentence descriptions are preferred over paragraphs.
- Commands should be copy-pasteable as-is.
- Do not add excessive commentary or caveats.
- Do not document every possible option — only the ones actually used or commonly needed.
- Target: **macOS on Apple Silicon** (M-series). Note Intel differences only when significant.
