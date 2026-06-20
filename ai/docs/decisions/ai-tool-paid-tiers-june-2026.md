---
tags: [ai, tools, pricing, reference]
---

# AI Tool Pricing & Paid Tiers — June 2026

Which tools in this stack cost money, what you get, and whether it's worth it
for a local-first setup.

---

## VS Code Extensions

### Kilo Code (`kilocode.kilo-code`) — **Freemium**

- **Free:** 300 cloud-routed messages/month via Kilo's gateway
- **Pro:** $15/month for unlimited cloud routing
- **Local models:** ✅ **Always free** — when pointed at Ollama (`:11434`),
  no messages are counted and no subscription is needed
- **Verdict for this stack:** Keep on free tier. All agents use local Ollama.
  The 300 free cloud messages are a bonus for occasional OpenRouter use.

### Continue (`continue.continue`) — **Free**

- The extension itself is free and open source
- Cost comes from API usage: OpenRouter models bill per token
- Local Ollama usage: ✅ completely free
- **Verdict:** No subscription needed. Pay only for cloud model usage.

### GitHub Copilot (`github.copilot`) — **Not installed, for reference**

- Individual: $10/month
- Business: $19/month
- Replaced in this stack by Continue (autocomplete) + OpenCode (agent)
- **Verdict:** Not worth adding; covered by current stack at $0.

### Claude Code (`anthropic.claude-code`) — **API pay-per-use**

- The extension is free; you pay for Anthropic API calls
- Configured here to use local Ollama — **free**
- If cloud Claude is used: ~$3–15 per session depending on Opus vs Haiku
- **Verdict:** Free as configured (Ollama). Cloud fallback billed by token.

---

## CLI Tools

### OpenCode — **Free, open source**

- MIT license, self-hosted
- Local usage via Ollama: free
- OpenRouter usage: pay per token (billed through OpenRouter account)
- **Verdict:** ✅ Free. Core tool.

### Crush — **Free, open source**

- Apache 2.0, Charm Industries
- Local usage: free
- **Verdict:** ✅ Free.

### Hermes — **Free (likely, check license)**

- Self-hosted at `~/.hermes/`
- Uses your own OpenRouter API key
- **Verdict:** ✅ Free as configured (Ollama primary, OpenRouter fallback billed
  per token).

### Aider — **Free, open source**

- Apache 2.0
- Local usage: free
- **Verdict:** ✅ Free.

---

## AI Editors

### Cursor — **Freemium, cloud-first**

| Tier | Price | Limits |
| --- | --- | --- |
| Free | $0/month | 200 fast requests/month, 50 slow requests |
| Pro | $20/month | 500 fast, unlimited slow, background agents |
| Business | $40/user/month | Team features, privacy mode, admin |

- For local Ollama use: free (but setup is unofficial/manual)
- For its intended use (Claude/GPT inline): Pro is required above 200 requests
- **Verdict for this stack:** Stay on free tier or drop. Local-first use doesn't
  need paid Cursor.

### Windsurf (Codeium) — **Not in active use, for reference**

| Tier | Price |
| --- | --- |
| Free | $0 — 25 Flow Actions/month |
| Pro | $15/month — unlimited |

- Not in the current active stack.

### Devin (Cognition) — **Very expensive**

- $500/month for 250 ACU (agent compute units)
- ~$2/ACU, enterprise pricing available
- **Not recommended** unless you have a specific use case that justifies it.

---

## API/Provider Costs (what you actually pay)

### OpenRouter — pay-per-token, no subscription

Current models used and their approximate costs per 1M tokens:

| Model | Input | Output | Notes |
| --- | --- | --- | --- |
| `anthropic/claude-sonnet-4-6` | $3 | $15 | Default cloud fallback |
| `anthropic/claude-opus-4-6` | $15 | $75 | Heavy reasoning only |
| `anthropic/claude-haiku-4-5` | $0.80 | $4 | Cheap fast tasks |
| `moonshot/kimi-k2.6` | $0.60 | $2.50 | Long-context, cheap |
| `perplexity/sonar-pro` | $3 | $15 | Web search built in |
| `openai/o3` | $10 | $40 | STEM reasoning |
| `google/gemini-2.5-flash` | $0.075 | $0.30 | Very cheap, fast |

**Typical session costs:**
- Light code task (Haiku): ~$0.01–0.05
- Standard coding session (Sonnet): ~$0.10–0.50
- Deep architecture review (Opus): ~$0.50–2.00

**With this stack's local-first setup:** most sessions cost $0 (Ollama). Cloud
is only hit when Ollama is unavailable (Hermes fallback) or explicitly chosen.

### Ollama — **Free**

- Free software, runs locally
- Bandwidth cost for model downloads (one-time): already done

---

## Monthly Cost Estimate (current stack, normal usage)

| Scenario | Est. cost/month |
| --- | --- |
| 100% local (Ollama only) | $0 |
| Mostly local, occasional cloud fallback | $2–10 |
| Heavy cloud use (Hermes research tasks) | $15–40 |
| Cursor Pro + OpenRouter | $20 + tokens |

**Configured correctly with Hermes local-first**, the practical cost is
$2–10/month for occasional research tasks that trigger the OpenRouter fallback.

---

## Subscriptions to Cancel / Avoid

These are not in this stack but common traps:

| Service | Cost | Why skip |
| --- | --- | --- |
| GitHub Copilot | $10–19/month | Covered by Continue + OpenCode |
| Cursor Pro | $20/month | Not needed for local-first stack |
| ChatGPT Plus | $20/month | Covered by OpenRouter o3/GPT-4o |
| Claude Pro | $20/month | Covered by OpenRouter per-token |
| Windsurf Pro | $15/month | Not in active use |

---

_Generated: 2026-06-11_  
_Profile: macbook-m5-64gb_
