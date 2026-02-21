---
tags: [ai, frameworks, python]
---

# AI Frameworks & Libraries

Essential libraries for building AI applications and working with models.

## <img src="https://github.com/huggingface.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Hugging Face CLI

The [Hugging Face CLI](https://huggingface.co/docs/huggingface_hub/guides/cli) is essential for downloading models and datasets.

```shell
pip install -U "huggingface_hub[cli]"
```

**Usage:**

```shell
huggingface-cli login
huggingface-cli download meta-llama/Meta-Llama-3-8B
```

## <img src="https://github.com/langchain-ai.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> LangChain

[LangChain](https://www.langchain.com/) is a framework for developing applications powered by language models.

```shell
pip install langchain
```

## <img src="https://github.com/run-llama.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> LlamaIndex

[LlamaIndex](https://www.llamaindex.ai/) is a data framework for connecting custom data sources to large language models.

```shell
pip install llama-index
```

## <img src="https://github.com/pytorch.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> PyTorch

[PyTorch](https://pytorch.org/) is the standard machine learning framework. For macOS, it supports Metal Performance Shaders (MPS) for GPU acceleration.

```shell
pip install torch torchvision torchaudio
```
