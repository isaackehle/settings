# MacBook Pro M2 32GB Models

## Installed Models

| Model | Size | Purpose |
|-------|------|---------|
| `qwen3.5:27b` | ~20 GB | Writing, general coding (#1 on IndexNow) |
| `qwen3-coder-30b-32k:q5` | ~25 GB | Primary coding (32k context) |
| `qwen3-coder-30b-220k:q5` | ~38 GB | Large context (solo only) |
| `qwen3.6-35b-32k:q5` | ~25 GB | Alternative coder |
| `deepseek-r1-tools:8b` | ~5 GB | Reasoning + tools |
| `deepseek-r1-tools:14b` | ~10 GB | Reasoning + tools (heavier) |
| `qwen3-14b:q5` | ~12 GB | Research |
| `qwen3-4b:q4` | ~3 GB | Planning |
| `qwen2.5-coder:7b` | ~5 GB | Fast code |
| `qwen2.5-coder:1.5b` | ~1 GB | Autocomplete |
| `nomic-embed-text` | ~0.3 GB | Embeddings |

## Memory Notes

- Code + think can coexist (~30 GB)
- Code + write pushes ~45 GB — nothing else large should be loaded
- Ollama evicts after 5 min idle
