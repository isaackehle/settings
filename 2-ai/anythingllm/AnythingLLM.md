---
tags: [ai, llm, local, rag]
---

# AnythingLLM

Local RAG and chat UI that supports multiple LLM backends. Use Ollama as the model provider to avoid downloading models twice.

## Installation

```shell
# macOS — download the .dmg from https://anythingllm.com/download
# or via Homebrew Cask (if available)
brew install --cask anythingllm
```

## Configure Ollama as the LLM Provider

AnythingLLM connects to Ollama over its REST API — no separate model download needed.

1. Open AnythingLLM → **Settings** → **LLM Preference**
2. Select **Ollama**
3. Set base URL: `http://127.0.0.1:11434`
4. Select your model from the dropdown (lists whatever is in `ollama list`)
5. Save

For embeddings (RAG / document search):

1. **Settings** → **Embedding Preference**
2. Select **Ollama**
3. Set base URL: `http://127.0.0.1:11434`
4. Pick a small embedding model (e.g. `nomic-embed-text`)

```shell
# Pull a good embedding model if you don't have one
ollama pull nomic-embed-text
```

## Start / Usage

```shell
# Ensure Ollama is running first
brew services start ollama   # or: ollama serve

# Then launch AnythingLLM
open -a AnythingLLM
```

## References

- [AnythingLLM](https://anythingllm.com/)
- [AnythingLLM docs](https://docs.anythingllm.com/)
- [Ollama integration guide](https://docs.anythingllm.com/llm-configuration/local/ollama)
