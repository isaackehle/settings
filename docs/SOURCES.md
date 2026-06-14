---
tags: [ai, reference]
---

# Sources

Tracking where model information and decisions come from. When a decision in
`MODELS.md` is updated, log the source here with a re-check URL.

## Model Information Sources

| Date       | Model                   | Source                                                                                                                         | Re-check URL                                      |
| ---------- | ----------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| 2026-05-27 | `deepseek-r1`           | Ollama official library page — confirmed tags: `1.5b`, `8b`, `14b`, `32b`, `70b`, `671b`                                       | <https://ollama.com/library/deepseek-r1>          |
| 2026-05-27 | `deepseek-r1-tools`     | Ollama search + local install — community fine-tune, not official DeepSeek. Only `32b` tag confirmed                           | <https://ollama.com/search?q=deepseek-r1-tools>   |
| 2026-05-27 | `deepseek-r1:8b`        | Ollama official library tags list — valid 8B distilled reasoning model (no tool-calling)                                       | <https://ollama.com/library/deepseek-r1/tags>     |
| 2026-05-27 | `deepseek-r1-tools:8b`  | Not confirmed as valid Ollama tag. The `deepseek-r1-tools` library only shows `32b` variants. May need `ollama pull` to verify | <https://ollama.com/search?q=deepseek-r1-tools>   |
| 2026-05-27 | `deepseek-r1-tools:32b` | Locally installed as `deepseek-r1-tools:32b-128k`. Family=qwen2, Q8_0, 32.8B params, ~34 GB on disk                            | `ollama show deepseek-r1-tools:32b-128k`          |
| 2026-05-27 | `qwen3-coder-next-80b`  | Ollama library — Q4 quantization, 80B MoE model                                                                                | <https://ollama.com/library/qwen3-coder-next-80b> |
| 2026-05-27 | `qwen3-coder-30b-a3b`   | Ollama library — MoE coding model, 3B active params                                                                            | <https://ollama.com/library/qwen3-coder-30b-a3b>  |
| 2026-05-27 | `qwen3.6-35b`           | Ollama library — agentic coding model                                                                                          | <https://ollama.com/library/qwen3.6>              |
| 2026-06-13 | `qwen2.5:32b`           | Ollama library — replacement architect model, dense 32B at Q4_K_M (~20 GB)                                                      | <https://ollama.com/library/qwen2.5/tags/32b>     |
| 2026-05-27 | `qwen3.5-27b`           | Ollama library — general/writing model                                                                                         | <https://ollama.com/library/qwen3.5>              |
| 2026-05-27 | `qwen3:14b`             | Ollama library — solo coding for 16/32GB profiles                                                                              | <https://ollama.com/library/qwen3>                |
| 2026-05-27 | `qwen3:4b`              | Ollama library — planning/routing/fast tasks                                                                                   | <https://ollama.com/library/qwen3>                |
| 2026-05-27 | `qwen2.5-coder:7b`      | Ollama library — primary coding for 16GB profiles                                                                              | <https://ollama.com/library/qwen2.5-coder>        |
| 2026-05-27 | `qwen2.5-coder:1.5b`    | Ollama library — FIM autocomplete                                                                                              | <https://ollama.com/library/qwen2.5-coder>        |
| 2026-05-27 | `gemma4:31b`            | Ollama library — Google general model                                                                                          | <https://ollama.com/library/gemma4>               |
| 2026-05-27 | `codestral:22b`         | Ollama library — Mistral code model for diff/apply                                                                             | <https://ollama.com/library/codestral>            |
| 2026-05-27 | `nomic-embed-text`      | Ollama library — embedding model for RAG/semantic search                                                                       | <https://ollama.com/library/nomic-embed-text>     |

## Profile Config Sources

| Date       | Source                                    | What was verified                                                  |
| ---------- | ----------------------------------------- | ------------------------------------------------------------------ |
| 2026-05-27 | `ai/profiles/*/models.sh`               | All 5 profile model definitions audited against downstream configs |
| 2026-05-27 | `ai/profiles/*/opencode/opencode.jsonc` | OpenCode agent model assignments verified                          |
| 2026-05-27 | `ai/profiles/*/continue/config.yaml`    | Continue role assignments verified                                 |
| 2026-05-27 | `ai/profiles/*/ollama/config.json`      | Ollama model lists and aliases verified                            |
| 2026-05-27 | `ai/profiles/*/grok/grok.json`          | Grok CLI model lists verified                                      |
| 2026-05-27 | `ai/profiles/*/crush/crush.json`        | Crush model lists verified                                         |
| 2026-05-27 | `ai/profiles/*/gemini/settings.json`    | Gemini model lists verified                                        |
| 2026-05-27 | `ai/profiles/*/claude/settings.json`    | Claude Code model lists verified                                   |
| 2026-05-27 | `ai/profiles/*/cursor/settings.jsonc`   | Cursor model references verified                                   |

## Re-check Procedure

To re-verify model availability and naming:

```shell
# Check if a model tag exists on Ollama
ollama pull <model>:<tag>     # will error if tag doesn't exist

# List locally installed models
ollama list

# Show model details
ollama show <model>:<tag>

# Search Ollama library (web)
# Visit: https://ollama.com/search?q=<model-name>
# Or: https://ollama.com/library/<model-name>/tags
```
