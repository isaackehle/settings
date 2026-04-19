---
tags: [ai, llm, proxy, local]
---

# LiteLLM

Unified OpenAI-compatible proxy in front of Ollama (and other providers). Exposes a single `:4000` endpoint with spend tracking, rate limiting, and a web UI.

## Prerequisites

- [uv](https://docs.astral.sh/uv/) installed (`brew install uv`)
- Docker runtime: **Rancher Desktop** or **Colima** (for PostgreSQL)
- Ollama running on `localhost:11434`

## Installation

```shell
uv tool install 'litellm[proxy]'
```

## PostgreSQL (Docker — Rancher Desktop or Colima)

PostgreSQL is required for the web UI, spend tracking, and model management. Run it as a container — no native install needed.

```shell
# Start the container (works with both Rancher Desktop and Colima)
docker run -d \
  --name litellm-postgres \
  --restart unless-stopped \
  -e POSTGRES_DB=litellm_db \
  -e POSTGRES_USER=litellm \
  -e POSTGRES_PASSWORD=litellm \
  -p 5432:5432 \
  postgres:16

# Verify it's running
docker ps | grep litellm-postgres
```

Stop / start without losing data:

```shell
docker stop litellm-postgres
docker start litellm-postgres
```

## Prisma Client

LiteLLM uses Prisma to talk to Postgres. Generate the client once after install (re-run after upgrades):

```shell
# Find the schema path (Python version may differ)
find $(uv tool dir litellm) -name "schema.prisma" -path "*/litellm/*"

# Generate (replace path with output above)
python -m prisma generate --schema $(find $(uv tool dir litellm) -name "schema.prisma" -path "*/litellm/*" | head -1)
```

## Environment

Create `~/.config/litellm/.env`:

```shell
# LiteLLM
LITELLM_MASTER_KEY="sk-local"
LITELLM_SALT_KEY="sk-local-salt"
LITELLM_DROP_PARAMS=True
STORE_MODEL_IN_DB=True
PORT=4000

# Database
DATABASE_URL=postgresql://litellm:litellm@localhost:5432/litellm_db

# API keys (add as needed)
# OPENAI_API_KEY="sk-..."
# ANTHROPIC_API_KEY="sk-ant-..."
# GROQ_API_KEY="gsk_..."
```

## Start

```shell
litellm --config ~/.config/litellm/config.yaml --port 4000
```

Web UI: `http://localhost:4000`

## Config

Config lives at `~/.config/litellm/config.yaml` — see [[config/litellm/litellm.yaml]] for the full model list.

```yaml
litellm_settings:
  drop_params: true

general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/DATABASE_URL
```

## Database Management

```shell
# Connect
docker exec -it litellm-postgres psql -U litellm -d litellm_db

# List tables
\dt

# View spend logs
SELECT * FROM "LiteLLM_SpendLogs" LIMIT 10;

# Clear logs/spend (stop LiteLLM first)
TRUNCATE TABLE "LiteLLM_SpendLogs" RESTART IDENTITY;
TRUNCATE TABLE "LiteLLM_AuditLog" RESTART IDENTITY;
TRUNCATE TABLE "LiteLLM_ErrorLogs" RESTART IDENTITY;

# Exit
\q
```

Reset database entirely:

```shell
docker stop litellm-postgres
docker rm litellm-postgres
# Re-run the docker run command above — LiteLLM recreates tables on next start
```

## Alias

Add to `~/.zshrc`:

```shell
alias litellm-start="litellm --config ~/.config/litellm/config.yaml --port 4000"
```

## Troubleshooting

| Problem | Fix |
|---|---|
| `command not found: litellm` | `uv tool install 'litellm[proxy]'` |
| `ModuleNotFoundError: prisma` | `uv tool run --from litellm pip install prisma` |
| `The Client hasn't been generated yet` | Re-run Prisma generate above |
| `Database connection failed` | `docker start litellm-postgres` |
| `Port 4000 already in use` | `--port 4001` |

## References

- [LiteLLM docs](https://docs.litellm.ai/)
- [Proxy quick start](https://docs.litellm.ai/docs/proxy/quick_start)
- [Docker deploy](https://docs.litellm.ai/docs/proxy/deploy)
