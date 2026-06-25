# model-updater

Automatically detect and suggest replacements for outdated models in the local Ollama installation based on newer releases, better quantizations, or model improvements discovered through searching.

## Purpose

When a newer or better model is discovered (new version, higher performance, smaller footprint, or improved capabilities), this skill:

1. Identifies opportunities to replace existing models
2. Provides clear recommendation details and rationale
3. Can automatically update model configuration files when requested
4. Helps keep the model stack current without manual investigation

## Workflow

### Step 1 — Read Current Model Config

Use `SCRIPT_MD_VIEW_COMMAND` to read `scripts/models.sh` and extract:

- Hardware profiles (macbook-m5-64gb, macbook-m1-16gb, etc.)
- Model assignments for each profile (architect, coder, reasoning, etc.)
- Current Ollama versions and quants
- Custom GGUF aliases in `CUSTOM_MODELS_*` arrays
- Context window information

Also read the per-machine `models.sh` files to understand what's currently installed.

### Step 2 — Check Ollama Current State

If Ollama is running locally:

```bash
curl -s http://localhost:11434/api/tags | python3 -c "
import json,sys
tags = json.load(sys.stdin)
for m in tags.get('models', []):
    print(m['name'], m.get('size',''))
"
```

Cross-reference with `models.sh` to identify:

- Models configured but not yet pulled
- Models pulled but no longer referenced (orphans)
- Aliases installed whose source URL no longer matches (drift)

### Step 3 — Search for New Releases

Search these sources for newer models:

**Ollama Hub Search**

```bash
# Check for newer tags on specific models
ollama search qwen2.5-coder
ollama search qwen3.6-35b
ollama search deepseek-r1

# Get exact tag details to compare:
official tags, size, quant, context windows
```

**Web Search for Improvements**

- Search for "Qwen 3.5 27B Q4 quantization improvements"
- Look for "Best local coding model 2024"
- Check for "New MoE model requirements"
- Search tool stability benchmarks

**Hugging Face**

- Compare model repositories for quantization improvements
- Check for new architectures with better performance
- Look for quant-to-quant improvements (Q4_K_M → Q5_K_M)
- Find models with better tool calling support

### Step 4 — Generate Recommendations

Compare discovered models against current setup:

**What makes a model better replacement:**

- Same role, smaller footprint (e.g., 16B → 8B for 16GB machines)
- Same role, higher performance (faster generation, better tools, larger context)
- Newer architecture or better training methodology
- More stable tool-calling implementation
- Better community support and updates

**Recommendation format:**

```yaml
role: "architect"
current: "qwen3.6-35b:opus4.7-128k" (25GB, Q6_K_M)
replacement: "qwen2.5:32b" (20GB, Q4_K_M)
improvement: "Better architect model, 20% faster generation"
impact: "Same role, 20% smaller memory footprint"
profile: "macbook-m5-64gb"

role: "coder"  
current: "qwen3-coder-30b-a3b:q5" (26GB, Q5_K_M)
replacement: "laguna-xs.2" (23GB, Q6_K)
improvement: "Better MoE architecture for coding"
impact: "Better reasoning in code, same footprint"
```

### Step 5 — Auto-Update When Requested

If user confirms auto-update:

1. Update `models.sh` CUSTOM_MODELS_ arrays
2. Optionally run `setup_ai.sh` to apply new models
3. Create context aliases for the new model if needed
4. Clean up old model directories (optional)

## Integration with Other Skills

This skill works with:

- **model-updater-updates**: Track when models are replaced and log changes
- **oMLX**: Handle oMLX quantization variants when they become available
- **ollama-model-registry**: Sync new model registrations with official Ollama Hub
- **workflow-notifications**: Alert users when model suggestions become available

## Trigger Phrases

```
"are there better models for my setup?"
"what new AI models were released?\ 