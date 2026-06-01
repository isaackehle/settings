# Model Map — macbook-m1-16gb

## Hugging Face → GGUF → Ollama Materialization

This is the profile-specific install graph: Hugging Face source repo, exact remote GGUF filename, normalized local artifact name, Ollama alias, MODELFILE parameters, and context-window aliases.

| Ollama alias         | HF repo                                                                                | Remote GGUF                                                                | Quant        | Local GGUF                             | Family             | Base num_ctx | Context aliases | MODELFILE params                                         |
| -------------------- | -------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- | ------------ | -------------------------------------- | ------------------ | -----------: | --------------- | -------------------------------------------------------- |
| `codestral:22b`      | `hf.co/bartowski/Codestral-22B-v0.1-GGUF`                                              | `Codestral-22B-v0.1-Q4_K_M.gguf`                                           | `Q4_K_M`     | `codestral-22b-cd-q4_k_m.gguf`         | `coder`            |          `—` | —               | —                                                        |
| `deepseek-r1:7b`     | `hf.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF`                                     | `DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf`                                  | `Q4_K_M`     | `deepseek-r1-7b-ds-q4_k_m.gguf`        | `reasoning-tools`  |     `131072` | —               | PARAMETER temperature 0.3                                |
| `nomic-embed-text`   | `hf.co/nomic-ai/nomic-embed-text-v1.5-GGUF`                                            | `nomic-embed-text-v1.5.f16.gguf`                                           | `F16`        | `nomic-embed-text-em-f16.gguf`         | `embedding`        |       `8192` | —               | —                                                        |
| `qwen2.5-7b:multi`   | `hf.co/mradermacher/Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL-GGUF` | `Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL.Q4_K_M.gguf` | `Q4_K_M`     | `qwen2.5-7b-multi-it-ds-q4_k_m.gguf`   | `instruct-distill` |    `1010000` | —               | PARAMETER temperature 0.6                                |
| `qwen2.5-coder:1.5b` | `hf.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-GGUF`                                       | `Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf`                                  | `Q4_K_M`     | `qwen2.5-coder-1.5b-cd-q4_k_m.gguf`    | `coder`            |          `—` | —               | —                                                        |
| `qwen2.5-coder:7b`   | `hf.co/unsloth/Qwen2.5-Coder-7B-Instruct-GGUF`                                         | `Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf`                                    | `Q4_K_M`     | `qwen2.5-coder-7b-cd-q4_k_m.gguf`      | `coder`            |      `32768` | —               | PARAMETER temperature 0<br>PARAMETER repeat_penalty 1.05 |
| `qwen3-8b:sonnet4.5` | `hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF`                      | `Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf`            | `Q4_K_M`     | `qwen3-8b-sonnet4.5-it-ds-q4_k_m.gguf` | `instruct-distill` |      `40960` | —               | PARAMETER temperature 0.6                                |
| `qwen3:14b`          | `hf.co/Qwen/Qwen3-14B-GGUF`                                                            | `Qwen3-14B-Q4_K_M.gguf`                                                    | `Q4_K_M`     | `qwen3-14b-it-q4_k_m.gguf`             | `instruct`         |     `262144` | —               | PARAMETER temperature 0.5                                |
| `qwen3:4b`           | `hf.co/Qwen/Qwen3-4B-GGUF`                                                             | `Qwen3-4B-Q4_K_M.gguf`                                                     | `Q4_K_M`     | `qwen3-4b-it-q4_k_m.gguf`              | `instruct`         |     `131072` | —               | PARAMETER temperature 0.2                                |
| `qwen3.5:4b`         | `hf.co/unsloth/Qwen3.5-4B-GGUF`                                                        | `Qwen3.5-4B-UD-Q4_K_XL.gguf`                                               | `UD-Q4_K_XL` | `qwen3.5-4b-it-ud-q4_k_xl.gguf`        | `instruct`         |     `131072` | —               | PARAMETER temperature 0.2                                |

### Materialization graph

```mermaid
flowchart LR
  classDef hf fill:#eef6ff,stroke:#4b8bbe,color:#111;
  classDef file fill:#f7f7f7,stroke:#999,color:#111;
  classDef ollama fill:#edf7ed,stroke:#4f9d5d,color:#111;
  classDef params fill:#fff7e6,stroke:#d99000,color:#111;
  hf_hf_co_bartowski_Codestral_22B_v0_1_GGUF["HF: hf.co/bartowski/Codestral-22B-v0.1-GGUF"]:::hf
  remote_hf_co_bartowski_Codestral_22B_v0_1_GGUF_Codestral_22B_v0_1_Q4_K_M_gguf["Remote GGUF: Codestral-22B-v0.1-Q4_K_M.gguf"]:::file
  local_codestral_22b_cd_q4_k_m_gguf["Local GGUF: codestral-22b-cd-q4_k_m.gguf"]:::file
  ollama_codestral_22b["Ollama: codestral:22b\nquant=Q4_K_M; family=coder"]:::ollama
  hf_hf_co_bartowski_Codestral_22B_v0_1_GGUF --> remote_hf_co_bartowski_Codestral_22B_v0_1_GGUF_Codestral_22B_v0_1_Q4_K_M_gguf --> local_codestral_22b_cd_q4_k_m_gguf --> ollama_codestral_22b
  hf_hf_co_bartowski_DeepSeek_R1_Distill_Qwen_7B_GGUF["HF: hf.co/bartowski/DeepSeek-R1-Distill-Qwen-7B-GGUF"]:::hf
  remote_hf_co_bartowski_DeepSeek_R1_Distill_Qwen_7B_GGUF_DeepSeek_R1_Distill_Qwen_7B_Q4_K_M_gguf["Remote GGUF: DeepSeek-R1-Distill-Qwen-7B-Q4_K_M.gguf"]:::file
  local_deepseek_r1_7b_ds_q4_k_m_gguf["Local GGUF: deepseek-r1-7b-ds-q4_k_m.gguf"]:::file
  ollama_deepseek_r1_7b["Ollama: deepseek-r1:7b\nquant=Q4_K_M; family=reasoning-tools"]:::ollama
  hf_hf_co_bartowski_DeepSeek_R1_Distill_Qwen_7B_GGUF --> remote_hf_co_bartowski_DeepSeek_R1_Distill_Qwen_7B_GGUF_DeepSeek_R1_Distill_Qwen_7B_Q4_K_M_gguf --> local_deepseek_r1_7b_ds_q4_k_m_gguf --> ollama_deepseek_r1_7b
  params_deepseek_r1_7b["MODELFILE params"]:::params
  params_deepseek_r1_7b -.-> ollama_deepseek_r1_7b
  hf_hf_co_nomic_ai_nomic_embed_text_v1_5_GGUF["HF: hf.co/nomic-ai/nomic-embed-text-v1.5-GGUF"]:::hf
  remote_hf_co_nomic_ai_nomic_embed_text_v1_5_GGUF_nomic_embed_text_v1_5_f16_gguf["Remote GGUF: nomic-embed-text-v1.5.f16.gguf"]:::file
  local_nomic_embed_text_em_f16_gguf["Local GGUF: nomic-embed-text-em-f16.gguf"]:::file
  ollama_nomic_embed_text["Ollama: nomic-embed-text\nquant=F16; family=embedding"]:::ollama
  hf_hf_co_nomic_ai_nomic_embed_text_v1_5_GGUF --> remote_hf_co_nomic_ai_nomic_embed_text_v1_5_GGUF_nomic_embed_text_v1_5_f16_gguf --> local_nomic_embed_text_em_f16_gguf --> ollama_nomic_embed_text
  hf_hf_co_mradermacher_Qwen2_5_7B_Instruct_1M_Thinking_Claude_Gemini_GPT5_2_DISTILL_GGUF["HF: hf.co/mradermacher/Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL-GGUF"]:::hf
  remote_hf_co_mradermacher_Qwen2_5_7B_Instruct_1M_Thinking_Claude_Gemini_GPT5_2_DISTILL_GGUF_Qwen2_5_7B_Instruct_1M_Thinking_Claude_Gemini_GPT5_2_DISTILL_Q4_K_M_gguf["Remote GGUF: Qwen2.5-7B-Instruct-1M-Thinking-Claude-Gemini-GPT5.2-DISTILL.Q4_K_M.gguf"]:::file
  local_qwen2_5_7b_multi_it_ds_q4_k_m_gguf["Local GGUF: qwen2.5-7b-multi-it-ds-q4_k_m.gguf"]:::file
  ollama_qwen2_5_7b_multi["Ollama: qwen2.5-7b:multi\nquant=Q4_K_M; family=instruct-distill"]:::ollama
  hf_hf_co_mradermacher_Qwen2_5_7B_Instruct_1M_Thinking_Claude_Gemini_GPT5_2_DISTILL_GGUF --> remote_hf_co_mradermacher_Qwen2_5_7B_Instruct_1M_Thinking_Claude_Gemini_GPT5_2_DISTILL_GGUF_Qwen2_5_7B_Instruct_1M_Thinking_Claude_Gemini_GPT5_2_DISTILL_Q4_K_M_gguf --> local_qwen2_5_7b_multi_it_ds_q4_k_m_gguf --> ollama_qwen2_5_7b_multi
  params_qwen2_5_7b_multi["MODELFILE params"]:::params
  params_qwen2_5_7b_multi -.-> ollama_qwen2_5_7b_multi
  hf_hf_co_unsloth_Qwen2_5_Coder_1_5B_Instruct_GGUF["HF: hf.co/unsloth/Qwen2.5-Coder-1.5B-Instruct-GGUF"]:::hf
  remote_hf_co_unsloth_Qwen2_5_Coder_1_5B_Instruct_GGUF_Qwen2_5_Coder_1_5B_Instruct_Q4_K_M_gguf["Remote GGUF: Qwen2.5-Coder-1.5B-Instruct-Q4_K_M.gguf"]:::file
  local_qwen2_5_coder_1_5b_cd_q4_k_m_gguf["Local GGUF: qwen2.5-coder-1.5b-cd-q4_k_m.gguf"]:::file
  ollama_qwen2_5_coder_1_5b["Ollama: qwen2.5-coder:1.5b\nquant=Q4_K_M; family=coder"]:::ollama
  hf_hf_co_unsloth_Qwen2_5_Coder_1_5B_Instruct_GGUF --> remote_hf_co_unsloth_Qwen2_5_Coder_1_5B_Instruct_GGUF_Qwen2_5_Coder_1_5B_Instruct_Q4_K_M_gguf --> local_qwen2_5_coder_1_5b_cd_q4_k_m_gguf --> ollama_qwen2_5_coder_1_5b
  hf_hf_co_unsloth_Qwen2_5_Coder_7B_Instruct_GGUF["HF: hf.co/unsloth/Qwen2.5-Coder-7B-Instruct-GGUF"]:::hf
  remote_hf_co_unsloth_Qwen2_5_Coder_7B_Instruct_GGUF_Qwen2_5_Coder_7B_Instruct_Q4_K_M_gguf["Remote GGUF: Qwen2.5-Coder-7B-Instruct-Q4_K_M.gguf"]:::file
  local_qwen2_5_coder_7b_cd_q4_k_m_gguf["Local GGUF: qwen2.5-coder-7b-cd-q4_k_m.gguf"]:::file
  ollama_qwen2_5_coder_7b["Ollama: qwen2.5-coder:7b\nquant=Q4_K_M; family=coder"]:::ollama
  hf_hf_co_unsloth_Qwen2_5_Coder_7B_Instruct_GGUF --> remote_hf_co_unsloth_Qwen2_5_Coder_7B_Instruct_GGUF_Qwen2_5_Coder_7B_Instruct_Q4_K_M_gguf --> local_qwen2_5_coder_7b_cd_q4_k_m_gguf --> ollama_qwen2_5_coder_7b
  params_qwen2_5_coder_7b["MODELFILE params"]:::params
  params_qwen2_5_coder_7b -.-> ollama_qwen2_5_coder_7b
  hf_hf_co_TeichAI_Qwen3_8B_Claude_Sonnet_4_5_Reasoning_Distill_GGUF["HF: hf.co/TeichAI/Qwen3-8B-Claude-Sonnet-4.5-Reasoning-Distill-GGUF"]:::hf
  remote_hf_co_TeichAI_Qwen3_8B_Claude_Sonnet_4_5_Reasoning_Distill_GGUF_Qwen3_8B_claude_sonnet_4_5_high_reasoning_distill_Q4_K_M_gguf["Remote GGUF: Qwen3-8B-claude-sonnet-4.5-high-reasoning-distill-Q4_K_M.gguf"]:::file
  local_qwen3_8b_sonnet4_5_it_ds_q4_k_m_gguf["Local GGUF: qwen3-8b-sonnet4.5-it-ds-q4_k_m.gguf"]:::file
  ollama_qwen3_8b_sonnet4_5["Ollama: qwen3-8b:sonnet4.5\nquant=Q4_K_M; family=instruct-distill"]:::ollama
  hf_hf_co_TeichAI_Qwen3_8B_Claude_Sonnet_4_5_Reasoning_Distill_GGUF --> remote_hf_co_TeichAI_Qwen3_8B_Claude_Sonnet_4_5_Reasoning_Distill_GGUF_Qwen3_8B_claude_sonnet_4_5_high_reasoning_distill_Q4_K_M_gguf --> local_qwen3_8b_sonnet4_5_it_ds_q4_k_m_gguf --> ollama_qwen3_8b_sonnet4_5
  params_qwen3_8b_sonnet4_5["MODELFILE params"]:::params
  params_qwen3_8b_sonnet4_5 -.-> ollama_qwen3_8b_sonnet4_5
  hf_hf_co_Qwen_Qwen3_14B_GGUF["HF: hf.co/Qwen/Qwen3-14B-GGUF"]:::hf
  remote_hf_co_Qwen_Qwen3_14B_GGUF_Qwen3_14B_Q4_K_M_gguf["Remote GGUF: Qwen3-14B-Q4_K_M.gguf"]:::file
  local_qwen3_14b_it_q4_k_m_gguf["Local GGUF: qwen3-14b-it-q4_k_m.gguf"]:::file
  ollama_qwen3_14b["Ollama: qwen3:14b\nquant=Q4_K_M; family=instruct"]:::ollama
  hf_hf_co_Qwen_Qwen3_14B_GGUF --> remote_hf_co_Qwen_Qwen3_14B_GGUF_Qwen3_14B_Q4_K_M_gguf --> local_qwen3_14b_it_q4_k_m_gguf --> ollama_qwen3_14b
  params_qwen3_14b["MODELFILE params"]:::params
  params_qwen3_14b -.-> ollama_qwen3_14b
  hf_hf_co_Qwen_Qwen3_4B_GGUF["HF: hf.co/Qwen/Qwen3-4B-GGUF"]:::hf
  remote_hf_co_Qwen_Qwen3_4B_GGUF_Qwen3_4B_Q4_K_M_gguf["Remote GGUF: Qwen3-4B-Q4_K_M.gguf"]:::file
  local_qwen3_4b_it_q4_k_m_gguf["Local GGUF: qwen3-4b-it-q4_k_m.gguf"]:::file
  ollama_qwen3_4b["Ollama: qwen3:4b\nquant=Q4_K_M; family=instruct"]:::ollama
  hf_hf_co_Qwen_Qwen3_4B_GGUF --> remote_hf_co_Qwen_Qwen3_4B_GGUF_Qwen3_4B_Q4_K_M_gguf --> local_qwen3_4b_it_q4_k_m_gguf --> ollama_qwen3_4b
  params_qwen3_4b["MODELFILE params"]:::params
  params_qwen3_4b -.-> ollama_qwen3_4b
  hf_hf_co_unsloth_Qwen3_5_4B_GGUF["HF: hf.co/unsloth/Qwen3.5-4B-GGUF"]:::hf
  remote_hf_co_unsloth_Qwen3_5_4B_GGUF_Qwen3_5_4B_UD_Q4_K_XL_gguf["Remote GGUF: Qwen3.5-4B-UD-Q4_K_XL.gguf"]:::file
  local_qwen3_5_4b_it_ud_q4_k_xl_gguf["Local GGUF: qwen3.5-4b-it-ud-q4_k_xl.gguf"]:::file
  ollama_qwen3_5_4b["Ollama: qwen3.5:4b\nquant=UD-Q4_K_XL; family=instruct"]:::ollama
  hf_hf_co_unsloth_Qwen3_5_4B_GGUF --> remote_hf_co_unsloth_Qwen3_5_4B_GGUF_Qwen3_5_4B_UD_Q4_K_XL_gguf --> local_qwen3_5_4b_it_ud_q4_k_xl_gguf --> ollama_qwen3_5_4b
  params_qwen3_5_4b["MODELFILE params"]:::params
  params_qwen3_5_4b -.-> ollama_qwen3_5_4b
```

---

## Model Assignment Matrix

Tools across the rows, models across the columns. Cells show the role(s)
each model plays in each tool. `-` = not assigned.

| Tool           | deepseek-r1:7b | qwen3:4b | qwen2.5-coder:1.5b |             qwen2.5-coder:7b              | nomic-embed-text |
| -------------- | :------------: | :------: | :----------------: | :---------------------------------------: | :--------------: |
| **Cline**      |       —        |    —     |         —          |                     —                     |        —         |
| **ZooCode**    |       —        |    —     |         —          |                     —                     |        —         |
| **KiloCode**   |       —        |    —     |         —          |                     —                     |        —         |
| **Aider**      |       —        |   weak   |         —          |               editor, model               |        —         |
| **Zed**        |       —        |    —     |         —          |                     —                     |        —         |
| **Cursor**     |       —        |    —     |         —          |                     —                     |        —         |
| **OpenCode**   |     think      |   plan   |         —          |           code, write, research           |        —         |
| **Continue**   |       —        |    —     |    autocomplete    | chat_alt, apply, chat, autocomplete_heavy |      embed       |
| **ClaudeCode** |   reasoning    |   fast   |         —          |      coding, research, opus, primary      |        —         |

---

## Model Categories

| Category         |   # | Models                                                   |
| ---------------- | --: | -------------------------------------------------------- |
| **Reasoning**    |   1 | `deepseek-r1:7b` (5 GB)                                  |
| **Planning**     |   1 | `qwen3:4b` (2.5 GB)                                      |
| **Autocomplete** |   2 | `qwen2.5-coder:1.5b` (986 MB), `qwen2.5-coder:7b` (5 GB) |
| **Embeddings**   |   1 | `nomic-embed-text` (0.3 GB)                              |

## OpenRouter (cloud models)

These models are available via OpenRouter — no local storage needed:

- claude-opus-4-6
- claude-sonnet-4-6
- claude-haiku-4-5
- gpt-4o
- o3
- sonar-pro
- deepseek-v4-pro
- gemini-3-flash-preview
- glm-5.1
- gpt-oss:120b
- gpt-oss:20b
- kimi-k2.6
- mistral-large-3

---

Generated by `generate-model-map.sh` for profile `macbook-m1-16gb`. Edit `models.sh` and re-run to regenerate.
