---
tags: [ai, openrouter, optimization, reference]
---

# OpenRouter Optimization Guide — June 2026

OpenRouter has a massive feature set that most users never touch. This guide
covers the optimizations that matter for a local-first stack with cloud fallback.

---

## The Big Wins (Do These First)

### 1. Prompt Caching — 50–90% Cost Reduction on Repeated Context

OpenRouter passes through prompt caching from Anthropic and OpenAI natively.
When you send the same system prompt or long context prefix repeatedly,
providers cache it and charge dramatically less.

**Anthropic Claude:**
- First request: full price
- Subsequent requests with same prefix: **90% cheaper on cached tokens**
- Cache TTL: 5 minutes (auto-extended on use)
- Free — Anthropic doesn't charge extra for caching

**OpenAI GPT:**
- Cached tokens: **50% cheaper** than uncached
- Cache TTL: 5–10 minutes
- Free — built into pricing

**How to use it:** Put your system prompt and any repeated context
(skills, instructions, project context) at the START of the messages array.
OpenRouter passes it through to providers who handle caching automatically.

**Impact for Hermes:** Hermes sessions reuse the same system prompt and
memory context across turns. With caching, only the new user message and
tool results are billed at full price. Estimated savings: 50–70% per session.

**Impact for OpenCode:** Agent system prompts and AGENTS.md content are
repeated every turn. Cache those prefixes.

### 2. Model Variants — `:exacto`, `:free`, `:nitro`, `:thinking`, `:online`

OpenRouter appends suffixes to model slugs to access specialized variants:

| Suffix | What it does | When to use |
| --- | --- | --- |
| `:exacto` | Prioritizes providers with strongest tool-calling signals | **Agent tool use** (OpenCode, Hermes, Crush) |
| `:free` | Routes to free-tier providers | Non-critical exploration, testing |
| `:nitro` | High-speed providers, lower latency | Interactive chat, autocomplete |
| `:thinking` | Extended reasoning enabled | Architecture decisions, debugging |
| `:online` | Real-time web search built in | Research tasks |

**Current setup uses:** `anthropic/claude-sonnet-4-6` (base)

**Better alternatives per tool:**

| Tool | Current | Recommended | Why |
| --- | --- | --- | --- |
| Hermes fallback | `anthropic/claude-sonnet-4-6` | `anthropic/claude-sonnet-4-6:exacto` | Better tool-calling quality |
| OpenCode research | `perplexity/sonar-pro` | `perplexity/sonar-pro:online` or `google/gemini-2.5-flash:online` | Built-in web search, cheaper |
| Crush quick tasks | `anthropic/claude-haiku-4-5` | `anthropic/claude-haiku-4-5:nitro` | Faster responses |

### 3. Model Fallbacks in API Requests

OpenRouter supports automatic failover in a single API call. If your primary
model is rate-limited, down, or errors, it tries the next one.

```json
{
  "model": "anthropic/claude-sonnet-4-6",
  "models": ["anthropic/claude-sonnet-4-6", "google/gemini-2.5-pro", "openai/gpt-4o"]
}
```

**Cost:** You only pay for the model that actually responds.

**For Hermes:** Already configured with `fallback_providers` in config.yaml,
but OpenRouter's server-side fallbacks are faster (no round-trip to the client).

### 4. Provider Routing — Optimize for Cost or Latency

```json
{
  "provider": {
    "order": ["Anthropic", "Azure"],
    "allow_fallbacks": true,
    "sort": "price"
  }
}
```

Options:
- `sort: "price"` — cheapest provider first
- `sort: "throughput"` — fastest provider first
- `sort: "latency"` — lowest latency provider first

**For your stack:** `sort: "price"` as default. Hermes long sessions benefit
from cheaper per-token costs. OpenCode interactive work benefits from
`sort: "latency"`.

### 5. Response Caching — Free for Identical Requests

```json
{
  "cache": true
}
```

Caches identical responses for 300 seconds. Useful for:
- Repeated tool calls with same arguments
- Agent workflows that retry the same prompt
- Unit testing and evaluation

**Cost:** Free. Reduces both cost and latency.

### 6. Guardrails — Spending Limits

Set hard spending caps per API key to prevent runaway costs:

- **Credit limits:** Stop serving when credits drop below threshold
- **Model restrictions:** Block expensive models on certain keys
- **Rate limits:** Cap requests per minute

**For Hermes/OpenCode:** Set a $20/month guardrail on the shared API key.
Prevents surprise bills from long sessions or retry loops.

---

## Routers — Automatic Model Selection

OpenRouter has several built-in routers that pick the best model for you:

### Auto Router (`openrouter/auto`)

Powered by NotDiamond. Analyzes your prompt and picks the best model
based on the task type. Good for mixed workloads.

**Cost:** Slight premium over base model pricing.

### Pareto Router (`openrouter/pareto`)

Routes by coding benchmark score. Specify a minimum score and it picks
the cheapest model that meets it.

```json
{
  "model": "openrouter/pareto",
  "provider": { "min_coding_score": 85 }
}
```

**Use case:** OpenCode coding tasks. Guarantees quality while minimizing cost.

### Free Models Router (`openrouter/free`)

Routes to free-tier models only. Zero cost.

```json
{
  "model": "openrouter/free"
}
```

**Use case:** Exploration, testing, non-critical tasks. Models include
`qwen3.5:4b:free`, `llama-3.3-70b:free`, etc.

### Fusion Router (`openrouter/fusion`)

Runs multiple models in parallel, compares responses through a judge,
returns consensus answer. Expensive but highest quality.

**Use case:** Critical architecture decisions. Not for everyday use.

---

## Server Tools — Built-In Capabilities

OpenRouter can inject server-side tools that any model can call:

| Tool | Slug | Cost | Use |
| --- | --- | --- | --- |
| **Web Search** | `:online` variant | Varies | Real-time web search with citations |
| **Web Fetch** | `web_fetch` | Varies | Fetch and parse URL content |
| **Image Gen** | `image_generation` | Varies | Generate images from text |
| **Datetime** | `datetime` | Free | Current date/time awareness |
| **Advisor** | `advisor` | Extra model cost | Consult a larger model mid-generation |
| **Subagent** | `subagent` | Extra model cost | Delegate sub-tasks to cheaper model |

**Best for Hermes:** `:online` variant on `google/gemini-2.5-flash` for
research tasks — gets web search without a separate tool.

**Best for OpenCode:** `advisor` tool — keep the main agent on a fast
model, escalate to Opus/o3 only when stuck.

---

## Optimized Configurations Per Tool

### Hermes Fallback

```yaml
# ~/.hermes/config.yaml
model:
  default: qwen2.5:32b-96k          # local primary
  provider: ollama
fallback_providers:
  - name: openrouter
    default_model: anthropic/claude-sonnet-4-6:exacto
    cache: true
```

The `:exacto` variant improves tool-calling reliability.
Prompt caching reduces repeated context costs by 50–70%.

### OpenCode Provider Config

```jsonc
// opencode.jsonc provider section
"openrouter": {
  "npm": "@ai-sdk/openai-compatible",
  "options": {
    "baseURL": "https://openrouter.ai/api/v1",
    "headers": {
      "HTTP-Referer": "https://localhost",
      "X-Title": "OpenCode"
    }
  },
  "models": {
    "anthropic/claude-sonnet-4-6:exacto": {
      "name": "Claude Sonnet 4.6 (Exacto, Tool-Optimized)"
    },
    "anthropic/claude-haiku-4-5:nitro": {
      "name": "Claude Haiku 4.5 (Nitro, Fast)"
    },
    "google/gemini-2.5-flash:online": {
      "name": "Gemini 2.5 Flash (Online, Web Search)"
    },
    "perplexity/sonar-pro": {
      "name": "Sonar Pro (Web Search)"
    },
    "openrouter/free": {
      "name": "Free Models Router"
    }
  }
}
```

### Cost-Optimized Agent Routing

For OpenCode, use different models per agent role:

| Agent | Model | Why |
| --- | --- | --- |
| `code` | Local `qwen3-coder-30b-a3b:q6` | Fast, free, good at editing |
| `think` | Local `deepseek-r1-tools:32b` or `anthropic/claude-haiku-4-5:nitro` | Fast reasoning |
| `research` | `google/gemini-2.5-flash:online` | Built-in web search, cheap |
| `write` | Local `qwen3.5-27b:q4` | Good prose, free |
| `plan` | Local `qwen3:4b` | Fast, free |
| `build` | Local `qwen3-coder-30b-a3b:q6` | Fast, free |
| `summary` | Local `qwen3.5:4b` | Fast, free |
| `title` | Local `qwen3.5:4b` | Fast, free |

Only `research` and `think` (when local is unavailable) should hit cloud.

---

## Monitoring & Cost Tracking

### Check Credit Balance

```shell
curl -s -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  https://openrouter.ai/api/v1/credits
```

### View Activity

OpenRouter dashboard at openrouter.ai/activity shows:
- Per-model usage and cost
- Per-API-key breakdown
- Token counts (prompt, completion, cached)
- Generation history with full prompt/completion logging

### Set Up Alerts

In OpenRouter dashboard → Settings → Guardrails:
- Credit alert at $5 remaining
- Hard stop at $0 remaining
- Block models over $10/1M tokens

---

## Estimated Monthly Costs — Optimized

| Scenario | Before tuning | After tuning |
| --- | --- | --- |
| Light (10 sessions, local primary) | $3–5 | $1–2 |
| Medium (50 sessions, mixed) | $10–15 | $4–6 |
| Heavy (200 sessions, cloud-heavy) | $40–60 | $15–25 |

**Biggest savings come from:**
1. Prompt caching (50–70% on repeated context)
2. Using `:exacto` variants (fewer retries = less wasted tokens)
3. Routing research through `:online` models instead of Sonar Pro
4. Using local models for everything except web-dependent tasks

---

## Quick Reference — API Headers

```shell
# Standard OpenRouter request
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://localhost" \
  -H "X-Title: MyApp" \
  -d '{
    "model": "anthropic/claude-sonnet-4-6:exacto",
    "messages": [...],
    "provider": { "sort": "price" },
    "cache": true
  }'
```

Key headers:
- `HTTP-Referer` — identifies your app (appears in OpenRouter rankings)
- `X-Title` — app name for analytics
- `Authorization` — your API key

---

## What's NOT Worth Paying For

- **OpenCode Go ($10/month):** You already run these models locally
- **OpenCode Zen ($20 load):** Quality guarantee helps cloud-first users, not local-first
- **Opus for coding tasks:** Sonnet 4.6 is 95% as good at 20% the price
- **GPT-5.4 for coding:** Claude Sonnet outperforms at lower cost
- **Reasoning tokens (`:thinking`) for simple tasks:** Only use for architecture/design decisions

## Configuration TODOs — Comet Prompts

Copy each prompt into Comet (Perplexity's AI browser) to get step-by-step help
configuring each optimization. Work through them in order — each one is independent
and takes 2–5 minutes.

---

### TODO 1: Audit Current OpenRouter Usage

```
Check my OpenRouter account at openrouter.ai and tell me:
1. What's my current credit balance?
2. What were my top 5 models by spend in the last 30 days?
3. How many total tokens (prompt + completion + cached) did I use?
4. What's my average cost per session?
5. Are there any models I'm paying for that have free alternatives?

Give me a summary table of what I'm spending and where I can cut costs.
```

**What this does:** Establishes a baseline before optimizing. You need to know
what you're currently spending to measure improvement.

---

### TODO 2: Set Up Spending Guardrails

```
Help me configure OpenRouter guardrails at openrouter.ai/settings/guardrails:
1. Set a credit alert when my balance drops below $5
2. Set a hard stop when my balance hits $0 (prevent surprise charges)
3. Block any model over $10 per million tokens (no Opus/o3 for routine work)
4. Set a monthly spending cap of $20

Walk me through the UI and confirm each setting is saved.
```

**What this does:** Prevents runaway costs from retry loops or long sessions.
$20/month is generous for your local-first stack.

---

### TODO 3: Update Hermes Fallback to Use `:exacto`

```
Help me update my Hermes Agent config at ~/.hermes/config.yaml:
1. Change the OpenRouter fallback model from `anthropic/claude-sonnet-4-6`
   to `anthropic/claude-sonnet-4-6:exacto`
2. Add `"cache": true` to the OpenRouter provider config
3. Verify the config is valid YAML

Show me the exact lines to edit and confirm the changes are saved.
```

**What this does:** `:exacto` variant improves tool-calling reliability by
prioritizing providers with stronger tool-calling signals. Caching reduces
repeated context costs by 50–70%.

---

### TODO 4: Update OpenCode Provider Config

```
Help me update my OpenCode config at ~/.config/opencode/opencode.jsonc:
1. In the `openrouter` provider section, add these model variants:
   - `anthropic/claude-sonnet-4-6:exacto` as "Claude Sonnet 4.6 (Exacto, Tool-Optimized)"
   - `anthropic/claude-haiku-4-5:nitro` as "Claude Haiku 4.5 (Nitro, Fast)"
   - `google/gemini-2.5-flash:online` as "Gemini 2.5 Flash (Online, Web Search)"
2. Keep the existing models (sonar-pro, kimi-k2.6, etc.)
3. Verify the JSON is valid

Show me the exact JSON to add and confirm the changes are saved.
```

**What this does:** Gives OpenCode access to optimized variants. `:exacto`
for tool-calling, `:nitro` for fast responses, `:online` for built-in web search.

---

### TODO 5: Optimize OpenCode Agent Routing

```
Help me update my OpenCode agent config at ~/.config/opencode/opencode.jsonc:
1. Change the `research` agent model from `ollama/qwen3.5-27b:q4` to
   `openrouter/google/gemini-2.5-flash:online` (for built-in web search)
2. Keep all other agents on local Ollama models
3. Verify the JSON is valid

Show me the exact agent section to edit and confirm the changes are saved.
```

**What this does:** Routes research tasks to a model with built-in web search
instead of requiring a separate tool. `gemini-2.5-flash:online` is cheaper
than `sonar-pro` and has built-in citations.

---

### TODO 6: Test Prompt Caching

```
Help me test OpenRouter prompt caching:
1. Make two identical API calls to `anthropic/claude-sonnet-4-6` with the same
   system prompt and user message
2. Compare the cost of the first request vs the second request
3. Verify that cached tokens are 90% cheaper

Use this test payload:
{
  "model": "anthropic/claude-sonnet-4-6",
  "messages": [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "What is 2+2?"}
  ]
}

Show me the API response headers or billing breakdown that confirms caching worked.
```

**What this does:** Validates that prompt caching is working. You should see
a dramatic cost difference between the first and second identical request.

---

### TODO 7: Set Up OpenRouter Observability

```
Help me set up OpenRouter logging at openrouter.ai/settings/observability:
1. Enable input/output logging (private, stored for 30 days)
2. Show me how to view logs at openrouter.ai/logs
3. Explain how to export logs as CSV for analysis

This helps me debug which prompts are expensive and optimize them.
```

**What this does:** Gives you visibility into what's being sent to OpenRouter
and how much each request costs. Essential for ongoing optimization.

---

### TODO 8: Create a Cost-Optimized API Key

```
Help me create a new OpenRouter API key at openrouter.ai/settings/keys:
1. Name it "Local-First Stack"
2. Set a credit limit of $20 (hard stop)
3. Block models over $10/1M tokens
4. Show me how to use this key in my tools (Hermes, OpenCode, Crush)

This key is for my local-first stack. Keep my existing key for cloud-heavy tasks.
```

**What this does:** Creates a dedicated key with spending limits for your
local-first tools. Prevents accidental overspending.

---

### TODO 9: Test Provider Routing

```
Help me test OpenRouter provider routing:
1. Make three API calls to `anthropic/claude-sonnet-4-6` with different
   provider sort options:
   - `{"provider": {"sort": "price"}}` (cheapest first)
   - `{"provider": {"sort": "throughput"}}` (fastest first)
   - `{"provider": {"sort": "latency"}}` (lowest latency)
2. Compare the response times and costs
3. Tell me which sort option is best for my use case (local-first with
   occasional cloud fallback)

Show me the exact API calls and compare the results in a table.
```

**What this does:** Helps you choose the right provider routing strategy.
For your stack, `"sort": "price"` is usually best.

---

### TODO 10: Audit and Cancel Redundant Subscriptions

```
Help me audit my AI subscriptions:
1. Check my credit card statement for the last 3 months
2. List all AI-related subscriptions (OpenRouter, Claude Pro, Perplexity Pro,
   OpenCode Go, ChatGPT Plus, Cursor Pro, etc.)
3. Calculate my total monthly AI spend
4. Compare to my actual usage (from OpenRouter and other dashboards)
5. Recommend which subscriptions to cancel based on overlap

Focus on: Am I paying for models I already run locally? Am I paying for
cloud access I don't use?
```

**What this does:** Final cost optimization. You're likely paying $60–80/month
in subscriptions when your actual usage is $3–10/month. This audit identifies
redundancies.

---

## Quick Start — Do These First

If you only have 15 minutes, do these three:

1. **TODO 2** — Set spending guardrails (2 min)
2. **TODO 3** — Update Hermes to use `:exacto` (2 min)
3. **TODO 10** — Audit subscriptions (10 min)

These three will save you the most money with the least effort.

---

_Generated: 2026-06-13_  
_Profile: macbook-m5-64gb_
