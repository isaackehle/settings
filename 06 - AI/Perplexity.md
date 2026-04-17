---
tags: [ai, coding, productivity, search, api]
---

# Perplexity

AI search platform with real-time web grounding. Unlike standard LLMs, Perplexity models return cited, up-to-date answers sourced from the web — useful for research, current events, and anything that needs live data.

- **API Docs:** [docs.perplexity.ai](https://docs.perplexity.ai)
- **Console / API Keys:** [console.perplexity.ai](https://console.perplexity.ai)
- **API Base URL:** `https://api.perplexity.ai`
- **OpenAI-compatible:** yes (`/chat/completions` endpoint)

## Models

| Model               | ID                    | Best for                          |
| ------------------- | --------------------- | --------------------------------- |
| Sonar               | `sonar`               | Fast, cheap web-grounded answers  |
| Sonar Pro           | `sonar-pro`           | Complex queries, follow-ups       |
| Sonar Reasoning Pro | `sonar-reasoning-pro` | Multi-step reasoning + web search |
| Sonar Deep Research | `sonar-deep-research` | Exhaustive research reports       |

## Setup

```shell
export PERPLEXITY_API_KEY="pplx-..."
```

### curl

```shell
curl https://api.perplexity.ai/chat/completions \
  -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "sonar-pro",
    "messages": [{"role": "user", "content": "Latest news on Rust 2025?"}]
  }'
```

### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://api.perplexity.ai",
    api_key=os.environ["PERPLEXITY_API_KEY"],
)

response = client.chat.completions.create(
    model="sonar-pro",
    messages=[{"role": "user", "content": "Latest Rust release notes?"}],
)
```

## VS Code Integration

Perplexity has no dedicated VS Code extension. The best approaches:

### Via OpenRouter (Recommended)

Use OpenRouter's `perplexity/sonar` or `perplexity/sonar-pro` model IDs — no separate Perplexity API key needed. See [[OpenRouter]].

In **Cline** or **Continue**, set provider to OpenAI Compatible:
- Base URL: `https://openrouter.ai/api/v1`
- Model: `perplexity/sonar-pro`

### Via Perplexity API Directly

In **Cline** → Settings → API Provider → `OpenAI Compatible`:
- Base URL: `https://api.perplexity.ai`
- API Key: your `PERPLEXITY_API_KEY`
- Model ID: `sonar-pro`

In **Continue** (`~/.continue/config.yaml`):

```yaml
models:
  - name: Perplexity Sonar Pro
    provider: openai
    model: sonar-pro
    apiBase: https://api.perplexity.ai
    apiKey: pplx-...
    roles:
      - chat
```

## Web Search Options

Perplexity's API supports filtering web results:

```json
{
  "model": "sonar-pro",
  "messages": [...],
  "search_domain_filter": ["arxiv.org", "github.com"],
  "search_recency_filter": "month"
}
```

| Filter                  | Values                                 |
| ----------------------- | -------------------------------------- |
| `search_recency_filter` | `hour`, `day`, `week`, `month`, `year` |
| `search_domain_filter`  | list of domains to restrict results to |

## When to Use Perplexity vs Standard LLMs

| Use Perplexity                              | Use Claude/GPT               |
| ------------------------------------------- | ---------------------------- |
| Current events, recent releases             | Code generation, refactoring |
| Researching docs/APIs that changed recently | Long multi-file reasoning    |
| Quick factual lookups with citations        | Complex instructions         |
| Comparing products/tools                    | Creative writing             |

## References

- [Perplexity API Docs](https://docs.perplexity.ai)
- [Model Cards](https://docs.perplexity.ai/models/model-cards)
- [Perplexity on OpenRouter](https://openrouter.ai/models?q=perplexity)
