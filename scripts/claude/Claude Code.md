---
tags: [ai, llm, coding, productivity, claude, ollama, local]
---

# Claude Code

Anthropic's agentic coding CLI. Reads, writes, and runs code in your terminal.

## Installation

curl is the only supported install method. If previously installed via npm or Homebrew, uninstall first:

```shell
npm uninstall -g @anthropic-ai/claude-code
brew uninstall claude 2>/dev/null || brew uninstall claude-code 2>/dev/null || true
```

Then install:

```shell
curl -fsSL https://claude.ai/install.sh | bash
```

## Local Models via Ollama

`config.json` in this directory routes Claude Code to a local Ollama instance. All three model tiers map to local Qwen3-Coder aliases.

Deployed to `~/.claude/config.json` by `setup_claude.sh`.

### Environment Variables

| Variable                         | Value                    | Purpose                           |
| -------------------------------- | ------------------------ | --------------------------------- |
| `ANTHROPIC_BASE_URL`             | `http://localhost:11434` | Route requests to local Ollama    |
| `ANTHROPIC_AUTH_TOKEN`           | `ollama`                 | Dummy token (Ollama doesn't auth) |
| `ANTHROPIC_API_KEY`              | `ollama`                 | Duplicate for SDK compatibility   |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `qwen3.6-35b-32k:q5`     | Maps Sonnet tier → local model    |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL`  | `qwen3-4b:q8`            | Maps Haiku tier → local model     |
| `ANTHROPIC_DEFAULT_OPUS_MODEL`   | `qwen3.6-35b-220k:q5`    | Maps Opus tier → local model      |

### Model Aliases

The model names are Ollama Modelfile aliases:

```shell
ollama list

# Create alias via Modelfile
cat > /tmp/Modelfile << 'EOF'
FROM qwen2.5-coder:32b-instruct-q4_K_M
PARAMETER num_ctx 32768
EOF
ollama create qwen3.6-35b-32k:q5 -f /tmp/Modelfile
```

### Permissions

Pre-approves read-only git commands to avoid prompts on every `git log`:

```json
"permissions": {
  "allow": ["Bash(git log:*)", "Bash(git diff:*)", "Bash(git status:*)", "Bash(git show:*)", "Bash(git blame:*)"]
}
```

## References

- [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code)
- [Ollama](https://ollama.com)
