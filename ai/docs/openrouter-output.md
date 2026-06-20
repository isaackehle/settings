Here's your full OpenRouter account breakdown for the past 30 days:

---

## 1. Current Credit Balance

**$15.60** remaining[[openrouter](https://openrouter.ai/settings/credits)]

Auto top-up is **enabled** — it adds $15 credits whenever your balance drops below $2. Given your burn rate (see below), that's going to trigger frequently.[[openrouter](https://openrouter.ai/settings/credits)]

---

## 2. Top 5 Models by Spend (Last 30 Days)

| Rank | Model                 | Spend  | % of Total |
| ---- | --------------------- | ------ | ---------- |
| 1    | **Claude Sonnet 4.6** | $85.80 | 69.0%      |
| 2    | **Claude Opus 4.8**   | $23.80 | 19.1%      |
| 3    | **MiniMax M3**        | $3.18  | 2.6%       |
| 4    | **GPT-5.5**           | $3.06  | 2.5%       |
| 5    | **Kimi K2.6**         | $2.45  | 2.0%       |

Claude Sonnet 4.6 alone is responsible for nearly **7 in every $10** you spend.[[openrouter](https://openrouter.ai/activity/explore?from=2026-05-16T04%3A00%3A00.000Z&to=2026-06-15T03%3A59%3A59.999Z&date_preset=past_1_month)]

---

## 3. Total Token Usage (Last 30 Days)

- **Total token volume: 178M tokens**[[openrouter](https://openrouter.ai/activity?from=2026-05-16T04:00:00.000Z&to=2026-06-15T03:59:59.999Z&date_preset=past_1_month)]

- **Cache hit rate: 71.8%** — this is excellent and means your caching is working well[[openrouter](https://openrouter.ai/activity?from=2026-05-16T04:00:00.000Z&to=2026-06-15T03:59:59.999Z&date_preset=past_1_month)]

Token breakdown by model (total tokens):[[openrouter](https://openrouter.ai/activity/explore?from=2026-05-16T04:00:00.000Z&to=2026-06-15T03:59:59.999Z&date_preset=past_1_month)]

| Model             | Tokens |
| ----------------- | ------ |
| Claude Sonnet 4.6 | 97.5M  |
| MiniMax M3        | 25.1M  |
| Laguna XS.2       | 23.2M  |
| Claude Opus 4.8   | 9.12M  |
| Kimi K2.6         | 4.31M  |

Note: OpenRouter's activity view shows total token volume as a combined metric. The 71.8% cache hit rate means roughly **127M tokens were served from cache**, significantly reducing your actual compute cost.

---

## 4. Average Cost Per Request/Session

- **Total spend:** $124.39[[openrouter](https://openrouter.ai/activity?from=2026-05-16T04:00:00.000Z&to=2026-06-15T03:59:59.999Z&date_preset=past_1_month)]

- **Total requests:** ~3,000[[openrouter](https://openrouter.ai/activity?from=2026-05-16T04:00:00.000Z&to=2026-06-15T03:59:59.999Z&date_preset=past_1_month)]

- **Average cost per request:** ~**$0.041** (~4.1 cents per request)

OpenRouter doesn't expose a native "session" grouping, but your top apps give context:[[openrouter](https://openrouter.ai/activity?from=2026-05-16T04:00:00.000Z&to=2026-06-15T03:59:59.999Z&date_preset=past_1_month)]

- **Hermes Agent**: 82.7M tok

- **Crush (CLI)**: 49.2M tok

- **Unknown**: 40.9M tok

- **Cline**: 3.18M tok

- **Roo Code**: 1.69M tok

Hermes Agent and Crush are your biggest token consumers — likely long agentic loops driving the cost.

---

## 5. Paid Models With Free Alternatives

| Your Paid Model              | Spend  | Free Alternative on OpenRouter                                                                                                        |
| ---------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| Claude Sonnet 4.6            | $85.80 | `openai/gpt-oss-120b:free`, `nvidia/nemotron-3-super-120b-a12b:free`[[costgoat](https://costgoat.com/pricing/openrouter-free-models)] |
| Claude Opus 4.8              | $23.80 | `openai/gpt-oss-120b:free`, Nex-N2-Pro (free)[[openrouter](https://openrouter.ai/collections/free-models)]                            |
| MiniMax M3                   | $3.18  | `google/gemma-4-31b-it:free`, `qwen/qwen3-coder:free`[[costgoat](https://costgoat.com/pricing/openrouter-free-models)]                |
| GPT-5.5                      | $3.06  | `openai/gpt-oss-120b:free`[[costgoat](https://costgoat.com/pricing/openrouter-free-models)]                                           |
| Kimi K2.6                    | $2.45  | **`moonshot/kimi-k2.6:free`** exists on OpenRouter[[openrouter](https://openrouter.ai/compare/minimax/minimax-m3)]                    |
| Llama 3.3 Nemotron Super 49B | $1.69  | `nvidia/nemotron-3-super-120b-a12b:free`[[openrouter](https://openrouter.ai/collections/free-models)]                                 |
| Gemma 4 31B                  | $0.027 | `google/gemma-4-31b-it:free`[[costgoat](https://costgoat.com/pricing/openrouter-free-models)]                                         |

**Key finding:** Kimi K2.6 has a free variant directly on OpenRouter. That's a direct swap with zero migration cost.[[openrouter](https://openrouter.ai/compare/minimax/minimax-m3)]

---

## 6. Cost Summary & Where to Cut

| Model | Spend | Tokens | Cost/1M tok | Action |
| ----- | ----- | ------ | ----------- | ------ |

| Model             | Spend     | Tokens | Cost/1M tok | Action                                                                                                  |
| ----------------- | --------- | ------ | ----------- | ------------------------------------------------------------------------------------------------------- |
| Claude Sonnet 4.6 | $85.80    | 97.5M  | ~$0.88      | **Biggest lever** — route non-critical Hermes/Crush agent steps to a free/cheaper model                 |
| Claude Opus 4.8   | $23.80    | 9.12M  | ~$2.61      | Reserve for tasks that actually need it; replace exploratory use                                        |
| MiniMax M3        | $3.18     | 25.1M  | ~$0.13      | Low cost/token — keep, but try `gemma-4-31b:free` for lower-stakes tasks                                |
| GPT-5.5           | $3.06     | 1.44M  | ~$2.13      | High cost/token — audit what's calling this and consider `gpt-oss-120b:free`                            |
| Kimi K2.6         | $2.45     | 4.31M  | ~$0.57      | **Swap to `:free` variant immediately**[[openrouter](https://openrouter.ai/compare/minimax/minimax-m3)] |
| Laguna XS.2       | ~$0 spend | 23.2M  | Free        | Already free — great usage                                                                              |
| Everything else   | ~$5.63    | —      | —           | Minor, low priority                                                                                     |

**Top 3 cost-cutting moves:**

1. **Route Hermes Agent's non-critical steps away from Claude Sonnet 4.6.** This model alone is $85.80/month. Even routing 50% of its volume to a free model (like `gpt-oss-120b:free` or `nex-n2-pro:free`) could save $40+/month.

2. **Swap Kimi K2.6 → `kimi-k2.6:free`** — zero-effort, same model, saves ~$2.45/month.

3. **Audit GPT-5.5 usage** — at ~$2.13/1M tokens it's your most expensive per-token model after Opus. Check what's calling it and whether `gpt-oss-120b:free` (OpenAI's open-weight 120B) covers the use case.

Your 71.8% cache hit rate is already excellent — keep that up. The real savings are in smart model routing at the agent level.

Here's a full summary of every change made to your OpenRouter account (`isaac@kehle.org`) this session:

---

## Changes Made — OpenRouter Guardrails Configuration

## 1. Monthly Spending Cap — $20/Month

**Where:** `openrouter.ai/workspaces/default/guardrails/default/budget`
**What changed:** The Workspace Guardrail's Budget Policy was set from **no limit** to **$20 every Month**.
**Effect:** Once your API usage hits $20 in a rolling monthly period, all requests across both `main dev` and `opencode` API keys are hard-blocked until the next billing cycle. This is the primary cost ceiling.

---

## 2. Blocked 9 High-Cost Models (>$10/M tokens)

**Where:** `openrouter.ai/workspaces/default/guardrails/default/models`
**What changed:** The following models were added to the **Blocked Models** list under the Workspace Guardrail's Model & Provider Access policy (previously "No policies / Allow All"):

| #   | Blocked Model          | Typical Output Cost |
| --- | ---------------------- | ------------------- |
| 1   | Claude Opus 4.8 (Fast) | ~$15–75/M           |
| 2   | Claude Opus 4.8        | ~$15–75/M           |
| 3   | Claude Opus 4.7 (Fast) | ~$25/M              |
| 4   | Claude Opus 4.7        | ~$25/M              |
| 5   | Claude Opus 4.6 (Fast) | ~$25/M              |
| 6   | Claude Opus 4.6        | ~$25/M              |
| 7   | GPT-5.5 Pro            | ~$30+/M             |
| 8   | GPT-5.5                | ~$30/M              |
| 9   | GPT-5.4 Pro            | ~$30+/M             |

**Effect:** Any API call to these models — from any app (Hermes Agent, Crush, Cline, Roo Code, etc.) using either API key — will be rejected immediately with a guardrail error instead of being billed. The eligible model count dropped from 413 → 404.

---

## 3. Auto Top-Up Disabled (Hard Stop at $0)

**Where:** `openrouter.ai/settings/credits` → Auto Top-Up
**What changed:** Auto Top-Up was **enabled** (triggering at $2 balance, charging $15 to Visa ending 1383) → now **disabled**.[[openrouter](https://openrouter.ai/settings/credits)]
**Effect:** Your Visa will no longer be automatically charged under any circumstance. When your credit balance reaches $0, API requests hard-stop. No surprise charges possible. You can re-enable anytime via Credits → Enable.

---

## What Was NOT Changed / What OpenRouter Doesn't Support Natively

- **Credit alert at $5 (notification only):** OpenRouter has no email/webhook alert for low balance without Auto Top-Up. There is no standalone "alert-only" threshold in the UI — it's all tied to Auto Top-Up. To get a $5 alert, you'd need to re-enable Auto Top-Up and set the threshold to 5 (but that also auto-charges).

---

## Before vs. After

| Setting             | Before                                     | After                                    |
| ------------------- | ------------------------------------------ | ---------------------------------------- |
| Monthly spend cap   | None                                       | $20/month hard limit                     |
| Model access        | All 413 models allowed                     | 404 models (9 Opus/GPT-5.5-tier blocked) |
| Auto Top-Up         | Enabled — charged at $2, adds $15          | Disabled — no auto-charges               |
| Hard stop mechanism | None (card would auto-charge indefinitely) | $0 balance = API blocked; $20/month cap  |

---

## Current Account State

- **Balance:** $15.18[[openrouter](https://openrouter.ai/settings/credits)]

- **Guardrail scope:** Applies to all API keys in your workspace (`main dev` + `opencode`)

- **Card on file:** Visa ending 1383 — still attached, just won't auto-charge
