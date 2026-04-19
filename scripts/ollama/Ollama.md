---
tags: [ai, llm, local]
---

# <img src="https://github.com/ollama.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Ollama

Local LLM manager for Apple Silicon that simplifies model downloads and serving.

## Installation

```shell
curl -fsSL https://ollama.com/install.sh | sh

# or

brew install ollama
```

## Configuration

```shell
ollama login
```

## Start / Usage

```shell
ollama serve
ollama run llama3.2
```

## Models

```shell
# List installed models
ollama list

# Pull a model
ollama pull <model-name>
```

### Recommended Models

See [[Models]] for the full model reference. Quick pulls:

```shell
ollama pull llama3.2
ollama pull qwen2.5-coder:7b
ollama pull qwen3.2-coder:7b
ollama pull deepseek-r1:14b
ollama pull phi4
ollama pull gemma3:12b
```

### Browse Available Models



```shell
# Search Ollama library
ollama search <query>
```

## Uninstall

### Homebrew

```shell
brew uninstall ollama
rm -rf ~/.ollama
```

### Shell script

```shell
rm -rf /Applications/Ollama.app
rm -f /usr/local/bin/ollama
pkill -x Ollama 2>/dev/null || true
```

- [Ollama](https://ollama.com/)
- [Ollama docs](https://ollama.com/docs)
