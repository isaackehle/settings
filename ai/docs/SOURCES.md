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
| 2026-07-16 | `deepseek-r1-distill-qwen-32b` (LM Studio) | `curl http://127.0.0.1:1234/api/v0/models` — no `capabilities` key present, confirming no tool_use support. Publisher `bartowski`, plain base distill | `curl http://127.0.0.1:1234/api/v0/models` |
| 2026-07-16 | `gpt-oss-20b-hermes_agent-tool-finetune_gguf` (LM Studio) | `curl http://127.0.0.1:1234/api/v0/models` — `"capabilities": ["tool_use"]` confirmed, then smoke-tested with a real `get_weather` tool schema and got back a correct `tool_calls` response | `curl http://127.0.0.1:1234/api/v0/models` |
| 2026-07-16 | `qwen_qwen3-30b-a3b`, `qwen/qwen3.6-35b-a3b`, `mistralai/codestral-22b-v0.1`, `qwen/qwen3.5-9b`, `qwen2.5-3b-instruct`, `google/gemma-4-e4b`, `google/gemma-4-26b-a4b-qat`, `text-embedding-nomic-embed-text-v1.5` (LM Studio) | `curl http://127.0.0.1:1234/v1/models` — confirmed present/downloadable on `discovery`'s LM Studio before wiring into `engines.sh` role map | `curl http://127.0.0.1:1234/v1/models` |
| 2026-07-16 | `qwen/qwen3-coder-next` (80B, LM Studio) | NOT confirmed — absent from `/v1/models` on `discovery` as of this date. `coder`/`heavy` roles fell back to `qwen_qwen3-30b-a3b` until downloaded | `lms ls` (re-check after download) |
| 2026-07-16 | `hermes-qwen3.5-35b-a3b-Q6_K.gguf` (LM Studio) | NOT confirmed — referenced in `profiles/discovery/hermes/config.yaml` as an upgrade over `ornith-1.0-35b`, but absent from `lms ls` output on `discovery` as of this date | `lms ls` (re-check after download) |

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

## Verification Methodology (standing instruction)

How to determine "the best model for a role" when wiring a new engine or
tool config. This is the method actually used for the 2026-07-16 LM Studio
role-map decisions above — follow it for future engine/model additions
rather than trusting a model's name, an old config comment, or a website
listing on its own.

1. **Never wire a model id into a config from memory or a name match.** A
   name like `deepseek-r1-distill-qwen-32b` looking similar to
   `deepseek-r1-tools:32b` tells you nothing about whether it actually
   supports tool-calling — verify each capability independently.
2. **Ask the engine itself what it has, and what it can do.** Local
   inference engines expose this directly — prefer it over a web search,
   since it's ground truth for *this machine right now*, not the model's
   general reputation:
   - Ollama: `ollama show <model>:<tag>` — the `Capabilities` section lists
     `tools` / `thinking` / `completion` explicitly. `ollama list` for
     what's installed.
   - LM Studio: `curl http://127.0.0.1:1234/api/v0/models` — LM Studio's
     *extended* API (not the plain OpenAI-compatible `/v1/models`) returns a
     `capabilities` array per model; look for `"tool_use"`. Models without
     tool support simply omit the `capabilities` key rather than listing an
     empty one. Plain `/v1/models` only gives you the id, not capabilities —
     use `/api/v0/models` when the question is "can this model call tools."
   - `lms ls` (LM Studio CLI) — shows what's actually **downloaded to disk**
     vs. what a config file merely references. A model referenced in a
     `.yaml`/`.json` config is not necessarily present locally; `lms ls`
     is the check for "is this real right now."
   - `ollama ps` — confirms whether a model is currently loaded in memory
     (relevant when checking if a config change needs a reload to take
     effect vs. picking up a stale cached instance).
3. **When a model's origin matters** (e.g. "is this the tool-calling fork or
   the base model?"), check the pull source, not just the local alias name.
   For Ollama, `remote_pull` in `models.json` (e.g. `deepseek-r1-tools:32b`
   → `MFDoom/deepseek-r1-tool-calling:32b`) tells you it's a community
   fine-tune, not an official DeepSeek release — that's the difference
   between "has tool-calling" and "doesn't."
4. **Smoke-test the actual capability being relied on, not just that the
   model responds.** A 200 OK on a plain chat completion does not confirm
   tool-calling works — send a real `tools` array in the request and check
   the response actually contains a `tool_calls` entry with correct
   arguments (see the `gpt-oss-20b-hermes_agent-tool-finetune_gguf` row
   above — a real `tool_calls` response, not just a 200, is what closed
   that decision).
5. **If a model referenced in a config isn't verifiable this way** — not
   downloaded, engine not running, capability unconfirmed — do not guess.
   Leave the role unmapped with a dated TODO comment naming exactly what to
   verify once it's available, rather than wiring in an assumption. See the
   `hermes-qwen3.5-35b-a3b-Q6_K.gguf` and `qwen/qwen3-coder-next` rows above
   for the pattern.
6. **Log the finding here (date + exact command as the "source") and in
   `MODELS.md`'s Naming Decisions / model-identity notes** so the next
   engine or profile rollout doesn't have to re-derive it from scratch.

This differs from the original `ollama.com`-browsing methodology below
(still valid for checking what tags exist upstream before pulling something
new) — the local-API method is for verifying what's *already installed and
capable*, a stronger and more current source of truth than a library page
when the question is about *this machine's* current state.

## Re-check Procedure

To re-verify model availability and naming:

```shell
# Check if a model tag exists on Ollama
ollama pull <model>:<tag>     # will error if tag doesn't exist

# List locally installed models
ollama list

# Show model details (capabilities, context, params)
ollama show <model>:<tag>

# Confirm what's currently loaded in memory
ollama ps

# Search Ollama library (web)
# Visit: https://ollama.com/search?q=<model-name>
# Or: https://ollama.com/library/<model-name>/tags
```

```shell
# LM Studio: what's downloaded to disk (source of truth for "is this real")
lms ls

# LM Studio: plain OpenAI-compatible list (ids only, no capabilities)
curl -s http://127.0.0.1:1234/v1/models

# LM Studio: extended API with per-model capabilities (tool_use, etc.)
curl -s http://127.0.0.1:1234/api/v0/models

# LM Studio: smoke-test an actual tool call (not just a chat completion)
curl -s http://127.0.0.1:1234/v1/chat/completions -H "content-type: application/json" -d '{
  "model": "<model-id>", "max_tokens": 100,
  "messages": [{"role":"user","content":"<prompt that should trigger the tool>"}],
  "tools": [{"type":"function","function":{"name":"<tool_name>","description":"...","parameters":{...}}}]
}'
# Check the response for a populated tool_calls array, not just HTTP 200.
```
