---
tags: [ai, coding, productivity, nvidia, security, agents]
---

# <img src="https://github.com/nvidia.png" width="24" style="vertical-align: middle; border-radius: 4px;" /> OpenShell

NVIDIA's open-source sandboxed runtime for running autonomous AI coding agents safely. Wraps agents like Claude Code, OpenCode, and Codex in an isolated container with declarative YAML policies controlling filesystem, network, and process access.

- **GitHub:** [NVIDIA/OpenShell](https://github.com/NVIDIA/OpenShell)
- **Status:** Alpha (single-user, not production-ready for enterprise)

## How It Works

OpenShell runs on K3s inside a single Docker container. Each sandbox gets its own isolated container with a policy engine that intercepts and enforces all outbound connections. Credentials are injected as environment variables — they never appear in the sandbox filesystem.

## Installation

```shell
# Binary (recommended)
curl -LsSf https://raw.githubusercontent.com/NVIDIA/OpenShell/main/install.sh | sh

# PyPI
uv tool install -U openshell
```

**Prerequisite:** Docker running locally.

## Quick Start

```shell
# Launch a sandbox with Claude Code
openshell sandbox create -- claude

# Launch with OpenCode
openshell sandbox create -- opencode

# Launch with Codex or Copilot CLI
openshell sandbox create -- codex
openshell sandbox create -- copilot
```

## CLI Reference

| Command | Purpose |
| --- | --- |
| `openshell sandbox create -- <agent>` | Launch sandbox with agent |
| `openshell sandbox connect [name]` | SSH into running sandbox |
| `openshell sandbox list` | View all sandboxes |
| `openshell sandbox create --remote user@host -- claude` | Deploy to remote host |
| `openshell policy get <name>` | Display active policy |
| `openshell policy set <name> --policy file.yaml --wait` | Apply/update a policy |
| `openshell logs [name] --tail` | Stream sandbox logs |
| `openshell term` | Open real-time terminal dashboard |

## Providers (Credentials)

Providers are named credential bundles auto-discovered from environment variables:

```shell
openshell provider create --type anthropic --from-existing
openshell provider create --type openai --from-existing
openshell provider create --type github --from-existing    # Copilot CLI
openshell provider create --type openrouter --from-existing
```

Supported providers: Anthropic, OpenAI, GitHub, OpenRouter, Ollama.

## Policies

Sandboxes start locked down. Apply YAML policies to open up access:

```shell
openshell policy set my-sandbox --policy policy.yaml --wait
```

Network and inference policies hot-reload without restarting the sandbox. Filesystem and process constraints are locked at creation.

Example policy structure:

```yaml
# policy.yaml
network:
  egress:
    - host: "api.anthropic.com"
      methods: [GET, POST]
    - host: "github.com"
      methods: [GET]
inference:
  routing:
    - pattern: "api.openai.com"
      backend: "http://localhost:11434/v1"  # redirect to Ollama
```

## Custom Sandboxes

```shell
# Community catalog image
openshell sandbox create --from openclaw

# Local Dockerfile/directory
openshell sandbox create --from ./my-sandbox-dir

# Container registry image
openshell sandbox create --from registry.io/img:v1
```

## GPU Support (Experimental)

```shell
openshell sandbox create --gpu --from <gpu-enabled-image> -- claude
```

Requires NVIDIA drivers and NVIDIA Container Toolkit on the host.

## Default Sandbox Contents

Each sandbox ships with:
- **Agents:** `claude`, `opencode`, `codex`, `copilot`
- **Languages:** Python 3.13, Node 22
- **Dev tools:** `gh`, `git`, `vim`, `nano`
- **Network tools:** `ping`, `dig`, `nc`, `traceroute`

## References

- [GitHub](https://github.com/NVIDIA/OpenShell)
- [NVIDIA Build](https://build.nvidia.com/openshell)
