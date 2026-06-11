# Agent Memory & Global Instructions Setup

How to configure every AI tool on this machine to share a single canonical source of truth for identity, vault routing, people conventions, and commit style.

---

## Overview

All AI agents (Claude Code, opencode, kilo, crush, aider, Gemini CLI, continue, and future tools) are wired to read from a single file:

**`~/.agents.md`** — canonical global instructions

Supporting files:

| File | Purpose |
|---|---|
| `~/.agents.md` | Canonical source of truth — all agents read this |
| `~/.vaults.md` | Vault registry (paths, variables, planned renames) |
| `~/.memory.md` | Persistent cross-session context and change log |
| `~/.claude/CLAUDE.md` | Claude Code auto-loaded global instructions (delegates to `~/.agents.md`) |

---

## Step 1 — Create `~/.agents.md`

```markdown
# Global Agent Instructions

This is the canonical source of truth for all AI agents operating on Isaac's machines.

## Tool Registry
...

## Identity
- **Owner:** Isaac Kehle
- **Location:** Baltimore, MD (ZIP 21117, Owings Mills area)

## People
Names that are always lowercase:
- **ravyn**
- **amethyst**

## Vault Registry
See `~/.vaults.md` for the full vault registry and planned renames.

| Variable          | Path                                                         | Purpose                     |
| ----------------- | ------------------------------------------------------------ | --------------------------- |
| `$OBSIDIAN_VAULT` | `~/Library/CloudStorage/OneDrive-Personal/vault`             | Job search & career         |
| `$PERSONAL_VAULT` | `~/Library/CloudStorage/OneDrive-Personal/Documents`         | Personal life, home, DIY    |

## Job Search Routing
All job search, resume, and career output → `$OBSIDIAN_VAULT/job_search/`
Use absolute paths. Do not write to the current working directory.

## Personal Vault Routing
Personal life content → `$PERSONAL_VAULT`. See `$PERSONAL_VAULT/AGENTS.md` for routing rules.

## Commit Message Style
Format: `type(scope): short description` (≤72 chars, imperative mood, no period)
Types: feat, fix, docs, style, refactor, test, chore, ci, perf, build
Output ONLY the raw string — no JSON, no markdown, no wrapping.
```

---

## Step 2 — Create `~/.vaults.md`

```markdown
# Isaac's Vaults

| Variable          | Path                                                                | Purpose                                      |
| ----------------- | ------------------------------------------------------------------- | -------------------------------------------- |
| `$OBSIDIAN_VAULT`   | `~/Library/CloudStorage/OneDrive-Personal/vault`                  | Job search & career (future: `$JOB_VAULT`)   |
| `$PERSONAL_VAULT`   | `~/Library/CloudStorage/OneDrive-Personal/Documents`              | Personal life — home, DIY, finances, health  |
```

---

## Step 3 — Create `~/.memory.md`

```markdown
# Global Memory

Persistent cross-session context for Isaac Kehle.
For canonical global instructions, vault registry, and conventions, see `~/.agents.md`.

## People
- **ravyn** — always lowercase
- **amethyst** — always lowercase

## Change Log
...
```

---

## Step 4 — Wire each tool

### Claude Code — `~/.claude/CLAUDE.md`

Auto-loaded by Claude Code in every session regardless of working directory.

```markdown
# Global Instructions

See `~/.agents.md` for the canonical source of truth for all global context, vault registry, routing rules, people, and conventions.

See `~/.memory.md` for persistent cross-session context (people, preferences, conventions).
```

### opencode — `~/.config/opencode/opencode.jsonc`

Add to the config:

```jsonc
"instructions": ["~/.agents.md"]
```

### kilo — `~/.kilo/agents/*.md`

Inject after the closing `---` of the frontmatter in every agent file:

```markdown
See `~/.agents.md` for global context, vault routing, people conventions, and commit message style.
```

Quick script to apply to all agents at once:

```bash
for f in ~/.kilo/agents/*.md; do
  python3 -c "
import sys
content = open('$f').read()
parts = content.split('---', 2)
if len(parts) >= 3:
    new = parts[0] + '---' + parts[1] + '---\n\nSee \`~/.agents.md\` for global context, vault routing, people conventions, and commit message style.\n' + parts[2]
    open('$f', 'w').write(new)
    print('updated: $f')
"
done
```

### crush — `~/.crush/config.json`

Add to the JSON object:

```json
"instructions": ["~/.agents.md"]
```

### aider — `~/.aider.conf.yml`

Add a `read-only` entry so `~/.agents.md` is loaded as context in every session:

```yaml
## ── Global instructions ────────────────────────────────────────────────────
read-only: ~/.agents.md
```

### Gemini CLI — `~/.gemini/GEMINI.md`

Replace the placeholder content:

```markdown
# Rules Pointer

This file intentionally delegates to the canonical agent instructions in `~/.agents.md`.

Use `~/.agents.md` for all behavior, vault routing, people conventions, and global context.
If any instruction conflicts, `~/.agents.md` wins.
```

### continue — `~/.continue/config.yaml`

Add a `systemMessage` near the top of the config:

```yaml
systemMessage: "See ~/.agents.md for global context: vault registry, routing rules, people conventions (ravyn and amethyst are always lowercase), and commit message style."
```

### Windsurf

No global instruction mechanism. Use per-project `.windsurfrules` when needed.

### Devin editor

Not yet installed. When set up: find where it loads global instructions and add a pointer to `~/.agents.md`. Update this doc and `~/.agents.md` tool registry when done.

---

## Step 5 — Wire vault-level AGENTS.md files

Each Obsidian vault should have an `AGENTS.md` at its root that:
1. References `~/.agents.md` for global context
2. Defines vault-specific identity, structure, and routing rules
3. Points to `VAULT_STRUCTURE.md` for the folder map
4. Points to `memory/MEMORY.md` for vault-local persistent context

See `$PERSONAL_VAULT/AGENTS.md` as the reference implementation.

---

## Step 6 — Add shell env vars

Add to `~/.zshrc`:

```zsh
export OBSIDIAN_VAULT="$HOME/Library/CloudStorage/OneDrive-Personal/vault"
export PERSONAL_VAULT="$HOME/Library/CloudStorage/OneDrive-Personal/Documents"
# Future:
# export JOB_VAULT="$HOME/Library/CloudStorage/OneDrive-Personal/job_vault"
```

---

## Planned Changes

- Rename `$OBSIDIAN_VAULT` → `$JOB_VAULT` and move folder to `job_vault/` once job search vault is fully split
- Add `$PERSONAL_VAULT` to `~/.zshrc` if not already set
- Wire Devin editor when installed

---

## Verification

After setup, confirm each tool picks up global context:

```bash
# Check files exist
ls ~/.agents.md ~/.vaults.md ~/.memory.md ~/.claude/CLAUDE.md

# Check opencode has instructions set
grep "instructions" ~/.config/opencode/opencode.jsonc

# Check kilo agents have agents.md reference
grep "agents.md" ~/.kilo/agents/code.md

# Check aider has read-only set
grep "read-only" ~/.aider.conf.yml

# Check crush has instructions set
grep "instructions" ~/.crush/config.json

# Check continue has systemMessage
grep "systemMessage" ~/.continue/config.yaml
```
