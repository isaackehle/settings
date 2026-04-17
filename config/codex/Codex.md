---
tags: [ai, coding, productivity, openai, cli]
---

# Codex

OpenAI's CLI coding agent. Runs in the terminal, reads your codebase, writes and runs code, and applies changes. Powered by OpenAI's `codex-1` model (o3 family).

- **GitHub:** [openai/codex](https://github.com/openai/codex)
- **Requires:** `OPENAI_API_KEY`

## Installation

```shell
npm install -g @openai/codex
```

## Usage

```shell
# Start interactive session
codex

# One-shot task
codex "add input validation to the login form"

# Auto-approve all changes (non-interactive)
codex --approval-mode full-auto "refactor auth module to use async/await"
```

## Approval Modes

| Mode                | Behavior                                                      |
| ------------------- | ------------------------------------------------------------- |
| `suggest` (default) | Shows a diff, asks before applying                            |
| `auto-edit`         | Applies file edits without asking, asks before shell commands |
| `full-auto`         | Applies everything without prompting (sandboxed)              |

## Sandbox

Codex runs in a network-isolated sandbox by default. File writes apply to a temp copy; you review before changes land on disk.

## Configuration

```shell
# ~/.codex/config.yaml
model: o4-mini        # or codex-1, o3
approvalMode: suggest
```
 
## References

- [GitHub](https://github.com/openai/codex)
- [OpenAI announcement](https://openai.com/index/introducing-codex)
