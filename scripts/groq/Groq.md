---
tags: [ai, llm, api, cloud]
---

# Groq

Cloud LLM inference API — extremely fast token generation via custom LPU hardware. Free tier available.

## API Key

Get one at https://console.groq.com/keys, then add to `~/.env.local`:

```shell
export GROQ_API_KEY="gsk_..."
```

## Installation

No official CLI. Groq is used via API key in tools that support it (LiteLLM, Continue, OpenCode, etc.).

SDKs if needed:

```shell
pip install groq                   # Python
npm install groq-sdk               # Node
npm install @ai-sdk/groq           # Vercel AI SDK
```

## Models (2025)

| Model                                | Best for                 |
| ------------------------------------ | ------------------------ |
| `llama-3.3-70b-versatile`            | General purpose, default |
| `qwen-3-32b`                         | Reasoning + coding       |
| `llama-4-scout-17b-16e-instruct`     | Fast, multilingual       |
| `llama-4-maverick-17b-128e-instruct` | Balanced                 |

Full list: https://console.groq.com/docs/models

## Config

`~/.groq/local-settings.json` is used by the Groq Code CLI:

```json
{
  "defaultModel": "llama-3.3-70b-versatile"
}
```

## References

- [Groq Console](https://console.groq.com)
- [Groq docs](https://console.groq.com/docs)
- [Supported models](https://console.groq.com/docs/models)
