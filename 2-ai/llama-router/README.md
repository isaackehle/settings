# llama-server Router Mode — M5 Max 64GB

Configuration package for running `llama-server` in **router mode** (dynamic
model loading/switching) on the M5 Max MacBook Pro, serving an OpenAI-compatible
API that Open WebUI points at. Models live in `/usr/local/lib/llama-models`.

## Models served

| Model ID (API `model` field) | GGUF | Role |
|---|---|---|
| `deepseek-r1-32b` | `deepseek-r1-32b-ds-q4_k_m.gguf` | Reasoning |
| `qwen3-4b-it` | `qwen3-4b-it-q4_k_m.gguf` | Fast chat / default |
| `qwen3-coder-30b` | `qwen3-coder-30b-a3b-cd-ud-q6_k_xl.gguf` (Q6_K_XL) | Coding |

## Files in this directory

| File | Purpose |
|---|---|
| `models.ini` | Router preset: per-model paths, context, GPU offload, KV cache, sampling. Copy to `/usr/local/lib/llama-models/models.ini`. |
| `org.kehle.llama-router.plist` | launchd LaunchAgent — starts the router at login on macOS (the native systemd equivalent). |
| `llama-router.service` | systemd unit — for running the same router on a Linux home-lab box. |
| `build.sh` | Pulls latest llama.cpp from GitHub, rebuilds llama-server with Metal, deploys to `/usr/local/bin`. |
| `setup.sh` | Verifies llama-server, auto-detects GGUF filenames, patches `models.ini`, installs the LaunchAgent. |
| `open-webui-integration.md` | Connect Open WebUI (Colima Docker) to **three backends** — llama-server router, native Ollama, OpenRouter — plus a **Tailscale** section (remote access, cross-Mac backends, Funnel). |
| `tuning-guide.md` | M5 Max 64GB performance tuning: GPU offload, KV cache, `--models-max`, flash attention, benchmarks. |

## Quick start

```bash
cd ~/code/isaackehle/settings/2-ai/llama-router

# 1. Build llama-server from source (Metal, router support)
./build.sh

# 2. Wire everything up (patches INI, installs LaunchAgent)
./setup.sh

# 3. Verify (router listens on port 10000; 8080 is Open WebUI)
curl -s http://127.0.0.1:10000/v1/models | jq '.data[].id'
```

Then connect Open WebUI per `open-webui-integration.md`.

## Notes

- macOS uses **launchd**, not systemd. Use the `.plist`; the `.service` file is
  only for a Linux box.
- llama.cpp's router/INI format is still evolving — `build.sh` verifies your
  build supports `--models-preset`, and `tuning-guide.md` §8 covers fallbacks.
- The router defaults to `--models-max 1` (one model resident). See
  `tuning-guide.md` §4 before raising it — never co-resident the 32B + 30B-coder
  on 64 GB.
- To download new GGUFs, just save them to `/usr/local/lib/llama-models/` (no
  sudo needed — the directory is owned by your user).

## Sources

- [New in llama.cpp: Model Management (ggml-org)](https://huggingface.co/blog/ggml-org/model-management-in-llamacpp)
- [llama-server router mode walkthrough (Glukhov)](https://www.glukhov.org/llm-hosting/llama-cpp/llama-server-router-mode/)
