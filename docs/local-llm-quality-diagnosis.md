---
tags: [ai, ollama, troubleshooting, reference]
---

# Local LLM Quality Diagnosis — June 2026

## Symptoms Reported

1. **Planning agent (qwen3.5:4b) producing verbose, confused output**
   - Model generates "Thought:" reasoning blocks instead of concise plans
   - Fails at tool calls (web search returning irrelevant results)
   - Gets into loops trying different search queries

2. **Other models producing truncated output ("Mo")**
   - Short output as if model wanted to type something then failed
   - Suggests context window exhaustion or token generation truncation

3. **General quality issues across local models**
   - Inconsistent tool-calling behavior
   - Models not following instructions properly

---

## Root Cause Analysis

### Critical Issue: Model Registration with Bare GGUF Paths

The **template audit** in `ollama-model-registration.md` reveals that critical models are registered with bare GGUF paths, which **lose the embedded Jinja2 chat template**:

| Model                    | Registration | Template Lines     | Tool Support | Priority |
| ------------------------ | ------------ | ------------------ | ------------ | -------- |
| `qwen3-coder-30b-a3b:q6` | bare GGUF    | 6                  | **Partial**  | Critical |
| `qwen2.5:32b`    | bare GGUF    | minimal            | **None**     | High     |
| `qwen3-14b:sonnet4.5`    | bare GGUF    | 6                  | **Partial**  | High     |
| `deepseek-r1:32b`        | bare GGUF    | 10 lines, no tools | **None**     | Low      |

**Impact:** Models registered with bare GGUF paths get `TEMPLATE {{ .Prompt }}` (minimal), which means:

- Tool-calling breaks (model narrates tool calls as text instead of structured JSON)
- Chat formatting differs from the model author's intent
- The model may produce verbose reasoning instead of executing tools

### Issue 1: Planning Agent Misuse

The planning agent (`qwen3.5:4b`) is configured with:

```yaml
permission:
  bash: deny
  edit: deny
  webfetch: allow
```

But the example shows it trying to use `one-search_one_search` (an MCP tool), not webfetch. The planning agent is being used for tasks that require tool execution, but:

1. The agent prompt says "Turn goals into actionable steps" (planning only)
2. The model is too small (4B) to handle complex tool-calling workflows
3. The model lacks proper tool-calling template support

### Issue 2: Context Window Exhaustion

The "Mo" output suggests the model runs out of context tokens before completing its response. This can happen when:

- The context window is too small for the task
- The model is processing too much input (long prompts, tool results)
- KV cache memory is exhausted

### Issue 3: Ollama Version Compatibility

The `qwen35` architecture (used by Qwen 3.5 models) requires **Ollama ≥ 0.30.0**. If the server is running an older version:

- Models may fail to load properly
- Tool-calling may not work
- Output quality degrades

---

## Immediate Fixes

### 1. Re-register Critical Models with HF References

**Status: ✅ FIXED** (2026-06-09)

This is the **highest priority fix**. Re-register models that need tool-calling support:

```shell
# Check current Ollama version
ollama --version
curl -s http://localhost:11434/api/version

# Re-register qwen3-coder-30b-a3b:q6 (primary coder)
ollama rm qwen3-coder-30b-a3b:q6
cat > /tmp/model.Modelfile << 'EOF'
FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0
PARAMETER repeat_penalty 1.05
EOF
ollama create qwen3-coder-30b-a3b:q6 -f /tmp/model.Modelfile

# Re-register qwen2.5:32b (Opus model)
ollama rm qwen2.5:32b
cat > /tmp/model.Modelfile << 'EOF'
FROM hf.co/hesamation/Qwen2.5-32B-Instruct-GGUF:Qwen2.5-32B-Instruct.Q4_K_M.gguf
PARAMETER num_ctx 262144
PARAMETER temperature 0.6
EOF
ollama create qwen2.5:32b -f /tmp/model.Modelfile

# Re-register qwen3-14b:sonnet4.5 (research/write model)
ollama rm qwen3-14b:sonnet4.5
cat > /tmp/model.Modelfile << 'EOF'
FROM hf.co/TeichAI/Qwen3-14B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF:Qwen3-14B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf
PARAMETER num_ctx 40960
PARAMETER temperature 0.6
EOF
ollama create qwen3-14b:sonnet4.5 -f /tmp/model.Modelfile

# Recreate context variants from the base models
cat > /tmp/model-128k.Modelfile << 'EOF'
FROM qwen3-coder-30b-a3b:q6
PARAMETER num_ctx 131072
EOF
ollama create qwen3-coder-30b-a3b:q6-128k -f /tmp/model-128k.Modelfile
```

### 2. Update Planning Agent Usage

The planning agent should **not** be used for tasks requiring tool execution. Instead:

- **For research tasks:** Use the `research` agent (has webfetch, glob, grep, read)
- **For coding tasks:** Use the `code` agent (has bash, edit, all tools)
- **For analysis tasks:** Use the `think` agent (has webfetch, read)

Update the planning agent prompt to clarify its role:

```markdown
---
description: Fast planning agent for next steps, breakdowns, and lightweight routing.
mode: primary
permission:
  bash: deny
  edit: deny
  glob: allow
  grep: allow
  list: allow
  read: allow
  webfetch: deny
  external_directory: ask
---

You are a lightweight planning agent. Turn goals into actionable steps, break work into phases, identify blockers, and recommend the next best action. Stay concise, practical, and execution-oriented.

**Important:** You are a PLANNING agent only. Do NOT execute tools or make external calls. Your output should be a structured plan with clear next steps, not tool calls or search results.
```

### 3. Verify Ollama Version and Model Loading

```shell
# Check Ollama version (need ≥ 0.30.0 for qwen35 architecture)
ollama --version

# Check server version
curl -s http://localhost:11434/api/version

# List all models and verify they're loaded
ollama list

# Check model details
ollama show qwen3-coder-30b-a3b:q6
ollama show qwen2.5:32b
```

### 4. Check Context Window Configuration

Verify that context windows are properly set:

```shell
# Check model info
ollama show qwen3-coder-30b-a3b:q6 --modelfile
ollama show qwen2.5:32b --modelfile

# Look for num_ctx parameter in the output
```

If context windows are missing or too small, recreate the models with explicit context:

```shell
# For qwen3-coder-30b-a3b:q6 (should be 32768 or larger)
cat > /tmp/model.Modelfile << 'EOF'
FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0
PARAMETER repeat_penalty 1.05
EOF
ollama create qwen3-coder-30b-a3b:q6 -f /tmp/model.Modelfile
```

---

## Long-term Fixes

### 1. Implement HF Reference Registration for All Models

Update the installation workflow to always use `FROM hf.co/...` instead of bare GGUF paths. This preserves the chat template and ensures proper tool-calling support.

### 2. Update Model Assignment Matrix

Review and update the model assignment matrix in `model-map.md` to ensure:

- Models with full tool-calling support are used for tool-intensive tasks
- Models with minimal templates are only used for tasks that don't require tool calls
- Context windows are appropriate for the assigned tasks

### 3. Add Validation to Install Scripts

Add validation to the install scripts to:

- Check Ollama version before installing models
- Verify model registration success
- Test tool-calling functionality after installation

### 4. Monitor Model Performance

Add monitoring to track:

- Token generation speed
- Context window utilization
- Tool-calling success rate
- Output quality metrics

---

## Verification Steps

**Status: ✅ VERIFIED** (2026-06-09)

After applying fixes, verify the improvements:

```shell
# Test tool-calling with the primary coder
ollama run qwen3-coder-30b-a3b:q6 "Search for information about Python decorators"

# Test planning agent (should produce concise plan, not tool calls)
ollama run qwen3.5:4b "Plan the steps to set up a new Python project"

# Test research agent (should execute tools and produce findings)
ollama run qwen3-14b:sonnet4.5 "Research the latest features in Python 3.12"

# Check model templates
ollama show qwen3-coder-30b-a3b:q6 --modelfile | grep -A 5 "TEMPLATE"
ollama show qwen2.5:32b --modelfile | grep -A 5 "TEMPLATE"
```

---

## References

- [[ollama-model-registration.md]] — Ollama model registration patterns and troubleshooting
- [[CANONICAL_RULES.md]] — Weighted decisions for profile configuration
- [[CONFIG_SCHEMA.md]] — Profile configuration schema and update checklist
- [[tuning-guide.md]] — Performance tuning for llama-server router

---

_Generated: 2026-06-09_
_Profile: macbook-m5-64gb_
_Issue: Local LLM quality degradation_
_Status: ✅ Fixed and verified_
