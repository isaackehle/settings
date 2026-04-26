---
tags: [ai, llm, models]
---

# AI Models

Central reference for model IDs across local (Ollama) and cloud (OpenRouter/direct API) providers.

## Cloud Models

Frontier models available via API only.

| Model                | Provider API ID             | OpenRouter ID                 | Best for                    |
| -------------------- | --------------------------- | ----------------------------- | --------------------------- |
| Claude Opus 4.6      | `claude-opus-4-6`           | `anthropic/claude-opus-4-6`   | Complex tasks, best quality |
| Claude Sonnet 4.6    | `claude-sonnet-4-6`         | `anthropic/claude-sonnet-4-6` | Balanced speed and quality  |
| Claude Haiku 4.5     | `claude-haiku-4-5-20251001` | `anthropic/claude-haiku-4-5`  | Fast, lightweight tasks     |
| GPT-4o               | `gpt-4o`                    | `openai/gpt-4o`               | General purpose             |
| o3                   | `o3`                        | `openai/o3`                   | Deep reasoning              |
| Gemini 2.5 Pro       | `gemini-2.5-pro`            | `google/gemini-2.5-pro`       | Long context, multimodal    |
| Mistral Large        | `mistral-large-latest`      | `mistralai/mistral-large`     | European, multilingual      |
| Perplexity Sonar Pro | —                           | `perplexity/sonar-pro`        | Web search, current events  |
| Kimi k2.6            | `kimi-k2.6:cloud`           | `moonshot/kimi-k2.6`          | Long context, reasoning     |

## Open Models

Available locally via Ollama and via OpenRouter.

| Model               | Ollama ID             | OpenRouter ID                           | Size (est) | Best for                   |
| ------------------- | --------------------- | --------------------------------------- | ---------- | -------------------------- |
| Codestral 22B       | `codestral:22b`       | `mistralai/codestral-2405`              | ~13GB      | Code, fill-in-middle       |
| DeepSeek Coder 6.7B | `deepseek-coder:6.7b` | `deepseek/deepseek-coder-6.7b-instruct` | ~4GB       | Code generation            |
| DeepSeek R1         | —                     | `deepseek/deepseek-r1`                  | —          | Reasoning, math            |
| DeepSeek R1 14B     | `deepseek-r1:14b`     | `deepseek/deepseek-r1-distill-qwen-14b` | ~9GB       | Local reasoning            |
| Gemma 3 12B         | `gemma3:12b`          | `google/gemma-3-12b-it`                 | ~7GB       | General purpose            |
| GLM-4 Flash         | `glm-4-flash`         | `thudm/glm-4-flash`                     | ~5GB       | Fast, Chinese-optimized    |
| Llama 3.1 70B       | —                     | `meta-llama/llama-3.1-70b-instruct`     | ~40GB      | Larger reasoning           |
| Llama 3.2           | `llama3.2`            | `meta-llama/llama-3.2-3b-instruct`      | ~2GB       | General purpose            |
| Gemma 4 31B         | `gemma4:31b`          | `google/gemma-4-31b-it`                 | ~18GB      | Reasoning, code            |
| Phi-4               | `phi4`                | `microsoft/phi-4`                       | ~9GB       | Efficient, small footprint |
| Qwen 2.5 Coder 7B   | `qwen2.5-coder:7b`    | `qwen/qwen-2.5-coder-7b-instruct`       | ~4.5GB     | Code generation            |
| Qwen 3.6 35B        | `qwen3.6:35b`         | `qwen/qwen3.6-35b`                      | ~18GB      | Large reasoning            |
| Qwen 3 Coder 7B     | `qwen3.2-coder:7b`    | `qwen/qwen3-coder-7b-instruct`          | ~4.5GB     | Code generation            |

## Local Model Specs

| Ollama ID         | Modelfile Path (Reference) | VRAM Req. | Status |
| ----------------- | -------------------------- | --------- | ------ |
| `gemma4:31b`      | `MODELS/gemma4-31b.mf`     | ~20GB     | ✅ Fits |
| `qwen3.6:35b`     | `MODELS/qwen3.6-35b.mf`    | ~18GB     | ✅ Fits |
| `codestral:22b`   | `MODELS/codestral-22b.mf`  | ~14GB     | ✅ Fits |
| `deepseek-r1:14b` | `MODELS/ds-r1-14b.mf`      | ~10GB     | ✅ Fits |
| `phi4`            | `MODELS/phi4.mf`           | ~10GB     | ✅ Fits |

## Embedding Models

| Model       | Ollama ID          | Use                    |
| ----------- | ------------------ | ---------------------- |
| Nomic Embed | `nomic-embed-text` | Codebase indexing, RAG |

## OpenRouter Variants

Append to any OpenRouter model ID:

| Suffix      | Effect                                 |
| ----------- | -------------------------------------- |
| `:free`     | Free tier (may be slower/rate-limited) |
| `:nitro`    | Fastest available provider             |
| `:thinking` | Extended chain-of-thought reasoning    |
| `:online`   | Web search grounding                   |
| `:extended` | Longer context window                  |

## References

- [[Ollama]] — local model manager
- [[OpenRouter]] — unified cloud API gateway
- [[Cline]] — VS Code agent (uses these model IDs)
- [[Continue]] — VS Code autocomplete (uses these model IDs)
