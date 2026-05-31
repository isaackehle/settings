# Ollama → oMLX Model Mapping — macmini-m2-16gb

Research output from the oMLX onboarding workstream ([[WORKSTREAM_2026-05-28]]).
Maps every model in `models.sh` to an MLX-format equivalent for use with oMLX.

---

## Model Equivalents

| Role           | Ollama Model           | Size    | MLX Equivalent                                     | MLX Size | Source        |
| -------------- | ---------------------- | ------- | -------------------------------------------------- | -------- | ------------- |
| Primary coding | `qwen2.5-coder:7b`     | ~5 GB   | `mlx-community/Qwen2.5-Coder-7B-Instruct-4bit`     | 4.28 GB  | mlx-community |
| Code apply     | `codestral:22b`        | ~14 GB  | `mlx-community/Codestral-22B-v0.1-4bit`            | 12.5 GB  | mlx-community |
| Solo coding    | `qwen3:14b`            | ~11 GB  | `Qwen/Qwen3-14B-MLX-4bit`                          | 7.75 GB  | Official Qwen |
| Reasoning      | `deepseek-r1-tools:8b` | ~5 GB   | `mlx-community/DeepSeek-R1-Distill-Qwen-7B-4bit`   | 4.28 GB  | mlx-community |
| Planning       | `qwen3:4b`             | ~5 GB   | `Qwen/Qwen3-4B-MLX-4bit`                           | 2.14 GB  | Official Qwen |
| Autocomplete   | `qwen2.5-coder:1.5b`   | ~1 GB   | `mlx-community/Qwen2.5-Coder-1.5B-Instruct-4bit`   | 869 MB   | mlx-community |
| Embeddings     | `nomic-embed-text`     | ~0.3 GB | `mlx-community/nomicai-modernbert-embed-base-8bit` | 160 MB   | Nomic AI      |

## Key Differences

| Aspect             | Ollama                               | oMLX                                   |
| ------------------ | ------------------------------------ | -------------------------------------- |
| API port           | `:11434`                             | `:8000`                                |
| API format         | OpenAI-compatible (`/v1`)            | OpenAI + Anthropic (`/v1/messages`)    |
| Context variants   | Separate `ollama create` aliases     | Handled per-request via `max_tokens`   |
| Model format       | GGUF                                 | MLX (safetensors)                      |
| Model pull         | `ollama pull <name>`                 | `huggingface-cli download <hf-path>`   |
| Embedding provider | `provider: ollama` (Continue)        | `provider: openai` (OpenAI-compatible) |
| Remote models      | Community namespace + local alias    | Direct HuggingFace download            |
| Quant variants     | Built into model name (`:q8`, `:q5`) | Download separate HF repo per quant    |
| Tool calling       | Built-in per model                   | Via mlx-lm built-in parsers            |

## Memory Budget (Multi-Mode, ~10 GB usable)

Co-resident set with oMLX tiered SSD KV cache:

| Model                            | RAM         | SSD Cache | Notes                    |
| -------------------------------- | ----------- | --------- | ------------------------ |
| Qwen2.5-Coder-7B-Instruct-4bit   | 4.28 GB     | —         | Always-loaded            |
| DeepSeek-R1-Distill-Qwen-7B-4bit | —           | 4.28 GB   | Swapped in for reasoning |
| Qwen3-4B-MLX-4bit                | 2.14 GB     | —         | Always-loaded            |
| Qwen2.5-Coder-1.5B-Instruct-4bit | 0.87 GB     | —         | Always-loaded            |
| ModernBERT Embed (8bit)          | 0.16 GB     | —         | Always-loaded            |
| Codestral-22B-v0.1-4bit          | —           | 12.5 GB   | On-demand only           |
| Qwen3-14B-MLX-4bit               | 7.75 GB     | —         | Solo mode only           |
| **Total RAM**                    | **7.45 GB** |           | ✓ Fits in ~10 GB budget  |

## Open Questions

See [[WORKSTREAM_2026-05-28#Open Questions]] for unresolved decisions:
3-bit vs 4-bit coding model, embedding choice, Codestral alternative, etc.

---

_Generated 2026-05-28 as part of the oMLX onboarding workstream._
