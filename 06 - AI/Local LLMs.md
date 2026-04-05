---
tags: [ai, llm, local]
---

# Local LLMs

Running Large Language Models locally ensures privacy, zero subscription costs, and offline availability.

## <img src="https://github.com/ollama.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Ollama

[Ollama](https://ollama.com/) is the easiest way to get up and running with local LLMs.

```shell
brew install ollama
```

```shell
ollama login
```

```shell
ollama serve
```

See more: [[Ollama]]

## <img src="https://github.com/lmstudio-ai.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> LM Studio

[LM Studio](https://lmstudio.ai/) provides a GUI for discovering and running local models.

```shell
brew install --cask lm-studio
```

No basic configuration required.

Start: Open the app from Applications.

See more: [[LM Studio]]

## <img src="https://github.com/nomic-ai.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> GPT4All

[GPT4All](https://www.nomic.ai/gpt4all) is a privacy-focused local chatbot app.

```shell
brew install --cask gpt4all
```

No basic configuration required.

Start: Open the app from Applications.

See more: [[GPT4All]]

## <img src="https://github.com/vllm-project.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> vLLM

[vLLM](https://github.com/vllm-project/vllm) is a high-throughput local serving engine for model inference.

```shell
pip install vllm
```

No basic configuration required.

```shell
vllm serve llama3.2
```

See more: [[vLLM]]

## <img src="https://github.com/ggml-org.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Llama.cpp

[Llama.cpp](https://github.com/ggml-org/llama.cpp) is an Apple Silicon-optimized inference library for LLaMA-family models.

```shell
brew install llama.cpp
```

No basic configuration required.

```shell
llama --help
```

See more: [[Llama.cpp]]
