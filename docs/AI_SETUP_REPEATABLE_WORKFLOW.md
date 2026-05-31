# AI Setup Repeatable Workflow

This document is the operational runbook for the macOS AI tooling installer in this repository.
It describes what actually exists, how the pieces fit together, and the repeatable steps for
installing, updating, and validating the AI tool stack.

The goal is to make future changes boring: update profile metadata first, validate all generated
and hand-maintained artifacts, install or rebuild models only through explicit wizard steps,
prune only when the user intentionally chooses a destructive sync path, and keep every claim
in this document grounded in real scripts.

## Operating Principles

- `setup_ai.sh` behaves like a wizard. Profile detection, infrastructure choice, local model install, config deployment, optional tools, verification, and summary are visible steps.
- `ai/profiles/<profile>/models.sh` is the source of truth for local model aliases, Hugging Face sources, GGUF filenames, quants, context windows, and tool-role assignments.
- Install/update must be non-destructive by default. Removing local models belongs only in explicit prune or sync actions.
- Pre-built tool configs should remain readable and diffable. Validate them against `models.sh` instead of turning the entire profile into a template engine.
- Exact remote metadata beats guessing. Hugging Face GGUF downloads should use profile-declared remote filenames whenever available.
- Local control is the default. OpenRouter is the cloud companion path, not a replacement for the local Ollama/GGUF stack.
- The llama-router (llama.cpp router mode on port 10000) is a separate, co-equal inference path for tools that benefit from direct GGUF serving without the Ollama wrapper.

## Current Architecture Snapshot

The May 2026 refresh removed LiteLLM from the local routing layer. Local inference now has
two co-equal paths:

```text
Before:
  Tools -> :4000 LiteLLM -> :11434 Ollama
                         -> OpenRouter

After:
  Tools -> :11434/v1 Ollama OpenAI-compatible API     (Ollama-managed models)
  Tools -> :10000/v1  llama-server router mode         (direct GGUF serving)
  Tools -> OpenRouter native provider blocks            (cloud models)
```

### Ollama path (`:11434`)

The primary local inference path for most tools. Models are registered via `ollama create` from
local GGUF artifacts. The registration uses `FROM hf.co/<repo>:<remote_filename>` so Ollama
fetches the model manifest directly from Hugging Face, preserving Jinja2 chat templates and
tool-calling capabilities.

- Used by: Continue, OpenCode, Claude Code, Cline, Aider, Gemini, Grok, Zed, Crush, Kilo Code
- Context variants (e.g. `qwen3-coder-30b-a3b:q6-128k`) are lightweight aliases sharing the same weights

### llama-router path (`:10000`)

A separate [`llama-server`](https://github.com/ggerganov/llama.cpp) instance running in
**router mode** with dynamic model loading. It serves GGUFs directly from
`/usr/local/lib/llama-models`, bypassing Ollama entirely.

- Three named presets defined in `models.ini`: `deepseek-r1-32b` (reasoning), `qwen3-4b-it` (fast),
  `qwen3-coder-30b` (coding)
- Six auto-discovered models from filenames in the models directory
- `--models-max 1` by default (one model resident at a time on 64 GB)
- Managed as a LaunchAgent (`org.kehle.llama-router`) — starts at login, restart on crash
- Used by: Open WebUI (Colima Docker) and any tool that can point at `http://host.docker.internal:10000`
- Build from source at `~/code/llama.cpp` (Metal, `-march=native`, Accelerate)

### Consequences of the LiteLLM removal

- No local LiteLLM proxy is required for normal AI tool routing.
- No LiteLLM Python venv or Postgres container is required for model routing.
- No `:4000` base URL should remain in AI tool configs.
- Local model names should stay in plain Ollama form, such as `qwen3-coder-30b-a3b:q6`.
- OpenRouter entries can remain provider-specific, such as `anthropic/claude-sonnet-4-6`, where a tool supports OpenRouter provider blocks.

## Primary Artifacts

| Artifact                                         | Role                                                                                                             |
| ------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `setup_ai.sh`                                    | Top-level wizard, command dispatcher, config deploy orchestration, optional tool selection.                      |
| `helpers.sh`                                     | Shared logging, shell utilities, platform helpers, and status functions.                                         |
| `ai/runtimes/paths.sh`                                  | Shared model/cache paths and binary defaults such as `HF_CLI_BIN`, `GGUF_DIR`, and Hugging Face cache paths.     |
| `ai/cloud/huggingface.sh`                            | Hugging Face CLI installation and auth verification helpers.                                                     |
| `ai/runtimes/install-models.sh`                         | GGUF materialization, Ollama registration, context alias reconciliation, cloud manifests, pre-flight validation. |
| `ai/runtimes/validate-profile.sh`                       | Profile metadata validation and drift detection.                                                                 |
| `ai/router/build.sh`                     | Pulls latest llama.cpp, rebuilds llama-server with Metal, deploys to `/usr/local/bin`.                           |
| `ai/router/setup.sh`                     | Verifies llama-server, auto-detects GGUF filenames, patches `models.ini`, installs LaunchAgent.                  |
| `ai/router/models.ini`                   | Router preset definitions (3 named models: reasoning, fast, coding).                                             |
| `ai/router/org.kehle.llama-router.plist` | launchd LaunchAgent — starts llama-server router at login.                                                       |
| `ai/router/README.md`                    | Quick-start, model table, and source references.                                                                 |
| `ai/router/tuning-guide.md`              | M5 Max 64GB performance tuning: GPU offload, KV cache, flash attention, benchmarks.                              |
| `ai/router/open-webui-integration.md`    | Connecting Open WebUI to three backends — router, Ollama, OpenRouter.                                            |
| `ai/profiles/<profile>/models.sh`              | Source of truth for local and cloud model inventories plus per-tool role mappings.                               |
| `ai/profiles/<profile>/model-map.md`           | Generated profile-specific model map with tool matrix, Hugging Face materialization table, and Mermaid graph.    |
| `ai/profiles/generate-model-map.sh`            | Generator for all per-profile model maps.                                                                        |
| `ai/profiles/CONFIG_SCHEMA.md`                 | Canonical schema reference for profile variables and downstream config expectations.                             |
| `docs/llama-router-testing.md`                   | Router health verification: model listing, chat completions, LaunchAgent, restart cycle, smoke test.             |

## Source-of-Truth Contract

Every profile has exactly one `models.sh` that defines the canonical inventory and tool assignments. Scripts may source it, validate it, and derive required model lists from it. Scripts should not silently invent alternate names that are not represented in the profile metadata.

### Local inventory

Use these declarations to describe local models:

| Variable                 | Purpose                                                                                                                                       |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `LOCAL_MODEL_NAMES`      | Canonical local Ollama aliases for the profile.                                                                                               |
| `GGUF_SOURCES`           | Alias to Hugging Face repo mapping, usually `hf.co/org/repo` or `org/repo`.                                                                   |
| `GGUF_QUANTS`            | Alias to quant label mapping, such as `Q4_K_M`, `Q6_K`, or `UD-Q6_K_XL`.                                                                      |
| `GGUF_LOCAL_FILENAMES`   | Alias to normalized local `.gguf` filename under `${GGUF_DIR}`.                                                                               |
| `GGUF_REMOTE_FILENAMES`  | Alias to exact remote filename in the Hugging Face repo.                                                                                      |
| `GGUF_FILENAMES`         | Legacy local filename map. Keep compatibility if present, but prefer split local/remote filename maps.                                        |
| `GGUF_FAMILIES`          | Alias to family mapping for registration defaults, such as `coder`, `embedding`, `reasoning-tools`, or `instruct`.                            |
| `GGUF_VARIANTS`          | Optional extra alias, quant, local filename, source, and remote filename records.                                                             |
| `MODELFILE_PARAMS`       | Extra Ollama `PARAMETER` lines for a model family or alias. Literal `\n` sequences must be converted to real newlines before `ollama create`. |
| `OLLAMA_CONTEXT_WINDOWS` | Alias to context window list. The first value is the base alias context; later values become context suffix aliases.                          |

### Cloud inventory

Cloud declarations stay explicit and separate from local GGUF-backed aliases:

| Variable              | Purpose                                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------------------- |
| `OPENROUTER_MODELS`   | OpenRouter model IDs used by tools that support OpenRouter provider blocks.                             |
| `OLLAMA_CLOUD_MODELS` | Ollama cloud model manifests, such as `model:cloud`, when those manifests are installed through Ollama. |

### Tool role maps

Tool assignments should be associative maps where possible:

| Variable                                   | Used by                                                             |
| ------------------------------------------ | ------------------------------------------------------------------- |
| `OPENCODE_AGENTS`                          | OpenCode agent role assignments.                                    |
| `CONTINUE_ROLES`                           | Continue chat, edit, apply, autocomplete, embed, and related roles. |
| `CLAUDE_CODE`                              | Claude Code local model defaults and role aliases.                  |
| `CLINE_MODELS`                             | Cline model references.                                             |
| `ZOOCODE_MODELS`                           | ZooCode model references.                                           |
| `ROOCODE_MODEL_CLOUD` and `ROOCODE_MODE_*` | Roo Code cloud and per-mode model references.                       |
| `KILOCODE_MODELS`                          | Kilo Code model references.                                         |
| `AIDER_MODELS`                             | Aider main, weak, and editor model references.                      |
| `ZED_MODELS`                               | Zed assistant model references.                                     |
| `CURSOR_MODELS`                            | Cursor local/cloud model references.                                |

### Naming rules

- Local aliases use plain Ollama `model:tag` format.
- Do not append `:latest` in configs. Bare names should resolve naturally where the tool supports them.
- Do not use old LiteLLM hyphen aliases for local models.
- OpenCode model values need provider prefixes where the config schema expects them, such as `ollama/qwen3:4b` or `openrouter/anthropic/claude-sonnet-4-6`.
- A local model reference is valid only if it resolves through `LOCAL_MODEL_NAMES`, derived `GGUF_VARIANTS`, or a generated context alias.
- A cloud model reference is valid only if it resolves through `OPENROUTER_MODELS` or `OLLAMA_CLOUD_MODELS`.

## Wizard Flow

The preferred user-facing flow is:

```bash
./setup_ai.sh deploy
./setup_ai.sh models
```

The implementation should keep these wizard steps distinct:

1. Detect machine and profile.
2. Select infrastructure, typically Ollama plus OpenRouter plus optional OpenWebUI.
3. Deploy per-tool configs and validate them against `models.sh`.
4. Ask whether to install or update local models if the user has not already chosen that command.
5. Materialize Hugging Face GGUF files.
6. Register or rebuild Ollama local models from GGUF artifacts.
7. Reconcile context aliases and cloud manifests.
8. Offer optional tools through explicit selectors.
9. Summarize installed, skipped, missing, and failed items.

Important flow constraints:

- If the user already selected a model install/update path, do not ask again at the end.
- Do not show a redundant “Local Model Plan” prompt after the user just completed the model update.
- Do not open a separate local model manager if it only duplicates the wizard step.
- Do not prune during install/update. Only prune from an explicit prune or sync path.
- If a sync path includes pruning, label it clearly before the user confirms.

## Hugging Face GGUF Materialization

The GGUF materialization step should be idempotent and explicit.

For each desired model spec, log:

- Ollama alias being prepared.
- Profile family.
- Quant.
- Hugging Face repo.
- Exact remote filename, if declared.
- Local target filename.
- Whether the file was already present, downloaded, renamed, skipped, or failed.

Preferred resolution order:

1. Use `GGUF_REMOTE_FILENAMES[alias]` or the remote filename embedded in `GGUF_VARIANTS`.
2. Use `GGUF_LOCAL_FILENAMES[alias]` or `GGUF_FILENAMES[alias]` for the local target.
3. Only if remote metadata is missing, guess the remote filename from repo basename plus quant.
4. When guessing, print a warning because many Hugging Face repos do not follow a predictable naming convention.

Use `HF_CLI_BIN` from `ai/runtimes/paths.sh`. The CLI is now `hf` (not the deprecated `huggingface-cli`). Install via `uv tool install "huggingface_hub[hf_xet,cli]"`. Auth: `hf auth login`.

All GGUF files are downloaded to `GGUF_DIR` (`/usr/local/lib/llama-models`). The directory is
owned by the user (`isaac:staff`) so no `sudo` is needed for model downloads.

Failure messages should distinguish:

- Hugging Face CLI missing.
- Hugging Face CLI present but user may not be logged in.
- Requested remote file does not exist.
- Download command failed.
- Download command succeeded but the expected local target is missing.
- Local target already exists.

### Hugging Face auth helper

The wizard-friendly helper should be non-invasive:

```bash
verify_hf_auth() {
  local hf_bin="${HF_CLI_BIN:-hf}"

  if ! command -v "$hf_bin" >/dev/null 2>&1; then
    warn "HF CLI not installed; gated model downloads will be skipped."
    return 1
  fi

  if "$hf_bin" auth whoami >/dev/null 2>&1; then
    ok "Hugging Face CLI is authenticated."
    return 0
  fi

  warn "Hugging Face CLI is installed but not authenticated."
  info "Run: $hf_bin auth login"
  info "Gated models will fail until your Hugging Face token is configured."
  return 1
}
```

This helper should print a hint, not force login, because login is user-account state.

## Ollama Registration and Context Aliases

Ollama registration converts local GGUF artifacts into usable Ollama model aliases.

**Critical:** Modelfiles must use `FROM hf.co/<repo>:<remote_filename>` rather than a bare local GGUF path. Bare paths cause Ollama to drop the embedded Jinja2 chat template and lose tool-calling capability. The HF reference causes Ollama to fetch the model manifest directly from Hugging Face, preserving the model author's intended Jinja2 template and tool-calling setup.

**Never override the GGUF-embedded template with a template file.** Previous versions of this pipeline used `OLLAMA_MODELFILE_TEMPLATES` to inject custom TEMPLATE blocks, but this replaced the model author's correct template with a generic one — breaking tool-calling in tools like OpenCode. The `FROM hf.co/...` approach handles templates correctly without any override.

The registration step:

- Constructs the HF reference from `GGUF_SOURCES[alias]` and `GGUF_REMOTE_FILENAMES[alias]`.
- Generates a minimal Modelfile with only the HF reference, PARAMETER lines, and no TEMPLATE block (the GGUF-embedded template is used).
- Converts literal `\n` sequences in parameter strings into real newlines before calling `ollama create`.

Context variants are lightweight Ollama aliases sharing the same underlying model weights. They are created by `reconcile_ollama_aliases` using `ollama show --modelfile <base>` so the template is inherited.

Example final Modelfile:

```text
FROM hf.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf
PARAMETER num_ctx 32768
PARAMETER temperature 0
PARAMETER repeat_penalty 1.05
```

If `ollama create` reports an invalid float containing a literal `\n`, the Modelfile was not reflowed correctly. Normalize parameters before writing the Modelfile.

## Rebuild and Prune Policy

There are three separate operations:

| Operation             | Destructive | Meaning                                                                                |
| --------------------- | ----------- | -------------------------------------------------------------------------------------- |
| Install/update        | No          | Download missing GGUFs, register or rebuild declared local aliases, reconcile aliases. |
| Rebuild Ollama models | No          | Recreate Ollama aliases from already installed GGUF artifacts.                         |
| Prune or sync         | Yes         | Remove models not represented in the selected profile or chosen sync plan.             |

Rules:

- `setup_ai.sh deploy` may offer model install/update, but should not prune unless the user selected a sync/prune action.
- “Install and do not prune” must never remove existing Ollama models.
- “Sync” may prune, but only after an explicit destructive confirmation.
- If prune runs, every deletion should be listed before or during the operation.

## Generated Model Maps

Each profile has a generated model map:

```text
ai/profiles/<profile>/model-map.md
```

The map should include:

- Model assignment matrix by tool and role.
- Local model categories.
- OpenRouter cloud model list where defined.
- Hugging Face to remote GGUF to local GGUF to Ollama alias materialization table.
- Renames from remote GGUF filename to normalized local filename.
- Context alias expansion.
- Mermaid graph for the materialization flow.

Regenerate maps after any model metadata change:

```bash
for p in macbook-m1-16gb macbook-m2-32gb macbook-m5-48gb macbook-m5-64gb macmini-m2-16gb; do
  /opt/homebrew/bin/bash ai/profiles/generate-model-map.sh "$p"
done
```

The old `model-map-ollama.md` suffix should not be used. Use `model-map.md` because the map now covers Hugging Face, GGUF local artifacts, Ollama aliases, context variants, and tool assignments.

## Profile Sizing and Memory Headroom

Profile sizing should reserve memory for macOS, editors, browsers, Ollama runtime, KV cache growth, embeddings, autocomplete, and occasional model overlap.

| Machine class | Total RAM | Suggested non-model reserve                                      | Practical model budget |
| ------------- | --------: | ---------------------------------------------------------------- | ---------------------: |
| Lightweight   |     16 GB | 6 GB base reserve plus extra caution for browser/editor load     |                 ~10 GB |
| Medium        |     32 GB | 6 GB base reserve                                                |                 ~26 GB |
| Powerful      |     48 GB | 6 GB base reserve                                                |                 ~42 GB |
| Maximum       |     64 GB | 10 GB combined reserve for macOS plus Ollama/runtime concurrency |                 ~54 GB |

Current `qwen3.5-27b:q8` placement:

- 16 GB profiles: do not expose it.
- 32 GB profile: do not expose it.
- 48 GB profile: keep it out of defaults and normal tool catalogs for now.
- 64 GB profile: keep it for now as a large writing/manual alternate.

When moving a model between profiles:

1. Update `models.sh`.
2. Update all role maps.
3. Update hand-maintained config files.
4. Regenerate `model-map.md`.
5. Run stale-reference and duplicate model-id checks.
6. Run profile validation for all affected profiles.

## Profile Notes

### 16 GB profiles

Applies to `macbook-m1-16gb` and `macmini-m2-16gb`.

- Keep the resident local set small.
- Prefer 4B to 14B for always-available planning/fast tasks.
- Avoid 27B/Q8 and other large writing models.
- Treat large coding or reasoning models as solo or cloud-assisted workflows.
- Consider oMLX only as an experimental alternative where SSD-backed KV cache helps.

### 32 GB profile

Applies to `macbook-m2-32gb`.

- Use medium local coding and reasoning models.
- Keep very large writing models out of default catalogs if they threaten co-residency.
- Do not include `qwen3.5-27b:q8` for now.

### 48 GB profile

Applies to `macbook-m5-48gb`.

- Strong local coding and agent roles are reasonable.
- Large writing models can exist as explicit alternates if memory pressure remains controlled.
- Do not default to `qwen3.5-27b:q8` unless the profile is intentionally retuned.

### 64 GB profile

Applies to `macbook-m5-64gb`.

- This is the widest profile and can keep large coding, writing, reasoning, embeddings, and cloud options.
- `qwen3-coder-next-80b:q4` belongs here as a solo or heavyweight coding path.
- `qwen3-coder-30b-a3b:q6` is the practical coding model.
- `qwen3.5-27b:q8` stays for now as a manual large writing alternate.

## Downstream Tool Config Contract

The repo keeps pre-built per-profile configs. The deploy step should copy or merge them, then validate that model names resolve to the profile source of truth.

| Config                     | Expectation                                                                                                                                         |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ollama/config.json`       | Integration aliases and model lists match local aliases and context variants.                                                                       |
| `claude/settings.json`     | `ANTHROPIC_BASE_URL` points at Ollama, usually `http://localhost:11434`; model env vars use local aliases.                                          |
| `continue/config.yaml`     | Local entries point at Ollama; cloud entries use OpenRouter where configured.                                                                       |
| `opencode/opencode.jsonc`  | Single Ollama-only config, no variants. Provider-prefixed model references (`ollama/` + `openrouter/`), agents assigned to role-appropriate models. |
| `gemini/settings.json`     | Ollama provider points at `http://localhost:11434/v1`; OpenRouter entries are explicit if present.                                                  |
| `grok/grok.json`           | Ollama and OpenRouter provider blocks are both allowed; base URLs must match tool expectations.                                                     |
| `groq/local-settings.json` | Cloud-only Groq settings, no local Ollama assumptions unless intentionally added.                                                                   |
| `crush/crush.json`         | Ollama OpenAI-compatible provider, no duplicate model IDs.                                                                                          |
| `aider/aider.conf.yml`     | Uses the expected Ollama prefix syntax for Aider.                                                                                                   |
| `zed/settings.json`        | Local model list and assistant default match profile assignments.                                                                                   |
| `cursor/settings.jsonc`    | Comments and custom model references match current local/cloud inventory.                                                                           |
| `cline/settings.jsonc`     | References only models available through local or declared cloud inventory.                                                                         |
| `roocode/settings.jsonc`   | Each mode resolves to declared local or cloud models.                                                                                               |
| `kilocode/kilo.jsonc`      | Single Ollama-only config, no variants. Models listed by purpose (role), not by context window size. Agent/model references resolve.                |
| `zoocode/settings.jsonc`   | VS Code merge content matches the profile model schema.                                                                                             |

Deploy-time validation should warn on stale models, but the target is zero drift warnings for the active profile.

## Optional Tool Installer Policy

Some terminal agents overlap heavily. They should not be silently installed by bundles.

Always use the fzf selector for these tools:

- Plandex
- OpenClaw
- IronClaw
- Hermes
- PicoClaw
- ZeroClaw

This policy applies to:

- Recommended bundles.
- Group installs.
- Legacy interactive menu paths.
- Direct commands such as `./setup_ai.sh plandex`.
- Internal `_run_one setup:<tool>` dispatch.

If `fzf` is missing, fail clearly and suggest:

```bash
brew install fzf
```

### Claw and related tool notes

| Tool     | Install method                          | Setup command                       | Category                 |
| -------- | --------------------------------------- | ----------------------------------- | ------------------------ |
| OpenClaw | `npm install -g openclaw@latest`        | `openclaw onboard --install-daemon` | agent                    |
| ZeroClaw | Installer script from ZeroClaw releases | `zeroclaw onboard`                  | agent                    |
| IronClaw | `brew install ironclaw` or Cargo build  | `ironclaw onboard`                  | agent                    |
| Hermes   | Installer script from NousResearch      | `hermes setup`                      | agent                    |
| PicoClaw | Go install or binary download           | Config via TOML                     | embedded/edge            |
| ZooCode  | VS Code settings merge                  | no standalone binary                | VS Code extension config |

## Tool Scout Direction

The long-term direction is a unified `tool-scout` that can discover, add, update, and remove tools across multiple categories.

Target categories:

- `terminal-agents`: AI CLI tools, including the Claw family.
- `vscode-extensions`: Continue, Cline, Roo Code, Kilo Code, and related editor extensions.
- `mcp-servers`: MCP servers from GitHub or npm.
- `cli-devtools`: General CLI development tools.
- `ollama-models`: Local model candidates.
- `brew-formulae`: Homebrew packages related to AI and development.

Target commands:

```bash
tool-scout list
tool-scout list --category mcp-servers
tool-scout search <query>
tool-scout add <name>
tool-scout update <name>
tool-scout remove <name>
tool-scout sync
tool-scout find-mcp <query>
tool-scout find-vscode <query>
tool-scout find-brew <query>
```

The catalog should be human-editable, PR-friendly, and versioned independently from generated scripts.

## oMLX Experimental Path

oMLX is an optional MLX-native inference path, mainly interesting for 16 GB Apple Silicon machines. It exposes an OpenAI-compatible API on `:8000` and supports Anthropic Messages on `/v1/messages`.

Current stance:

- Ollama remains the default local runtime for 48 GB and 64 GB profiles.
- Ollama remains the simpler default unless oMLX is explicitly selected.
- oMLX is most interesting for `macmini-m2-16gb` and potentially `macbook-m1-16gb`.
- oMLX work should not disrupt the canonical GGUF-backed Ollama metadata contract.

Potential MLX equivalents for constrained profiles:

| Ollama role    | Candidate MLX model                                | Notes                                                    |
| -------------- | -------------------------------------------------- | -------------------------------------------------------- |
| Primary coding | `mlx-community/Qwen2.5-Coder-7B-Instruct-4bit`     | About 4.28 GB, practical 7B coding path.                 |
| Heavy coding   | `Qwen/Qwen3-14B-MLX-4bit`                          | About 7.75 GB, solo mode on 16 GB.                       |
| Reasoning      | `mlx-community/DeepSeek-R1-Distill-Qwen-7B-4bit`   | About 4.28 GB, on-demand reasoning.                      |
| Planning       | `Qwen/Qwen3-4B-MLX-4bit`                           | About 2.14 GB.                                           |
| Autocomplete   | `mlx-community/Qwen2.5-Coder-1.5B-Instruct-4bit`   | About 869 MB.                                            |
| Embeddings     | `mlx-community/nomicai-modernbert-embed-base-8bit` | About 160 MB, attractive Nomic-aligned embedding option. |
| Code apply     | `mlx-community/Codestral-22B-v0.1-4bit`            | About 12.5 GB, on-demand only on 16 GB.                  |

Open oMLX questions:

- Should downloads be driven by oMLX UI, Hugging Face CLI, or git-lfs?
- Which embedding model should become the default?
- Should the 7B coding model use 3-bit or 4-bit for extra headroom?
- Does Continue autocomplete perform well through oMLX's OpenAI-compatible endpoint?
- Which environment variables should replace Ollama-specific profile settings?

## Model Refresh Cadence

Run a model refresh every 3 to 6 months, or when a major model family changes enough to justify profile churn.

Refresh process:

1. Research new local and cloud models.
2. Decide whether each new model supersedes an existing profile role.
3. Check memory co-residency for each profile class.
4. Remove redundant or unused model options.
5. Update `models.sh` first.
6. Update downstream tool configs.
7. Regenerate `model-map.md`.
8. Run validation across all profiles.
9. Install or rebuild local models.
10. Prune only if intentionally syncing a profile.

For the current naming generation:

- Maximum coding on 64 GB: `qwen3-coder-next-80b:q4`.
- Practical coding on 64 GB: `qwen3-coder-30b-a3b:q6`.
- Writing/default local path: `qwen3.5-27b:q4` unless a profile explicitly retains a larger manual alternate.
- Fast/planning: `qwen3:4b`.
- Embeddings: `nomic-embed-text`.

## New Machine Bootstrap

High-level bootstrap for a new Mac:

```bash
git clone <repo-url> ~/code/isaackehle/settings
cd ~/code/isaackehle/settings

# 1. Build and deploy the llama-server router (if desired)
cd ai/router
./build.sh
./setup.sh
cd ../..

# 2. Profile-aware AI tool setup
./setup_ai.sh deploy
./setup_ai.sh models
```

If troubleshooting by component:

```bash
source helpers.sh
/opt/homebrew/bin/bash ai/runtimes/ollama.sh
/opt/homebrew/bin/bash ai/cloud/huggingface.sh
/opt/homebrew/bin/bash ai/runtimes/install-models.sh
```

Prefer the wizard path for normal use so profile detection, validation, and user confirmations remain consistent.

After bootstrap, verify the router:

```bash
curl -s http://127.0.0.1:10000/v1/models | jq '.data[].id'
```

See `docs/llama-router-testing.md` for full verification commands.

## Router Health Checks

After bootstrap or rebuild:

```shell
# List available models (expected: 9 — 3 named presets + 6 auto-discovered)
curl -s http://127.0.0.1:10000/v1/models | jq '.data[].id'

# LaunchAgent health (should show PID, exit code 0)
launchctl list | grep llama-router

# Chat completion smoke test
curl -s http://127.0.0.1:10000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"qwen3-4b-it","messages":[{"role":"user","content":"Hi"}]}' \
  | jq -r '.choices[0].message.content'
```

See `docs/llama-router-testing.md` for the full test suite (per-model chat completions,
logs, restart cycle, one-liner smoke test).

## Validation Checklist

Run syntax checks:

```bash
/opt/homebrew/bin/bash -n \
  setup_ai.sh \
  helpers.sh \
  ai/profiles/generate-model-map.sh \
  ai/runtimes/install-models.sh \
  ai/runtimes/validate-profile.sh \
  ai/profiles/*/models.sh
```

Scan for stale names from this refactor:

```bash
/opt/homebrew/bin/rg -n \
  'qwen3\.5-27b:q5|qwen3\.6-35b:q4|model-map-ollama|:4000|litellm|llama-cpp\.sh|:801[1-5]|Models/gguf' \
  setup_ai.sh 2-ai docs \
  -g '!docs/WORKSTREAM_2026-05-23.md' \
  -g '!ai/profiles/CONFIG_SCHEMA.md'
```

Regenerate model maps:

```bash
for p in macbook-m1-16gb macbook-m2-32gb macbook-m5-48gb macbook-m5-64gb macmini-m2-16gb; do
  /opt/homebrew/bin/bash ai/profiles/generate-model-map.sh "$p"
done
```

Validate profiles:

```bash
for p in macbook-m1-16gb macbook-m2-32gb macbook-m5-48gb macbook-m5-64gb macmini-m2-16gb; do
  echo "--- $p ---"
  MACHINE_PROFILE="$p" /opt/homebrew/bin/bash ai/runtimes/validate-profile.sh
done
```

Expected profile validation state after the current refactor:

- `macbook-m1-16gb`: missing-local-artifact warnings are acceptable, errors must be zero.
- `macbook-m2-32gb`: missing-local-artifact warnings are acceptable, errors must be zero.
- `macbook-m5-48gb`: missing-local-artifact warnings are acceptable, errors must be zero.
- `macbook-m5-64gb`: should validate with zero warnings and zero errors on the current fully populated machine.
- `macmini-m2-16gb`: missing-local-artifact warnings are acceptable, errors must be zero.

Use a focused duplicate model-id scan instead of a naive duplicate-key scan. Keys such as `name` repeat legitimately in separate JSON objects, but duplicate model IDs inside one provider list are usually drift.

## Known Local Shell Noise

When running through `pc bash`, shell startup may emit unrelated errors from `fnm`, `pyenv`, `oh-my-zsh`, or `zoxide` trying to write protected paths. Treat those as environment noise unless the target script exits nonzero or emits a script-specific error.

## Future Work

- Keep refining the wizard so each step is explicit, idempotent, and non-destructive unless clearly labeled otherwise.
- Continue improving colored logging for warnings, errors, skips, and success states.
- Template hash tracking is now dead code (no template overrides remain). Consider removing the template hash tracking functions from `install-models.sh`.
- Add or maintain `verify_hf_auth` so gated model failures are explained before long download attempts.
- Keep the generated `model-map.md` files current and include Mermaid diagrams for every profile.
- Revisit whether `qwen3.5-27b:q8` should remain in the 64 GB profile after real-world memory pressure is observed.
- Decide whether oMLX deserves a first-class experimental profile or remains a research note.
- Continue moving optional overlapping tools behind the fzf selection gate.
- Keep the repeatable workflow document updated whenever a workstream note graduates into operational policy.
