# Local LLM Quality Issues — Diagnosis & Fixes

## Root Cause Found

**Critical Issue:** `qwen3.6-35b:opus4.6` (your Opus model) is registered with a **minimal template** (`TEMPLATE {{ .Prompt }}`) that **does not support tool-calling**. When this model tries to make tool calls, it produces garbled output like "Mo" because it's outputting tool-call tokens that the system doesn't understand.

### Template Status Check

| Model | Template | Tool Support | Status |
|-------|----------|--------------|--------|
| `qwen3-coder-30b-a3b:q6` | Full Jinja2 (20+ lines) | ✅ Full | Working |
| `qwen3-14b:sonnet4.5` | Full Jinja2 (20+ lines) | ✅ Full | Working |
| `qwen3.5:4b` | `RENDERER qwen3.5` / `PARSER qwen3.5` | ✅ Architecture-native | Working |
| `qwen3.6-35b:opus4.6` | `TEMPLATE {{ .Prompt }}` | ❌ **None** | **BROKEN** |

---

## Immediate Fix: Re-register Opus Model

The Opus model needs to be re-registered with an HF reference to preserve the chat template:

```shell
# 1. Remove the broken model
ollama rm qwen3.6-35b:opus4.6

# 2. Re-register with HF reference (preserves chat template)
cat > /tmp/opus.Modelfile << 'EOF'
FROM hf.co/hesamation/Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled-GGUF:Qwen3.6-35B-A3B-Claude-4.6-Opus-Reasoning-Distilled.Q4_K_M.gguf
PARAMETER num_ctx 262144
PARAMETER temperature 0.6
EOF
ollama create qwen3.6-35b:opus4.6 -f /tmp/opus.Modelfile

# 3. Recreate context variants
for ctx in 8k 32k 128k 256k; do
  num_ctx=$(echo "$ctx" | sed 's/k/000/')
  cat > /tmp/opus-${ctx}.Modelfile << EOF
FROM qwen3.6-35b:opus4.6
PARAMETER num_ctx ${num_ctx}
PARAMETER temperature 0.6
EOF
  ollama create qwen3.6-35b:opus4.6-${ctx} -f /tmp/opus-${ctx}.Modelfile
done

# 4. Verify the fix
ollama show qwen3.6-35b:opus4.6 --modelfile | head -30
```

---

## Secondary Fix: Planning Agent Configuration

I've updated the planning agent to prevent it from trying to use MCP tools it can't handle:

### Changes Made:

1. **Added tool filters to `opencode.jsonc`:**
   ```jsonc
   "plan": {
     "tools": {
       "home-assistant_*": false,
       "apple-reminders_*": false,
       "one-search_*": false,
       "weather_*": false
     }
   }
   ```

2. **Updated `plan.md` prompt:**
   - Changed `webfetch: allow` → `webfetch: deny`
   - Added clear instruction: "You are a PLANNING agent only. Do NOT execute tools or make external calls."

### Why This Helps:
The 4B planning model was trying to execute complex tool calls (web search) that it couldn't handle. By filtering out MCP tools and clarifying the agent's role, it will focus on planning instead of attempting tool execution.

---

## Additional Issues to Check

### 1. Context Window Exhaustion ("Mo" output)

If you're seeing truncated output, it could be:
- Context window too small for the task
- KV cache memory exhausted
- Model running out of tokens mid-generation

**Check context windows:**
```shell
ollama show qwen3-coder-30b-a3b:q6 --modelfile | grep num_ctx
ollama show qwen3.6-35b:opus4.6 --modelfile | grep num_ctx
```

### 2. Ollama Version Compatibility

✅ Ollama is at version 0.30.0 (minimum required for qwen35 architecture)

### 3. Model Loading Issues

Verify all models are loaded correctly:
```shell
ollama list | grep -E "(qwen3-coder|qwen3.6|qwen3.5:4b)"
```

---

## Verification Steps

After applying the fix:

```shell
# Test Opus model with tool-calling
ollama run qwen3.6-35b:opus4.6 "Search for the latest Python 3.12 features"

# Test planning model (should produce concise plan, not tool calls)
ollama run qwen3.5:4b "Plan the steps to set up a new Python project"

# Test primary coder (should work fine)
ollama run qwen3-coder-30b-a3b:q6 "Write a function to calculate fibonacci numbers"
```

---

## Long-term Recommendations

1. **Always use `FROM hf.co/...` for model registration** — preserves chat templates
2. **Add validation to install scripts** — check template quality after registration
3. **Monitor tool-calling success rate** — track which models work for agentic tasks
4. **Consider replacing Opus model** — if re-registration doesn't fix quality, try a different distill

---

## Files Modified

- `ai/profiles/macbook-m5-64gb/opencode/opencode.jsonc` — Added tool filters for planning agent
- `ai/opencode/agents/plan.md` — Updated prompt to clarify planning-only role
- `docs/local-llm-quality-diagnosis.md` — Created diagnostic document

---

_Generated: 2026-06-09_
_Profile: macbook-m5-64gb_
_Issue: Local LLM quality degradation_
