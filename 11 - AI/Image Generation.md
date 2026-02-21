---
tags: [ai, image-generation, stable-diffusion]
---

# Image Generation

Tools for generating images locally using models like Stable Diffusion.

## <img src="https://github.com/AUTOMATIC1111.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Automatic1111 (Stable Diffusion WebUI)

[Stable Diffusion WebUI](https://github.com/AUTOMATIC1111/stable-diffusion-webui) is the most popular browser interface for Stable Diffusion.

**Prerequisites for macOS (Apple Silicon):**

```shell
brew install cmake protobuf rust python@3.10 git wget
```

**Installation:**

```shell
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui
./webui.sh
```

## <img src="https://github.com/Comfy-Org.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> ComfyUI

[ComfyUI](https://github.com/Comfy-Org/ComfyUI) is a powerful and modular node-based GUI for Stable Diffusion.

**Installation:**

```shell
git clone https://github.com/Comfy-Org/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt
python main.py
```

## <img src="https://github.com/liuliu.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> Draw Things

[Draw Things](https://drawthings.ai/) is a native macOS/iOS app for running Stable Diffusion locally. Highly optimized for Apple Silicon.

- Available on the Mac App Store.

## Configuration

No basic configuration required.

## Start / Usage

```shell
cd stable-diffusion-webui && ./webui.sh
cd ComfyUI && python main.py
```

Draw Things: Start: Open the app from Applications.
