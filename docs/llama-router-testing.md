# llama-router Testing Guide

Verification commands for the llama-server router mode running on port 10000.

## 1. Router is alive

```shell
# List available models
curl -s http://127.0.0.1:10000/v1/models | jq '.data[].id'
```

Expected: 9 models — 3 named presets + 6 auto-discovered from filenames.

## 2. Chat completions (per model)

### Fast model (loads instantly, ~2.5 GB)

```shell
curl -s http://127.0.0.1:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-4b-it",
    "messages": [{"role": "user", "content": "Say hello in one sentence."}],
    "temperature": 0.7
  }' | jq '.choices[0].message.content'
```

### Coding model (cold-load ~5 s, 25 GB)

```shell
curl -s http://127.0.0.1:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "qwen3-coder-30b",
    "messages": [{"role": "user", "content": "Write a fibonacci function in Python."}],
    "temperature": 0.7
  }' | jq '.choices[0].message.content'
```

### Reasoning model (cold-load ~5 s, 18 GB)

```shell
curl -s http://127.0.0.1:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "deepseek-r1-32b",
    "messages": [{"role": "user", "content": "What is 42 * 37?"}],
    "temperature": 0.6
  }' | jq '.choices[0].message.content'
```

## 3. LaunchAgent health

```shell
# Should show PID and exit code 0
launchctl list | grep llama-router

# Live output log
tail -f ~/Library/Logs/llama-router/llama-router.out.log

# Error log (if something went wrong)
tail -f ~/Library/Logs/llama-router/llama-router.err.log
```

## 4. Restart cycle

```shell
# Stop the router
launchctl bootout gui/$(id -u)/org.kehle.llama-router

# Start it again
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/org.kehle.llama-router.plist

# Confirm it's back
sleep 2 && curl -s http://127.0.0.1:10000/v1/models | jq '.data | length'
```

## 5. Quick smoke test (one-liner)

```shell
curl -s http://127.0.0.1:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3-4b-it","messages":[{"role":"user","content":"Hi"}]}' \
  | jq -r '.choices[0].message.content'
```

Should respond in under a second (4B is always the fastest to load).
