# Model Map — macbook-m5-64gb

## Assignments by Category

### Solo Coding

| Model | Tool | Role |
|------|------|------|
| `qwen3-coder-next-80b:q4 (48 GB)` | Aider | default |
| `qwen3-coder-next-80b:q4 (48 GB)` | ClaudeCode | primary |
| `qwen3-coder-next-80b:q4 (48 GB)` | Cline | default |
| `qwen3-coder-next-80b:q4 (48 GB)` | Continue | chat |
| `qwen3-coder-next-80b:q4 (48 GB)` | Cursor | default |
| `qwen3-coder-next-80b:q4 (48 GB)` | KiloCode | default |
| `qwen3-coder-next-80b:q4 (48 GB)` | OpenCode | code |
| `qwen3-coder-next-80b:q4 (48 GB)` | Zed | default |
| `qwen3-coder-next-80b:q4 (48 GB)` | ZooCode | code |
| `qwen3-coder-next-80b:q4 (48 GB)` | ZooCode | default |

### Co-resident Coding

| Model | Tool | Role |
|------|------|------|
| `qwen3-coder-30b-a3b:q6 (26 GB)` | ClaudeCode | coding |

### Architect

| Model | Tool | Role |
|------|------|------|
| `qwen3.6-35b:q4 (22 GB)` | ClaudeCode | opus |
| `qwen3.6-35b:q4 (22 GB)` | ZooCode | architect |

### Dense / Vision

| Model | Tool | Role |
|------|------|------|
| `gemma4:31b (20 GB)` | OpenCode | think |
| `gemma4:31b (20 GB)` | ZooCode | debug |

### Writing

| Model | Tool | Role |
|------|------|------|
| `qwen3.5-27b:q5 (19 GB)` | ClaudeCode | research |
| `qwen3.5-27b:q5 (19 GB)` | OpenCode | research |
| `qwen3.5-27b:q5 (19 GB)` | ZooCode | ask |
| `qwen3.5-27b:q8 (19 GB)` | Continue | chat_alt |
| `qwen3.5-27b:q8 (19 GB)` | OpenCode | write |

### Reasoning

| Model | Tool | Role |
|------|------|------|
| `deepseek-r1-tools:32b (20 GB)` | ClaudeCode | reasoning |

### Planning

| Model | Tool | Role |
|------|------|------|
| `qwen3:4b (5 GB)` | Aider | weak |
| `qwen3:4b (5 GB)` | ClaudeCode | fast |
| `qwen3:4b (5 GB)` | OpenCode | plan |

### Apply / Insert

| Model | Tool | Role |
|------|------|------|
| `codestral:22b (23 GB)` | Aider | editor |
| `codestral:22b (23 GB)` | Continue | apply |

### Autocomplete

| Model | Tool | Role |
|------|------|------|
| `qwen2.5-coder:1.5b (1 GB)` | Continue | autocomplete |
| `qwen2.5-coder:7b (5 GB)` | Continue | autocomplete_heavy |

### Embeddings

| Model | Tool | Role |
|------|------|------|
| `nomic-embed-text (0.3 GB)` | Continue | embed |

### Cloud

| Model | Tool | Role |
|------|------|------|
| `kimi-k2.6` | Cline | cloud |
| `kimi-k2.6` | Continue | kimi |
| `kimi-k2.6` | Cursor | cloud |
| `kimi-k2.6` | KiloCode | cloud |
| `kimi-k2.6` | ZooCode | cloud |

## Flow Diagram

```mermaid
graph LR

    subgraph Solo Coding["Solo Coding"]
    qwen3_coder_next_80b_q4("qwen3-coder-next-80b\:q4")
    end

    subgraph Co-resident Coding["Co-resident Coding"]
    qwen3_coder_30b_a3b_q6("qwen3-coder-30b-a3b\:q6")
    end

    subgraph Architect["Architect"]
    qwen3_6_35b_q4("qwen3.6-35b\:q4")
    end

    subgraph Dense / Vision["Dense / Vision"]
    gemma4_31b("gemma4\:31b")
    end

    subgraph Writing["Writing"]
    qwen3_5_27b_q5("qwen3.5-27b\:q5")
    qwen3_5_27b_q8("qwen3.5-27b\:q8")
    end

    subgraph Reasoning["Reasoning"]
    deepseek_r1_tools_32b("deepseek-r1-tools\:32b")
    end

    subgraph Planning["Planning"]
    qwen3_4b("qwen3\:4b")
    end

    subgraph Apply / Insert["Apply / Insert"]
    codestral_22b("codestral\:22b")
    end

    subgraph Autocomplete["Autocomplete"]
    qwen2_5_coder_1_5b("qwen2.5-coder\:1.5b")
    qwen2_5_coder_7b("qwen2.5-coder\:7b")
    end

    subgraph Embeddings["Embeddings"]
    nomic_embed_text("nomic-embed-text")
    end

    subgraph Cloud["Cloud"]
    kimi_k2_6("kimi-k2.6")
    end

    subgraph Tools["Tools"]
    Cline["Cline"]
    ZooCode["Zoo Code"]
    KiloCode["Kilo Code"]
    Aider["Aider"]
    Zed["Zed"]
    Cursor["Cursor"]
    OpenCode["OpenCode"]
    Continue["Continue"]
    ClaudeCode["Claude Code"]
    end

    qwen3_coder_next_80b_q4 -.->|default| Cline
    kimi_k2_6 -.->|cloud| Cline
    qwen3_coder_next_80b_q4 -.->|default| ZooCode
    kimi_k2_6 -.->|cloud| ZooCode
    qwen3_coder_next_80b_q4 -.->|code| ZooCode
    qwen3_6_35b_q4 -.->|architect| ZooCode
    qwen3_5_27b_q5 -.->|ask| ZooCode
    gemma4_31b -.->|debug| ZooCode
    qwen3_coder_next_80b_q4 -.->|default| KiloCode
    kimi_k2_6 -.->|cloud| KiloCode
    qwen3_coder_next_80b_q4 -.->|default| Aider
    qwen3_4b -.->|weak| Aider
    codestral_22b -.->|editor| Aider
    qwen3_coder_next_80b_q4 -.->|default| Zed
    qwen3_coder_next_80b_q4 -.->|default| Cursor
    kimi_k2_6 -.->|cloud| Cursor
    qwen3_coder_next_80b_q4 -.->|code| OpenCode
    qwen3_5_27b_q8 -.->|write| OpenCode
    qwen3_4b -.->|plan| OpenCode
    qwen3_5_27b_q5 -.->|research| OpenCode
    gemma4_31b -.->|think| OpenCode
    nomic_embed_text -.->|embed| Continue
    qwen3_5_27b_q8 -.->|chat_alt| Continue
    kimi_k2_6 -.->|kimi| Continue
    codestral_22b -.->|apply| Continue
    qwen3_coder_next_80b_q4 -.->|chat| Continue
    qwen2_5_coder_7b -.->|autocomplete_heavy| Continue
    qwen2_5_coder_1_5b -.->|autocomplete| Continue
    qwen3_4b -.->|fast| ClaudeCode
    qwen3_coder_30b_a3b_q6 -.->|coding| ClaudeCode
    qwen3_5_27b_q5 -.->|research| ClaudeCode
    qwen3_6_35b_q4 -.->|opus| ClaudeCode
    qwen3_coder_next_80b_q4 -.->|primary| ClaudeCode
    deepseek_r1_tools_32b -.->|reasoning| ClaudeCode

    classDef local fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,color:#0d47a1
    classDef cloud fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,color:#4a148c
    classDef tool fill:#fff3e0,stroke:#e65100,stroke-width:2px,color:#bf360c
    class codestral_22b local
    class deepseek_r1_tools_32b local
    class gemma4_31b local
    class kimi_k2_6 cloud
    class nomic_embed_text local
    class qwen2_5_coder_1_5b local
    class qwen2_5_coder_7b local
    class qwen3_coder_30b_a3b_q6 local
    class qwen3_coder_next_80b_q4 local
    class qwen3_5_27b_q5 local
    class qwen3_5_27b_q8 local
    class qwen3_6_35b_q4 local
    class qwen3_4b local
    class Cline tool
    class ZooCode tool
    class KiloCode tool
    class Aider tool
    class Zed tool
    class Cursor tool
    class OpenCode tool
    class Continue tool
    class ClaudeCode tool

    subgraph OpenRouterAvailable["OpenRouter (available)"]
    or_claude_opus_4_6("claude-opus-4-6")
    or_claude_sonnet_4_6("claude-sonnet-4-6")
    or_claude_haiku_4_5("claude-haiku-4-5")
    or_gpt_4o("gpt-4o")
    or_o3("o3")
    or_sonar_pro("sonar-pro")
    or_deepseek_v4_pro("deepseek-v4-pro")
    or_gemini_3_flash_preview("gemini-3-flash-preview")
    or_glm_5_1("glm-5.1")
    or_gpt_oss_120b("gpt-oss:120b")
    or_gpt_oss_20b("gpt-oss:20b")
    or_kimi_k2_6("kimi-k2.6")
    or_mistral_large_3("mistral-large-3")
    end
```

## OpenRouter (cloud)

The following models are available via OpenRouter but not stored locally:

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
Generated by `generate-model-map.sh` for profile `macbook-m5-64gb`. Edit `models.sh` and re-run to regenerate.
