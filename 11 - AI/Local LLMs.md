---
tags: [ai, llm, local]
---

# Local LLMs

Running Large Language Models locally ensures privacy, zero subscription costs, and offline availability.

## <img src="https://github.com/ollama.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Ollama

[Ollama](https://ollama.com/) is the easiest way to get up and running with large language models locally.

```shell
brew install ollama
```

**Usage:**

```shell
# Start the server (if not running as a service)
ollama serve

# Run a model (downloads it if not present)
ollama run llama3
ollama run mistral
```

## <img src="https://github.com/lmstudio-ai.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> LM Studio

[LM Studio](https://lmstudio.ai/) provides a clean GUI to discover, download, and run local LLMs. It also provides a local server that mimics the OpenAI API.

```shell
brew install --cask lm-studio
```

## <img src="https://github.com/nomic-ai.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> GPT4All

[GPT4All](https://www.nomic.ai/gpt4all) is a free-to-use, locally running, privacy-aware chatbot. No GPU or internet required.

```shell
brew install --cask gpt4all
```

## <img src="https://github.com/vllm-project.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> vLLM

[vLLM](https://github.com/vllm-project/vllm) is a high-throughput and memory-efficient LLM serving engine. Best for production-like local serving if you have a powerful GPU.

```shell
pip install vllm
```

## <img src="https://github.com/ggml-org.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Llama.cpp

[Llama.cpp](https://github.com/ggml-org/llama.cpp) allows inference of LLaMA models in pure C/C++. Highly optimized for Apple Silicon (Metal).

```shell
brew install llama.cpp
```
