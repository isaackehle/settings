# Ai Strategy

High-level strategy for AI setup. Per-model decisions and rationale live in [docs/MODELS.md]. This file is the 60-second reference.

## Q5 — Primary Reasoning Model

**Decision:** Use the Qwen3.6-35B family as the primary reasoning model, starting with `qwen3.6-35b:opus4.7-128k` (HF distillation — hf.co/hesamation) and migrating to native `qwen3.6-35b` when Ollama's variant is stable.

**Decision summary:**

- **Qwen3 architecture:** Reasoning-optimized from first principles (not a distillation), significantly superior to older distillations
- **35B parameter range:** Sweet spot for M5 Max 64GB — fits comfortably in profile with headroom for large context windows
- **128K context window:** the critical capacity dimension enabling repository-scale codebase understanding
- **Native model preferred:** Qwen3.6's superior architecture outweighs the marginal quality gain of the opus4.7 distill of Qwen2.5-32B
- **Ecosystem support:** Official Ollama support, active development, MLX quantizations for 2-3x faster inference on Apple Silicon
- **Architectural purpose:** Essential for thinking/plan agents and Claude Opus-style deep-thinking workloads on local hardware

### Model Lineup

| Variant | Status | Reasoning | Context | Target | Notes |
|:---| --- | :---: | :-: | --- | --- |
| `qwen3.6-35b:opus4.7-128k` | **Current/production** | ✓ | 128K | 64GB | HF distillation of Qwen2.5-32B (~24 GB Q8) |
| `qwen3.6-35b:opus4.7-128k` | **Planned** | ✓ | 128K | 64GB | Native Ollama variant (upgrading soon) |
| `qwen3.6-35b:opus4.7-16k` | Planned | ✓ | 16K | 48/32GB | Swap-in variant for smaller machines |

### Migration Notes

1. **Native upgrade path:** `qwen3.6-35b` replaces the HF distillation once the Ollama library variant is fully available (currently awaiting `rope_sections` bug fix in llama.cpp).
2. **`opus4.7-16k` variant:** Faster swap-in variant for 48GB and 32GB profiles where the full 128K context variant is too memory-intensive.
3. **`opus4.7-128k` variant:** Primary slot — use for all reasoning-intense workloads.

### Performance

- **Throughput:** ~110–130 tokens/s on M5 Max 64GB (Q8 quant)
- **Memory:** ~28–30 GB per model (depending on variant)

---

*See [docs/MODELS.md] for per-model decision log and history.*
