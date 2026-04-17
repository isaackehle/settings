---
tags: [ai, frameworks, libraries, ml, python]
---

# <img src="https://github.com/pytorch.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> PyTorch

Standard machine learning framework. Supports Metal Performance Shaders (MPS) for GPU acceleration on macOS Apple Silicon.

## Installation

```shell
pip install torch torchvision torchaudio
```

## Verify

```shell
python -c "import torch; print(torch.__version__)"
python -c "import torch; print(torch.backends.mps.is_available())"
```

## References

- [PyTorch](https://pytorch.org/)
- [PyTorch Docs](https://pytorch.org/docs/)
- [MPS Backend (Apple Silicon)](https://pytorch.org/docs/stable/notes/mps.html)
