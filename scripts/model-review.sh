#!/usr/bin/env bash
# model-review.sh — monthly model review guide
# Shows current models by role with targeted benchmark sources for each.
# Run via: model-review
# Records a timestamp so the shell can remind you when it's been too long.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ai/models-last-checked"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              AI MODEL REVIEW — $(date '+%Y-%m-%d')                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"

# ---------------------------------------------------------------------------
# Coding / agentic (primary workhorse)
# ---------------------------------------------------------------------------
echo ""
echo "── CODING / AGENTIC ────────────────────────────────────────────────"
echo ""
echo "  Current:"
echo "    64GB  qwen3-coder-30b-32k:q6   (Q6 quant, ~26 GB loaded)"
echo "    48GB  qwen3-coder-30b-32k:q5   (Q5 quant, ~21 GB loaded)"
echo "    16GB  qwen3:14b                (stock Ollama Q4_K_M)"
echo ""
echo "  What to look for:"
echo "    → A model that scores higher on SWE-bench Verified at similar RAM"
echo "    → Improved tool-call reliability (structured output, no hallucinated calls)"
echo "    → Context window ≥32K without quant penalty"
echo ""
echo "  Check:"
echo "    SWE-bench Verified     https://www.swebench.com"
echo "    LiveCodeBench          https://livecodebench.github.io/leaderboard.html"
echo "    OpenCode benchmark     https://opencode.ai"
echo "    Ollama library         https://ollama.com/library  (filter: code)"

# ---------------------------------------------------------------------------
# Reasoning / tool calls
# ---------------------------------------------------------------------------
echo ""
echo "── REASONING / TOOL CALLS ──────────────────────────────────────────"
echo ""
echo "  Current:"
echo "    64GB  deepseek-r1-tools:32b    (mfdoom fork with tool-calling)"
echo "    48GB  deepseek-r1-tools:14b"
echo "    16GB  deepseek-r1-tools:8b"
echo ""
echo "  What to look for:"
echo "    → A thinking model that also reliably emits JSON tool calls"
echo "    → Better than mfdoom fork? Check for newer fine-tunes of R1/Qwen3"
echo "    → Qwen3-30B-A3B already has native thinking — worth testing as replacement"
echo ""
echo "  Check:"
echo "    r/LocalLLaMA (tool calling thread)  https://www.reddit.com/r/LocalLLaMA"
echo "    HuggingFace trending                https://huggingface.co/models?sort=trending&pipeline_tag=text-generation"

# ---------------------------------------------------------------------------
# Research / long context
# ---------------------------------------------------------------------------
echo ""
echo "── RESEARCH ────────────────────────────────────────────────────────"
echo ""
echo "  Current:"
echo "    64GB  qwen3-32b:q5             (~22 GB)"
echo "    48GB  qwen3-14b:q5             (~12 GB)"
echo "    16GB  qwen3:14b                (shared with coding role)"
echo ""
echo "  What to look for:"
echo "    → Better instruction-following and summarisation at similar size"
echo "    → Improved multilingual or domain-specific reasoning"
echo ""
echo "  Check:"
echo "    Open LLM Leaderboard    https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard"
echo "    Chatbot Arena           https://lmarena.ai"

# ---------------------------------------------------------------------------
# Writing / general
# ---------------------------------------------------------------------------
echo ""
echo "── WRITING / GENERAL ───────────────────────────────────────────────"
echo ""
echo "  Current:"
echo "    All   qwen3.5:27b              (~20 GB, #1 on OpenCode IndexNow)"
echo ""
echo "  What to look for:"
echo "    → Higher Chatbot Arena ELO with similar RAM footprint"
echo "    → Better prose quality, lower repetition"
echo ""
echo "  Check:"
echo "    Chatbot Arena           https://lmarena.ai"
echo "    Simon Willison's blog   https://simonwillison.net"

# ---------------------------------------------------------------------------
# Planning / fast
# ---------------------------------------------------------------------------
echo ""
echo "── PLANNING / FAST ─────────────────────────────────────────────────"
echo ""
echo "  Current:"
echo "    64GB  qwen3-4b:q8              (~5 GB)"
echo "    48GB  qwen3-4b:q4              (~3 GB)"
echo "    16GB  qwen3-4b:q4"
echo ""
echo "  What to look for:"
echo "    → Faster time-to-first-token at same quality"
echo "    → Better instruction-following for structured routing/planning tasks"
echo ""
echo "  Check:"
echo "    Ollama library (sort: newest, small models)  https://ollama.com/library"

# ---------------------------------------------------------------------------
# Autocomplete
# ---------------------------------------------------------------------------
echo ""
echo "── AUTOCOMPLETE ────────────────────────────────────────────────────"
echo ""
echo "  Current:"
echo "    All   qwen2.5-coder:1.5b       (default, ~1 GB)"
echo "    All   qwen2.5-coder:7b         (quality fallback, ~5 GB)"
echo ""
echo "  What to look for:"
echo "    → Lower latency at 1-2B size (time-to-first-token < 200ms)"
echo "    → FIM (fill-in-middle) support confirmed"
echo "    → qwen2.5-coder still the benchmark leader at 1.5B/7B?"
echo ""
echo "  Check:"
echo "    HumanEval / EvalPlus    https://evalplus.github.io/leaderboard.html"
echo "    r/LocalLLaMA            https://www.reddit.com/r/LocalLLaMA"

# ---------------------------------------------------------------------------
# New releases to watch
# ---------------------------------------------------------------------------
echo ""
echo "── NEW RELEASES TO WATCH ───────────────────────────────────────────"
echo ""
echo "  Ollama newest            https://ollama.com/library?sort=newest"
echo "  HuggingFace trending     https://huggingface.co/models?sort=trending&pipeline_tag=text-generation"
echo "  Unsloth blog (quants)    https://unsloth.ai/blog"
echo "  Simon Willison           https://simonwillison.net"

# ---------------------------------------------------------------------------
# Stamp
# ---------------------------------------------------------------------------
echo ""
mkdir -p "$(dirname "$STAMP_FILE")"
date +%s > "$STAMP_FILE"
echo "────────────────────────────────────────────────────────────────────"
echo "  ✓ Marked as reviewed: $(date '+%Y-%m-%d')"
echo "    Shell will remind you again in 30 days."
echo ""

# Offer to replace any models
echo ""
read -p "Replace any models? (y/n): " replace_models
if [[ "$replace_models" == "y" || "$replace_models" == "Y" ]]; then
    "$SCRIPT_DIR/swap-model.sh"
fi
echo ""
