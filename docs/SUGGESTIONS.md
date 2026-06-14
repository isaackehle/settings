# Tooling Suggestions

Tools and improvements to consider adding to the setup. Pick what interests you.

## High-Impact (strongly recommended)

### 1. MLX Model Variants (Apple Silicon speed boost)

All major models (Qwen3.5, Qwen3.6, Gemma 4) now have MLX tags on Ollama
— 2-3x faster on M-series Macs for inference speed.

```shell
ollama pull qwen3.5:27b-mlx     # 17 GB, ~2x faster than Q4_0
ollama pull qwen2.5:32b-mlx     # 22 GB
ollama pull gemma4:31b-mlx      # 20 GB
```

Trade-off: slightly larger on disk than equivalent Q4_K_M quants.

### 2. Qwen3.5:4b for Planning/Fast Tasks

Replace `qwen3:4b` with `qwen3.5:4b` for planning/routing. Same size (~3.4 GB)
but adds vision support, 256K context, and tool calling. The `qwen3:4b` model
is from an older architecture.

```shell
ollama pull qwen3.5:4b
```

### 3. Llama Swap — Zero-Overhead Model Aliasing

If context-window variants via `ollama create` become unwieldy, `llama-swap`
is a ~15 MB Go binary that does intelligent model aliasing and load balancing:

```shell
brew install llama-swap
```

```yaml
# ~/.config/llama-swap/config.yaml
models:
  coder-big:
    cmd: echo "passthrough to ollama"
    aliases: [qwen3-coder-next-80b, big-code]
  coder-fast:
    cmd: echo "passthrough to ollama"
    aliases: [qwen3-coder-30b-a3b, medium-code]
```

No Python runtime, no pip, no Docker, no Postgres. Web UI at `:8080/ui`.

## Medium-Impact (nice to have)

### 4. Ollama GPU Layer Tuning

For M-series Macs, Ollama auto-detects GPU layers. For fine-tuning which models
stay in GPU memory vs spill to CPU:

```shell
# Per-model GPU layers override
ollama run qwen3-coder-30b-a3b:q5 --gpu-layers 32

# Global setting
# ~/.ollama/config.json
{ "gpu_layers": 42 }
```

### 5. Continue.dev Custom Slash Commands

Continue supports custom `/` commands. Useful for common workflows:

```yaml
# ~/.continue/config.yaml
slashCommands:
  - name: commit
    description: Generate a conventional commit message
    prompt: |
      Generate a concise conventional commit message for the current git diff.
      Format: type(scope): subject
  - name: pr
    description: Generate a PR description
    prompt: |
      Write a pull request description for the current branch. Include:
      - What changed
      - Why
      - Testing notes
```

### 6. Ollama Benchmark Script

Quick script to compare model speed on current hardware:

```shell
#!/bin/bash
MODELS=("qwen3:14b" "qwen3-coder-30b-a3b:q5" "qwen3-coder-next-80b:q4")
for m in "${MODELS[@]}"; do
  echo "=== $m ==="
  ollama run "$m" "Write a Python function to reverse a linked list. Only output code, no explanation." --verbose 2>&1 | grep "eval"
done
```

## Low-Impact (explore if curious)

### 7. Gemma 4:e4b as Alternative Small Model

Google's Gemma 4 edge model (4.5B effective) with vision + audio. Larger
on disk than qwen3.5:4b but strong reasoning:

```shell
ollama pull gemma4:e4b   # 9.6 GB MLX
```

### 8. Continue.dev Reranker for Better Code Search

Add a reranker model to Continue for better @codebase results:

```yaml
# models section of config.yaml
- name: Code Reranker
  provider: ollama
  model: qwen3:0.6b      # or any small model
  roles: [rerank]
```

### 9. Ollama Modelfile Templates

Standardize context-window variant creation:

```shell
# Save as ~/.ollama/templates/32k.Modelfile
FROM %MODEL%
PARAMETER num_ctx 32768
PARAMETER temperature 0.2

# Usage
MODEL=qwen3-coder-30b-a3b:q5 envsubst < ~/.ollama/templates/32k.Modelfile > /tmp/mf
ollama create qwen3-coder-30b-a3b:q5-32k -f /tmp/mf
```

### 10. Ollama API Key for Security

Even though Ollama doesn't validate API keys, set one for defense-in-depth:

```shell
# ~/.ollama/config.json
{ "api_key": "local-only-please" }
```

Then tools use `ollama:local-only-please` as the key.
