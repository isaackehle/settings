---
tags: [development, ai, agents]
---

# [Project Name] — Backend Agent Instructions

> **Canonical instructions.** This file overrides any conflicting directives
> in tool-specific config files (Cursor rules, Copilot instructions, etc.).

<!-- markdownlint-disable MD013 -->

## Purpose

<!--
Describe what this service does and its role in the broader system.
Example: "Async REST API powering the [App] platform. Owns auth, LLM
orchestration, and vector-search endpoints."
-->

## Tech Stack

| Layer | Choice |
|---|---|
| Language | Python 3.12+ |
| Framework | FastAPI |
| Validation | Pydantic v2 |
| Package manager | **uv** — always `uv add / uv run`; never invoke `pip` directly |
| Linter / formatter | Ruff |
| Database | PostgreSQL |
| ORM | SQLAlchemy 2.x (async) + Alembic |
| Vector DB | Qdrant (optional) |
| Local LLM inference | Ollama |
| Containers | Docker Compose |
| Target platform | macOS Apple Silicon (arm64) |

> All container images must be `linux/arm64` or multi-arch.

## Key Commands

```bash
uv sync                                                  # install/sync deps
uv run uvicorn app.main:app --reload                     # dev server
uv run pytest                                            # full test suite
uv run ruff check . && uv run ruff format .              # lint + format
docker compose up -d                                     # start services
uv run alembic upgrade head                              # apply migrations
uv run alembic revision --autogenerate -m "description"  # new migration
```

## Project Structure

```
.
├── app/
│   ├── main.py          # app factory, lifespan, middleware
│   ├── api/
│   │   ├── deps.py      # shared dependencies (DB session, auth)
│   │   └── v1/          # versioned routers
│   ├── models/          # SQLAlchemy ORM models
│   ├── schemas/         # Pydantic request/response schemas
│   ├── services/
│   │   ├── llm.py       # unified LLM interface (Ollama / OpenAI)
│   │   └── vector.py    # Qdrant helpers
│   ├── core/
│   │   ├── config.py    # pydantic-settings Settings class
│   │   └── database.py  # async engine + session factory
│   └── utils/           # pure helpers, no framework deps
├── tests/
│   ├── conftest.py      # shared fixtures, async test client
│   └── api/             # route-level integration tests
├── alembic/
│   └── versions/        # auto-generated migration scripts
├── docker-compose.yml
└── pyproject.toml
```

## Non-Obvious Patterns

**LLM abstraction** — All LLM calls go through `app/services/llm.py`, which
exposes a single async interface regardless of backend (Ollama locally,
OpenAI/Anthropic in production). Never import `ollama` or `openai` outside
that module.

**Config via pydantic-settings** — Read all environment variables through the
`Settings` class in `app/core/config.py`. Never call `os.getenv()` directly;
use `from app.core.config import settings` everywhere.

**Async-first DB** — Use `AsyncSession` with `async with` throughout. Do not
mix sync SQLAlchemy sessions into async route handlers.

**Qdrant collections** — Declare collection names as constants in
`app/services/vector.py`. Create collections idempotently in the FastAPI
lifespan startup hook.

## Code Style

- **Type hints everywhere** — all signatures; no bare `Any` without a comment.
- **Ruff** is the single source of truth. Line length: **88**. Config in
  `pyproject.toml`.
- **Docstrings** on all public functions and classes (Google style).
- **Prefer `async def`** for route handlers and any service method touching I/O.
- **No star imports.** No mutable default arguments.
- Keep route handlers thin — business logic belongs in `app/services/`.

## Testing Rules

- **Framework:** `pytest` + `pytest-asyncio` (mode = `asyncio`).
- **API tests:** `httpx.AsyncClient` with ASGI transport — no live server in CI.
- **Fixtures:** all shared fixtures in `tests/conftest.py`.
- **Mock external services:** patch Ollama, OpenAI, and Qdrant at the service
  boundary using `unittest.mock.AsyncMock` or `pytest-mock`.
- **Coverage:** ≥ 80 % on `app/`; enforced with `--cov=app --cov-fail-under=80`.
- Mirror source paths: `app/services/llm.py` → `tests/services/test_llm.py`.

## Git Commits

Follow [Conventional Commits](https://www.conventionalcommits.org/):
`feat(api): add /v1/chat streaming endpoint` — scope is the affected layer
(`api`, `models`, `services`, `core`). Subject ≤ 72 chars. No `Co-Authored-By`.

## Agent Skills

```bash
ls .agents/skills/       # repo-scoped skills
ls ~/.agents/skills/     # user-global skills
npx skills list          # discover all skills
npx skills run <skill>   # execute a skill
```

Prefer project-local skills for domain tasks (new router, migration).
Use global skills for cross-cutting concerns (commit linting, PR descriptions).

## Boundaries

**✅ Allowed** — Read any file; run `ruff`, `pytest`, `mypy`; modify `app/`
and `tests/`; add docstrings, type hints, or new files within existing structure.

**⚠️ Ask first** — `uv add / uv remove`; create/edit Alembic migrations;
delete tracked files; push or open a PR; change `docker-compose.yml` ports or
volumes.

**🚫 Never** — Read or modify `.env` or secrets; `git push --force`; hand-edit
`alembic/versions/` (always use `alembic revision --autogenerate`); run
destructive DB operations (`DROP TABLE`, unqualified `DELETE FROM`) outside a
migration; disable Ruff rules without an explanatory comment.

## Modular Overrides

Subdirectories may contain their own `AGENTS.md` to extend these instructions:

```
app/services/AGENTS.md   # LLM/vector service-specific guidance
app/api/v1/AGENTS.md     # v1 routing conventions
tests/AGENTS.md          # test-generation preferences
```

A subdirectory `AGENTS.md` adds to this file; it does not replace it unless
it explicitly states "overrides parent `AGENTS.md`".

## Tool-Specific Symlinks

| Tool | Symlink / setting |
|---|---|
| Cursor | `.cursor/rules/backend.mdc` → `../../AGENTS.md` |
| GitHub Copilot | `.github/copilot-instructions.md` → `../AGENTS.md` |
| Windsurf | `.windsurf/rules/backend.md` → `../../AGENTS.md` |
| Claude Code | reads `AGENTS.md` natively — no symlink needed |
| Codex / OpenAI | reads `AGENTS.md` natively — no symlink needed |

<!-- markdownlint-enable MD013 -->
