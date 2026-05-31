#!/bin/zsh
# ai/runtimes/test-models.sh — Smoke-test installed Ollama models
# Usage: test-models.sh [model1 model2 ...]
# Defaults to testing OLLAMA_SMOKE_MODELS from ~/.env.local, else common coding models

set -euo pipefail
source "$(dirname "$0")/helpers.sh"

ollama_is_running || fail "Ollama is not running. Start it first."

# Default smoke models (high-priority local models from May 2026)
DEFAULT_SMOKE_MODELS=(
    "qwen3-coder-30b-a3b:q6-8k"
    "qwen3-coder-next-80b:q4-16k"
    "qwen3.6-35b:q4-8k"
    "qwen3.5-27b:q5-8k"
    "deepseek-r1-tools:32b-128k"
    "qwen2.5-coder:1.5b"
    "codestral:22b-32k"
    "gemma4:31b-8k"
)

# Allow override from env
SMOKE_MODELS=(${OLLAMA_SMOKE_MODELS[@]:-"${DEFAULT_SMOKE_MODELS[@]}"})
[ -n "${1:-}" ] && SMOKE_MODELS=("$@")

PROMPT="Why is the sky blue? Answer in one sentence."
FAILED=()

for model in "${SMOKE_MODELS[@]}"; do
    echo "Testing: $model"
    if ! ollama list | awk '{print $1}' | grep -q "^${model}$"; then
        echo "  SKIP — not installed"
        continue
    fi

    result=$(ollama run "$model" "$PROMPT" 2>/dev/null | head -c 100)
    if [ -n "$result" ] && [ ${#result} -gt 5 ]; then
        echo "  OK — ${#result} chars returned"
    else
        echo "  FAIL — no response"
        FAILED+=("$model")
    fi
done

echo ""
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "All tested models passed."
    exit 0
else
    echo "Failed models: ${FAILED[@]}"
    exit 1
fi
