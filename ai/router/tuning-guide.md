# Performance Tuning — llama-server Router on M5 Max 64GB

Target machine: **MacBook Pro, M5 Max, 64 GB unified memory** ("discovery").
Backend: **Metal** (Apple Silicon GPU). All three models run fully on the GPU.

The single most important fact on Apple Silicon: **CPU and GPU share one pool
of unified memory.** "VRAM" and "RAM" are the same 64 GB. Your budget is not
"how much fits on a GPU" but "weights + KV cache + everything else macOS is
doing, under ~64 GB."

---

## 1. Your actual models and their footprints

| Model ID          | File                                     | Quant       | Weights (approx) | Type                     |
| ----------------- | ---------------------------------------- | ----------- | ---------------- | ------------------------ |
| `deepseek-r1-32b` | `deepseek-r1-32b-ds-q4_k_m.gguf`         | Q4_K_M      | ~19–20 GB        | Dense 32B reasoning      |
| `qwen3-4b-it`     | `qwen3-4b-it-q4_k_m.gguf`                | Q4_K_M      | ~2.5 GB          | Dense 4B chat            |
| `qwen3-coder-30b` | `qwen3-coder-30b-a3b-cd-ud-q6_k_xl.gguf` | **Q6_K_XL** | **~25 GB**       | MoE 30B/3B-active coding |

Note the coder is **Q6_K_XL**, not Q4 — about 6–7 GB heavier than a Q4 build but
noticeably higher fidelity on code. It still fits resident alone with room to
spare; just don't try to co-resident it with the 32B (see §4).

---

## 2. GPU offload: set everything to full offload

On M-series the right answer is almost always **offload all layers**:

- In `models.ini`: `ngl = 999` (any value ≥ layer count = "all"). `-1` also
  means "all" on current builds; `999` is the unambiguous idiom.
- All three of your models fit entirely in unified memory, so there is **no
  reason to partially offload**. Partial offload (`ngl = 20`) only matters when
  weights exceed memory — not your situation.

Why not leave layers on CPU "to save memory"? It doesn't save total memory
(unified pool) and it tanks throughput, because tokens then bounce between CPU
and GPU each layer. Keep `ngl = 999` everywhere.

---

## 3. KV cache — the real memory variable

Weights are fixed; the **KV cache grows with context length** and is what
actually blows your budget. Two levers:

### a) Flash attention — turn it on (`flash-attn = on`, `-fa`)

- Big prompt-processing speedup (often >2x on long prompts).
- Substantially smaller KV cache memory.
- On Metal it computes the same result — no quality loss.
- Already set on all three models in your INI.

### b) KV cache quantization (`cache-type-k` / `cache-type-v`)

KV defaults to f16. Quantizing to `q8_0` roughly **halves** KV memory with
negligible quality impact. Guidance from the llama.cpp maintainers:

- `cache-type-v = q8_0` (value cache) is the safest — nearly free.
- `cache-type-k = q8_0` (key cache) is also fine for most models; it has
  slightly more impact than the value cache but is still low-risk at q8_0.
- **Avoid q4 KV** unless desperate for memory — it can degrade quality.
- KV quant requires flash attention enabled (it is).

Your INI sets `q8_0/q8_0` only on the 32B (where context memory matters most).
The 4B is tiny so it's left at f16 for max quality; the coder uses f16 by
default but you can add `q8_0` if you push its context past ~48k.

### KV cache size rule of thumb (f16)

KV bytes ≈ `2 (K+V) × n_layers × ctx × n_kv_heads × head_dim × 2 bytes`.
You don't need the formula — just the ballparks at f16, halved with q8_0:

| Model                         | ctx in INI | KV @ f16 | KV @ q8_0 |
| ----------------------------- | ---------- | -------- | --------- |
| `deepseek-r1-32b` (64 layers) | 16k        | ~3–4 GB  | ~1.5–2 GB |
| `qwen3-coder-30b` (MoE)       | 64k        | ~6–8 GB  | ~3–4 GB   |
| `qwen3-4b-it`                 | 32k        | ~1.5 GB  | ~0.8 GB   |

---

## 4. How many models resident at once (`--models-max`)

This is the headroom decision. macOS + apps comfortably want ~8–12 GB. Keep a
safety margin; don't plan to use the full 64 GB.

| Scenario               | Resident set                      | Peak memory | Verdict                                 |
| ---------------------- | --------------------------------- | ----------- | --------------------------------------- |
| One big model alone    | coder Q6 (25 GB) + 64k KV (~6 GB) | ~31 GB      | Safe, lots of headroom                  |
| One big model alone    | R1-32B (20 GB) + 16k KV (~3 GB)   | ~23 GB      | Safe                                    |
| **4B + one big model** | 4B (~4 GB) + coder (~31 GB)       | ~35 GB      | Safe — recommended `--models-max 2`     |
| Two big models         | R1-32B (~23 GB) + coder (~31 GB)  | ~54 GB      | Risky — leaves <10 GB for macOS. Avoid. |

**Recommendation:** start at `--models-max 1` (the shipped default in your
files). Once you confirm stability, bump to `--models-max 2` so the **4B stays
warm alongside one big model** — instant responses for quick turns, no reload
penalty. Never co-resident the 32B and the 30B-coder on 64 GB.

To change it: edit `--models-max` in `org.kehle.llama-router.plist`, then
reload the agent (commands at the bottom of that file).

---

## 5. Threads, batch, and Metal specifics

- **`threads`**: only affects work _not_ on the GPU. With full offload its
  impact is small. Set to your performance-core count (M5 Max ≈ 12 P-cores is a
  reasonable value; the INI uses `12`). Going higher rarely helps and can hurt.
- **`-b` / batch size**: default (2048) is fine. Larger batch speeds long-prompt
  prefill at some memory cost; not needed here.
- **`--mlock`**: keeps weights pinned in RAM (no paging). With 64 GB and one
  resident big model you generally don't need it, and it can fight macOS memory
  management. Skip unless you see paging.
- **Metal is automatic.** Homebrew/official Apple-Silicon builds enable Metal +
  Accelerate by default. If you build from source, do **not** pass
  `-DGGML_METAL=OFF`. A native build is meaningfully faster than some packaged
  builds — worth `brew install llama.cpp` or building with Metal on.

---

## 6. Per-model sampling (already in the INI)

| Model             | temp | top-p | top-k | Why                                                                                       |
| ----------------- | ---- | ----- | ----- | ----------------------------------------------------------------------------------------- |
| `deepseek-r1-32b` | 0.6  | 0.95  | —     | DeepSeek's recommended reasoning settings; lower temp keeps the chain-of-thought coherent |
| `qwen3-4b-it`     | 0.7  | 0.8   | 20    | Qwen3 instruct defaults                                                                   |
| `qwen3-coder-30b` | 0.7  | 0.8   | 20    | Qwen3 defaults; deterministic enough for code                                             |

For maximally deterministic code generation, drop the coder to `temp = 0.2`.

---

## 7. Expected behavior

- **Cold load**: first request to a model memory-maps the GGUF and warms Metal.
  The 4B is near-instant; the 20–25 GB models take a few seconds. With
  `--models-max 1`, switching models pays this cost each switch.
- **MoE speed**: `qwen3-coder-30b` is a 30B model that activates only ~3B
  params per token, so tokens/sec feels closer to a small model than its size
  suggests — despite the Q6 weights. This is why it's a great daily coder.
- **R1 reasoning**: expect long outputs with `<think>` blocks; budget tokens and
  context accordingly (that's why its ctx is 16k, not larger — reasoning fills
  KV fast).

---

## 8. Verify your build supports router mode

The INI interface in llama.cpp is still evolving. Before trusting a key, check:

```bash
llama-server --help | grep -E 'models-preset|models-dir|models-max|flash-attn|cache-type'
```

- If `--models-preset` is missing: `brew upgrade llama.cpp` (or rebuild).
- If a specific INI key is rejected, it may have been renamed — drop it or move
  the setting to a command-line flag in the plist as a fallback.
- For reproducibility across restarts, pin to a known-good llama.cpp version
  rather than always tracking `main`, since the preset format may change.

---

## 9. Quick benchmark

Measure real throughput on your machine for each file:

```bash
# tokens/sec for prefill (-p) and generation (-n)
llama-bench -m /usr/local/lib/llama-models/qwen3-coder-30b-a3b-cd-ud-q6_k_xl.gguf -ngl 999 -fa 1 -p 512 -n 128
llama-bench -m /usr/local/lib/llama-models/deepseek-r1-32b-ds-q4_k_m.gguf        -ngl 999 -fa 1 -p 512 -n 128
llama-bench -m /usr/local/lib/llama-models/qwen3-4b-it-q4_k_m.gguf               -ngl 999 -fa 1 -p 512 -n 128
```

Compare `-fa 1` vs `-fa 0`, and `q8_0` KV vs f16, to confirm the wins on your
exact hardware before locking settings into the INI.
