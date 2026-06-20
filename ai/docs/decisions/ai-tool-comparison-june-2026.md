---
tags: [ai, tools, review, reference]
---

# AI Tool Comparison — June 2026

Personal evaluation of every AI coding/agent tool in this stack.
Goal: identify what's worth maintaining, what's redundant, what to drop.

---

## The Short Version

**Keep and use actively:** OpenCode, Hermes, Crush, Aider, Continue, Kilo Code  
**Keep but don't maintain:** Zed (if you use it as an editor), aichat (quick shell queries)  
**Drop or stop maintaining:** Cline (replaced by Kilo), Zoo Code (broken + stale), Gemini CLI, Grok CLI, Cursor (cloud-first, expensive)

---

## Tier 1 — Core tools (worth deep investment)

### OpenCode

**What it is:** Multi-agent CLI coding assistant with a rich agent system, MCP support,
and OpenRouter integration.

**Strengths:**
- Multi-agent architecture — code, think, research, write, plan, build agents each optimized
  for a different job, running whatever model fits
- Fastest iteration loop for in-codebase work; reads files, runs tests, edits, commits
- Fully local-first: all agents route to Ollama by default, OpenRouter is opt-in per agent
- Most actively maintained tool in this category (daily releases)

**Weaknesses:**
- No persistent memory between sessions — context resets every time
- Agent switching is manual; users need to understand which agent fits which task
- `maxTokens` defaults can truncate output (fixed in this profile)

**When to use:** In-codebase work — feature implementation, refactoring, debugging,
test writing. Default choice for anything touching actual project files.

**Rating: ★★★★★** — Primary tool. Most investment justified.

---

### Hermes Agent

**What it is:** Full autonomous agent framework with persistent memory, sessions,
hooks, sandboxes, delegation, and multi-platform support (CLI, Slack, Discord, etc.)

**Strengths:**
- **Persistent memory** — knows your garage project, your preferences, prior decisions
  across every session. No re-explaining context.
- Long-horizon tasks: can run 60-turn sessions, manage sub-agents, pick up where it left off
- Built-in **fallback_providers** — local-first with cloud failover (the only tool here
  that does this natively)
- Hooks, cron, kanban — can be scheduled, automated, wired into platforms
- Compression + context management prevents context window exhaustion automatically
- Multi-modal: browser, TTS/STT, vision

**Weaknesses:**
- Currently 1461 commits behind — needs `hermes update` before serious use
- Slower startup than OpenCode for quick tasks
- More complex to configure correctly

**When to use:** Long-running multi-session projects (garage/cabinet planning), tasks
that require memory of prior work, anything that spans research → design → execution
over multiple days.

**Rating: ★★★★★** — Unique capabilities. Underutilised. Run `hermes update`.

---

### Crush

**What it is:** Charm Industries' terminal AI assistant — essentially a polished
terminal wrapper around Claude/Ollama with a strong focus on CLI UX.

**Strengths:**
- Best terminal UX in the group: syntax highlighting, diffing, clean output
- Fast and lightweight — no warmup, no server
- Works identically with local Ollama and cloud providers
- Excellent for quick focused tasks without the overhead of a full agent session

**Weaknesses:**
- No memory, no sessions
- Single-model per invocation (no agent routing)
- Less capable for multi-file refactoring than OpenCode

**When to use:** Quick questions, one-shot edits, pipe output through for analysis,
git commit messages, quick explanations. The `hermes` of throwaway tasks.

**Rating: ★★★★☆** — Low maintenance, high value for quick work.

---

### Aider

**What it is:** CLI git-aware coding assistant that edits files via structured diffs.

**Strengths:**
- Most reliable multi-file editor in the group — uses structured diff formats that
  don't corrupt files
- Git-native: automatically commits each change with meaningful messages
- `--architect` mode separates reasoning (big model) from editing (Codestral) —
  efficient and accurate
- Works offline, no server, simple config

**Weaknesses:**
- Slower iteration loop than OpenCode (more round-trips for diffs)
- Less capable for exploratory/agentic tasks
- No web access, no tool calling

**When to use:** Precise multi-file refactoring where you want clean git history.
Large-scale renames, API migrations, test generation across a codebase.

**Rating: ★★★★☆** — Complementary to OpenCode, not redundant. Keep.

---

## Tier 2 — VS Code extensions (keep, low maintenance)

### Continue

**What it is:** VS Code extension for autocomplete + inline chat + multi-model routing.

**Strengths:**
- Best-in-class autocomplete via `qwen2.5-coder:1.5b` (fast, FIM-trained)
- Chat and edit roles work alongside autocomplete from one extension
- Clean separation of roles per model (apply = Codestral, embed = nomic)

**Weaknesses:**
- Not an agent — no multi-step tool execution
- Chat quality depends on model; 30B local model is slower than cloud

**When to use:** Leave it running in VS Code at all times. It does autocomplete
silently; only switch to a chat agent if you need multi-step work.

**Rating: ★★★★☆** — Set and forget. Minimal maintenance.

---

### Kilo Code

**What it is:** VS Code agent extension (Cline/Roo architecture) with multi-agent
support, per-agent model routing, and good MCP integration.

**Strengths:**
- Best VS Code agent extension currently — more actively maintained than Cline/Zoo
- Per-agent model routing: architect → `qwen2.5:32b`, debug → `deepseek-r1-tools:32b`
- MCP integration (GitHub, git) works reliably
- All agents now correctly configured (fixed today)

**Weaknesses:**
- Requires VS Code (not terminal-native)
- Duplicates some OpenCode capability if you're terminal-first

**When to use:** When you want agent capabilities without leaving the editor.
Particularly good for code review, architecture discussions while viewing code.

**Rating: ★★★★☆** — Best VS Code agent. Keep.

---

## Tier 3 — Redundant or diminishing returns

### Cline

**What it is:** The original VS Code agentic extension — the upstream of Kilo Code
and Roo Code.

**Verdict:** If you're using Kilo Code, Cline is redundant. Kilo is a maintained fork
with more features. The only reason to keep Cline is if a specific Cline-only feature
is needed — unlikely.

**Recommended action:** Stop maintaining. Remove config from profile. Uninstall
VS Code extension when convenient.

**Rating: ★★☆☆☆** — Superseded by Kilo Code.

---

### Zoo Code

**What it is:** Another Cline fork (Zoo Veterinary) with per-mode model selection.

**Problems found today:**
- `architect` mode was pointing to `gemma4:31b` (cloud-only manifest, no local weights)
  — silently broken for months
- Less actively maintained than Kilo

**Recommended action:** Drop. Config has been patched (`qwen2.5:32b` now) but the
maintenance overhead for a third Cline fork is not worth it.

**Rating: ★★☆☆☆** — Drop. Use Kilo instead.

---

### Cursor

**What it is:** AI-first code editor with strong cloud model integration.

**Why it underdelivers for this stack:**
- Subscription-based; local model setup is manual and unofficial
- References `gemma4:31b` (cloud-only) — was silently broken in profile
- Cloud-first philosophy conflicts with local-first goals
- Cursor's core value (fast autocomplete, inline generation) is covered by Continue +
  OpenCode in VS Code

**When it makes sense:** If you're doing paid cloud-first work and want the native
Cursor experience. Not for local-first AI development.

**Recommended action:** Stop maintaining the local config. Keep it installed for
occasional cloud use if needed. Remove from active profile maintenance.

**Rating: ★★★☆☆** — Good editor, wrong fit for this stack.

---

## Tier 4 — Drop

### Gemini CLI

**What it is:** Google's official Gemini command-line tool.

**Why it doesn't fit:**
- Cloud-only — no local model support
- Gemini 2.5 Pro/Flash are available via OpenRouter with better routing
- Duplicates what OpenCode + OpenRouter already does, without the agent framework

**Recommended action:** Stop installing/maintaining. Access Gemini via OpenRouter
in OpenCode/Hermes where needed.

**Rating: ★★☆☆☆** — Redundant. Drop.

---

### Grok CLI

**What it is:** xAI's command-line interface for Grok models.

**Why it doesn't fit:**
- Cloud-only
- Grok 3 is available via OpenRouter
- No advantage over `openrouter/x-ai/grok-3` in OpenCode

**Recommended action:** Same as Gemini — access via OpenRouter. Stop maintaining
the dedicated CLI.

**Rating: ★★☆☆☆** — Redundant. Drop.

---

## Tier 5 — Edge cases (keep for specific workflows)

### Zed

**What it is:** Fast, native macOS code editor with built-in AI assistant.

**When it earns its place:**
- Fastest editor for large file navigation
- AI assistant + inline completion work well for quick reads/edits
- Profile updated to use `qwen3-coder-30b-a3b:q6` and `qwen2.5:32b` locally

**Recommended action:** Keep if you use Zed as an occasional editor. Low maintenance.

**Rating: ★★★☆☆** — Situational. Keep but don't over-invest.

---

### aichat

**What it is:** Rust-based terminal AI chat with roles, sessions, and RAG.

**Niche value:**
- Fastest CLI chat tool (compiled binary, no startup overhead)
- Good for `cat file | aichat "explain this"`
- Supports local Ollama and most cloud providers

**Recommended action:** Keep as a lightweight piping tool. No active maintenance needed.

**Rating: ★★★☆☆** — Useful utility, minimal maintenance.

---

## Summary Matrix

| Tool | Type | Local-first | Memory | Multi-agent | Keep? |
| --- | --- | :---: | :---: | :---: | :---: |
| OpenCode | CLI agent | ✅ | ❌ | ✅ | ✅ Primary |
| Hermes | Full agent | ✅ (after config) | ✅ | ✅ | ✅ Primary |
| Crush | CLI assistant | ✅ | ❌ | ❌ | ✅ |
| Aider | CLI editor | ✅ | ❌ | ❌ | ✅ |
| Continue | VS Code ext | ✅ | ❌ | ❌ | ✅ |
| Kilo Code | VS Code agent | ✅ | ❌ | ✅ | ✅ |
| Cline | VS Code agent | ✅ | ❌ | ❌ | ❌ Drop |
| Zoo Code | VS Code agent | ✅ | ❌ | ❌ | ❌ Drop |
| Cursor | AI editor | ❌ | ❌ | ❌ | ⚠️ Reduce |
| Zed | Editor + AI | ✅ | ❌ | ❌ | ⚠️ Situational |
| aichat | CLI chat | ✅ | ❌ | ❌ | ⚠️ Situational |
| Gemini CLI | CLI chat | ❌ | ❌ | ❌ | ❌ Drop |
| Grok CLI | CLI chat | ❌ | ❌ | ❌ | ❌ Drop |

---

_Generated: 2026-06-11_  
_Profile: macbook-m5-64gb_
