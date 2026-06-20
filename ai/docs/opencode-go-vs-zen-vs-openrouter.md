---
tags: [ai, providers, pricing, reference]
---

# OpenCode Go vs OpenCode Zen vs OpenRouter — Comparison

Three cloud model gateways in the OpenCode ecosystem. Different value propositions.

---

## Side-by-side

| | OpenCode Go | OpenCode Zen | OpenRouter |
| --- | --- | --- | --- |
| **Price** | $10/month ($5 first month) | $20 initial load, pay-per-use | Pay-per-token, no subscription |
| **Model selection** | 15 curated open-source models | Curated coding-agent models (tested & benchmarked) | 200+ models from any provider |
| **Rate limits** | Per-5-hour request caps (see table below) | No rate limits — pay per request | Per-provider, varies |
| **Quality guarantee** | Generous access, no testing claims | Models tested & validated for coding agents | No quality guarantee |
| **Privacy** | Standard | Zero-retention, US-hosted, no training | Varies by provider |
| **Works with** | OpenCode + any agent | OpenCode + any agent | Any OpenAI-compatible client |
| **Top-up** | Optional credit top-up | Auto-top-up at $5 remaining ($20) | Manual credit load |

---

## OpenCode Go — $10/month

**Models included (with per-5-hour request limits):**

| Model | Requests/5hr | Notes |
| --- | ---: | --- |
| Big Pickle + free models | 880 | Free tier bonus models |
| GLM-5.1 | 950 | Zhipu AI flagship |
| Qwen3.7 Max | 1,150 | Alibaba |
| Kimi K2.7 Code | 3,250 | Moonshot |
| MiMo-V2.5-Pro | 3,450 | Xiaomi reasoning |
| DeepSeek V4 Pro | 4,300 | DeepSeek flagship |
| Qwen3.7 Plus | 9,600 | Alibaba |
| MiniMax M3 | 30,100 | MiniMax (currently 3× limit) |
| MiMo-V2.5 | 31,650 | Xiaomi |
| DeepSeek V4 Flash | 31,650 | DeepSeek fast |

**When it's worth it:**
- You use OpenCode heavily and hit OpenRouter rate limits or cost caps
- You want predictable $10/month rather than variable per-token billing
- You primarily use open-source models (Kimi, DeepSeek, Qwen, GLM)
- You don't need Claude/GPT/Gemini (Go is open-source only)

**When it's not:**
- You're local-first with Ollama and only use cloud as fallback (your current setup)
- You need Claude/GPT/Gemini models
- Your monthly cloud usage is under $10

---

## OpenCode Zen — $20 load, pay-per-use

**What makes it different:**
- Every model is **specifically benchmarked for coding agents**
- Models are tested with provider teams to ensure correct tool-calling, context handling
- Transparent pricing: pay per request, zero markup over provider cost
- Auto-top-up: when balance hits $5, adds $20 automatically
- US-hosted, zero-retention, no training data use

**What it solves:**
OpenRouter has inconsistent quality across providers. The same model via different providers can behave differently with coding agents. Zen validates every model-provider combination before offering it.

**When it's worth it:**
- You're hitting quality issues with OpenRouter provider routing
- You want guaranteed tool-calling compatibility for your agent
- You use OpenCode as your primary coding tool and want the smoothest experience

**When it's not:**
- You're local-first (Zen is cloud-only)
- Your current OpenRouter experience is fine
- You need non-coding models (Zen is coding-agent focused)

---

## OpenRouter — pay-per-token

**Strengths:**
- Widest model selection (200+ models)
- Any provider, any model
- Works with every tool (OpenCode, Hermes, Crush, Continue, etc.)
- No subscription, load credits as needed
- Fallback routing between providers (if one goes down)

**Weaknesses:**
- Quality varies by provider — same model can behave differently
- No benchmarking or testing guarantee
- Some providers may be slower or rate-limited

**When it's worth it:**
- You're the primary cloud fallback for local-first tools
- You need Claude/GPT/Gemini alongside open-source
- You use multiple tools that all point to the same gateway

---

## Verdict for This Stack

### Current setup (local-first + Hermes + OpenCode)

| Tool | Primary | Fallback |
| --- | --- | --- |
| **Hermes** | Local Ollama | OpenRouter (Claude Sonnet) |
| **OpenCode** | Local Ollama | OpenRouter (varies) |
| **Crush** | Local Ollama | — |
| **Continue** | Local Ollama | OpenRouter (cloud models) |

### Should you add Go or Zen?

**No, not right now.** Here's why:

1. **Local usage = $0.** Most of your work stays on Ollama. Cloud is a fallback only.
2. **OpenRouter already covers fallback.** When local fails, OpenRouter's per-token pricing (~$0.05–1.50/session) is cheaper than Go's $10/month flat.
3. **Go's model set overlaps with local.** Kimi K2.7, DeepSeek V4, Qwen3.7 — you already run local versions of these via Ollama. Go's value is cloud access to these, but you have them locally.
4. **Zen's quality guarantee is for cloud-first users.** If you're local-first, the quality issue OpenRouter has (inconsistent tool-calling) doesn't affect you — your local models have proper templates (we fixed them today).

### When Go or Zen would make sense

| Scenario | Best choice |
| --- | --- |
| OpenCode is your ONLY tool, cloud-only | **Zen** ($20 load, quality guaranteed) |
| Heavy OpenRouter usage hitting rate limits | **Go** ($10/month, generous limits) |
| Laptop without local GPU, need cloud coding | **Zen** |
| Current local-first + occasional cloud fallback | **OpenRouter only** (keep current setup) |

---

## Monthly Cost Projection

| Usage pattern | OpenRouter | OpenCode Go | OpenCode Zen |
| --- | --- | --- | --- |
| Light (10 cloud sessions/month) | ~$2 | $10 | ~$3 |
| Medium (50 cloud sessions/month) | ~$10 | $10 | ~$15 |
| Heavy (200 cloud sessions/month) | ~$40 | $10 + top-up | ~$60 |
| **Your pattern (local-first)** | **~$3–5** | **$10** | **~$5** |

At your usage level, OpenRouter alone at $3–5/month is the cheapest. Go at $10 is paying a premium for models you already run locally.

---

## Subscription Recommendation

| Subscription | Keep? | Cost/month |
| --- | --- | --- |
| OpenRouter | ✅ Keep | ~$3–5 variable |
| OpenCode Go | ❌ Cancel | $10 (you have these locally) |
| OpenCode Zen | ❌ Not needed | $20 load (you're local-first) |
| Claude Pro | ✅ Keep (Comet ambient use) | $20 |
| Perplexity Pro | ✅ Keep (Comet) | $20 |
| **Unknown** | ❓ Check statement | ? |

**Potential savings: $10–30/month** by confirming OpenCode Go and the unknown subscription aren't redundant.

---

_Generated: 2026-06-13_
