---
tags: [development, ai, agents]
---

# [Project Name] — Agent Instructions

<!-- Canonical source: this file lives at the repo root. Do not duplicate its contents into subdirectory AGENTS.md files. -->

## Purpose

<!-- Describe the product in 2–3 sentences: what it does, who uses it, and what problem it solves. Example: "Acme Platform is a B2B SaaS application for supply-chain analytics. It serves logistics teams who need real-time visibility into shipment status and cost forecasting." -->

---

## Repository Layout

<!-- Add or remove rows to match your actual directory structure. -->

| Directory   | Purpose              | Stack                        | Agent Config          |
|-------------|----------------------|------------------------------|-----------------------|
| `frontend/` | Web application      | Next.js 15, TypeScript       | `frontend/AGENTS.md`  |
| `backend/`  | API server           | Python, FastAPI              | `backend/AGENTS.md`   |
| `infra/`    | Infrastructure       | Terraform, Docker            | `infra/AGENTS.md`     |
| `docs/`     | Documentation        | Markdown                     | —                     |
| `.agents/`  | Shared agent skills  | —                            | —                     |

---

## Key Commands (Root Level)

These commands span the full stack and run from the repo root.

| Command              | What it does                                  |
|----------------------|-----------------------------------------------|
| `docker compose up`  | Start all services locally (full stack)       |
| `make dev`           | Start all services in watch/hot-reload mode   |
| `make test`          | Run all test suites across every subdirectory |
| `make lint`          | Lint all subdirectories in parallel           |
| `make build`         | Build all artifacts for production            |

Stack-specific commands (e.g., `pnpm dev`, `pytest`, `terraform plan`) are documented in the relevant subdirectory `AGENTS.md`.

---

## Shared Conventions

These rules apply everywhere, regardless of stack.

- **Commits:** Follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `chore:`, `docs:`, etc.).
- **Branches:** Use `feature/<slug>`, `fix/<slug>`, or `chore/<slug>`. No work directly on `main`.
- **Pull Requests:** Fill out the PR template at `.github/pull_request_template.md` before requesting review.
- **Secrets:** No credentials, tokens, or private keys in source code or commit history — ever.
- **Environment config:** All environment variables are documented in `.env.example`. Actual `.env` files are never committed.

---

## Cross-Cutting Patterns

- **API communication:** Frontend calls backend via the `/api/` proxy in local dev; in production it calls the direct service URL set in `NEXT_PUBLIC_API_URL`.
- **Shared types:** Canonical type definitions live in `shared/types/`. Both frontend and backend import from there — neither side owns a duplicate copy.
- **Database migrations:** Owned exclusively by `backend/`. Frontend never reads or writes the schema directly. Run migrations before starting dependent services.
- **Feature flags:** Evaluated server-side in `backend/` and forwarded to the frontend as part of the session payload — never hardcoded in UI logic.

<!-- Add cross-cutting patterns specific to your architecture here. -->

---

## Agent Skills

Shared skills available to all agents are stored in `.agents/skills/`. Each subdirectory may also define its own skills directory.

```bash
# List all available skills
npx skills list

# Run a shared skill from the repo root
npx skills run .agents/skills/<skill-name>

# Run a subdirectory-specific skill
npx skills run frontend/.agents/skills/<skill-name>
```

---

## Boundaries

**✅ Allowed — no approval needed**
- Read any file anywhere in the repository.
- Run `lint` or `test` in any subdirectory.
- Edit files within a single subdirectory while working on a task scoped to that directory.

**⚠️ Ask first**
- Install or remove dependencies in any subdirectory.
- Make changes that touch more than one subdirectory simultaneously.
- Run or modify database migrations.
- Modify `docker-compose.yml` or any root-level infrastructure config.

**🚫 Never**
- Write secrets, tokens, or credentials to any file.
- Force-push to `main` or any protected branch.
- Edit files under `generated/` or any directory marked `# AUTO-GENERATED`.
- Commit `.env` or any file excluded by `.gitignore`.

---

## Progressive Disclosure

**Start with this file.** It provides orientation and universal rules.

Load a subdirectory `AGENTS.md` only when you are actively working in that directory. Do not load all `AGENTS.md` files at once — each file is scoped to its context and loading them together creates noise and potential conflicts.

---

## Tool-Specific Symlinks

| Tool      | Config entry point         | Notes                                      |
|-----------|----------------------------|--------------------------------------------|
| Cursor    | `.cursor/rules`            | Symlink or copy this file there            |
| Windsurf  | `.windsurfrules`           | Symlink to repo root                       |
| Copilot   | `.github/copilot-instructions.md` | Symlink or copy this file there     |
| Claude    | `CLAUDE.md`                | Symlink to repo root                       |
| Aider     | `.aider.conf.yml` → `agents_md` | Reference path in config              |

---

## Infrastructure

- **Local development:** `docker-compose.yml` at repo root orchestrates all services. See comments inside that file for port mappings and volume mounts.
- **CI/CD:** Pipelines are defined in `.github/workflows/`. <!-- Replace with your CI provider path if not GitHub Actions. -->
- **Deployment:** <!-- Describe your deployment target (e.g., "Deployed to AWS ECS via GitHub Actions on merge to main"). -->
- **Secrets management:** <!-- Describe where runtime secrets are stored (e.g., AWS Secrets Manager, Vault, 1Password Secrets Automation). -->
