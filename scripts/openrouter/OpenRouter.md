---
tags: [ai, coding, productivity, api, routing]
---

# OpenRouter

Unified API gateway giving access to hundreds of AI models through a single OpenAI-compatible endpoint. Handles provider routing, fallbacks, and cost optimization automatically.

- **API Base URL:** `https://openrouter.ai/api/v1`
- **Docs:** [openrouter.ai/docs](https://openrouter.ai/docs)
- **Model catalog:** [openrouter.ai/models](https://openrouter.ai/models)

## Why Use It

- **One API key** for Claude, GPT, Gemini, Llama, Mistral, and hundreds more
- **Automatic fallbacks** — if a provider is down or rate-limited, it retries another
- **Provider routing** — picks the cheapest or fastest provider for a given model
- **Prompt caching** — cache-read pricing on supported models (Claude, Gemini) cuts repeated-context costs
- **BYOK** — bring your own Anthropic/OpenAI/etc. keys to skip markup
- **Zero Data Retention** — opt out of logging for privacy

## Setup

Get an API key at [openrouter.ai/keys](https://openrouter.ai/keys), then use it like any OpenAI-compatible API.

### Environment

```shell
export OPENROUTER_API_KEY="sk-or-..."
```

### OpenAI SDK (Python)

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key=os.environ["OPENROUTER_API_KEY"],
)

response = client.chat.completions.create(
    model="anthropic/claude-sonnet-4-6",
    messages=[{"role": "user", "content": "Hello"}],
)
```

### OpenAI SDK (Node)

```ts
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "https://openrouter.ai/api/v1",
  apiKey: process.env.OPENROUTER_API_KEY,
});
```

### curl

```shell
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "anthropic/claude-sonnet-4-6",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

## Model IDs

Models follow `provider/model-name` convention. See [[Models]] for the full reference.

Quick examples: `anthropic/claude-sonnet-4-6`, `openai/gpt-4o`, `deepseek/deepseek-r1`

### Model Variants

Append suffixes to tweak behavior:

| Suffix      | Meaning                    |
| ----------- | -------------------------- |
| `:free`     | Free tier (may be slower)  |
| `:nitro`    | Fastest available provider |
| `:thinking` | Extended reasoning mode    |
| `:online`   | Web search enabled         |
| `:extended` | Longer context window      |

Example: `anthropic/claude-sonnet-4-6:thinking`

### Auto Router

Use `openrouter/auto` to let OpenRouter pick the best model for each request via NotDiamond:

```json
{ "model": "openrouter/auto" }
```

## Provider Routing

Control which providers are used per request:

```json
{
  "model": "anthropic/claude-sonnet-4-6",
  "provider": {
    "order": ["Anthropic", "AWS Bedrock"],
    "allow_fallbacks": true
  }
}
```

Optimize for cost or speed:

```json
{
  "provider": {
    "sort": "price"
  }
}
```

## Prompt Caching

Supported on Claude and Gemini models. Repeated context (system prompts, large documents) is billed at the cheaper cache-read rate automatically — no extra configuration needed.

## Coding Agent Integration

### Claude Code

```shell
ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1 \
ANTHROPIC_API_KEY=$OPENROUTER_API_KEY \
claude
```

### Cline (VS Code)

Set **API Provider** → `OpenAI Compatible`:
- Base URL: `https://openrouter.ai/api/v1`
- API Key: your OpenRouter key
- Model ID: e.g. `anthropic/claude-sonnet-4-6`

### Continue.dev

```yaml
models:
  - name: Claude via OpenRouter
    provider: openai
    model: anthropic/claude-sonnet-4-6
    apiBase: https://openrouter.ai/api/v1
    apiKey: sk-or-...
```

### OpenCode

```json
{
  "provider": {
    "openrouter": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OpenRouter",
      "options": {
        "baseURL": "https://openrouter.ai/api/v1",
        "apiKey": "sk-or-..."
      },
      "models": {
        "claude-sonnet": {
          "name": "anthropic/claude-sonnet-4-6"
        }
      }
    }
  }
}
```

## References

- [OpenRouter Docs](https://openrouter.ai/docs)
- [Model Catalog](https://openrouter.ai/models)
- [Pricing](https://openrouter.ai/models?order=pricing)
