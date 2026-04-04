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

| Model          | Command                           | Description          |
| -------------- | --------------------------------- | -------------------- |
| Llama 3.2      | `ollama pull llama3.2`            | General purpose, 8B  |
| Qwen 3 Coder   | `ollama pull qwen3.2-coder:7b`    | Code-focused, 7B     |
| DeepSeek Coder | `ollama pull deepseek-coder:6.7b` | Code generation      |
| Phi-4          | `ollama pull phi4`                | Microsoft, efficient |
| Gemma 3        | `ollama pull gemma3:12b`          | Google, 12B          |
| GLM-4 Flash    | `ollama pull glm-4-flash`         | Chinese, fast        |
| Codestral      | `ollama pull codestral:22b`       | Mistral code model   |
| Qwen 3         | `ollama pull qwen3:30b-a3b`       | Large, reasoning     |

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
