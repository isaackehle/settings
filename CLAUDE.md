# CLAUDE.md

Guidance for Claude Code (and other agents working in this repo) on how this repository is organized and the conventions it follows. Read this before making changes.

## Purpose of this repo

Git-tracked source of truth for personal infrastructure configuration: homelab config, AI agent stack setup, and containerized services (IaC) running on the Synology NAS. Config files here are canonical — the running systems should reflect what's committed, not the other way around.

## Core principles

- **Config files are the single source of truth.** No duplicated definitions across files, no drift between what's committed and what's actually deployed. If two files define the same thing, consolidate into one canonical file and reference it rather than keeping both in sync by hand.
- **Secrets are never committed.** Compose files and configs reference secrets via `${VAR}` placeholders only — never a literal value in a tracked file. Actual values live either in Portainer's stack-level environment variables (for Repository/GitOps-deployed stacks) or in a gitignored `.env` file alongside a committed `.env.example` documenting required variables with no real values filled in.
- **Verify before continuing.** After any failed or interrupted operation, re-check actual state (disk, git, container status) before describing progress or moving to the next step. Don't report success based on what should have happened — confirm what actually did.
- **Deterministic tooling where possible.** Prefer plain scripts/CLI tools over LLM-in-the-loop for infrastructure tasks (probing, diffing, applying config). Reserve AI/agentic tooling for tasks where semantic reasoning genuinely adds value over a deterministic approach.

## Directory structure

- `ai/setup-web/` — existing GUI for AI agent stack setup. Extend rather than replace.
- `iac/<stack-name>/docker-compose.yml` — one directory per Docker Compose stack running on the NAS, one compose file per directory. Each stack should be independently deployable via Portainer's Repository-based Stacks feature (GitOps).
- *(other tracked content — fleet management config, agent stack setup, etc. — exists in this repo; expand this section as it's reviewed rather than assuming this list is complete)*

## Docker / IaC conventions (`iac/`)

- Portainer stacks deploy from this repo via **Repository** mode, not the Web editor paste-in — the repo is the source of truth, Portainer just deploys whatever's currently committed.
- GitOps updates use **polling**, not webhooks — the NAS stays behind Tailscale with no inbound exposure; polling means Portainer reaches out on an interval rather than requiring GitHub to reach in.
- Pin image tags deliberately for pre-1.0 / fast-moving software (e.g. AFFiNE) rather than tracking `latest`/`stable`. Auto-redeploy on a floating tag can pull a breaking change into a running service with no chosen moment to review release notes first — bump the pin on purpose.
- Match container `PUID`/`PGID` to the actual host user (`id <username>`) to avoid file ownership mismatches between host and container — a known source of confusing "won't sync/write" symptoms, especially for Syncthing.
- **DSM's firewall doesn't know about Docker's dynamic bridge networks.** Each new Portainer stack can create its own isolated network with a randomly-named bridge (`docker-<hash>`) and subnet — DSM's firewall has no automatic awareness of these, and can silently drop all outbound container traffic (DNS included) even when iptables rules themselves look correct. Symptom looks like a DNS problem (containers can't resolve hostnames) but is actually a total outbound block — confirm via `docker run --rm alpine ping -c 3 1.1.1.1` (raw IP, no DNS involved) rather than assuming it's DNS-specific. Fix: Control Panel → Security → Firewall → Edit Rules → add an Allow rule for source `172.16.0.0/12` (covers Docker's entire private range, not just currently-existing bridges) positioned above the default deny rule. Don't leave the firewall disabled as the "fix" — this NAS holds Portainer secrets and is reachable over Tailscale.

## Plan documents

Detailed plan documents (used when handing implementation work to Hermes, or tracking multi-phase infrastructure changes) use this header convention:

```
Created: YYYY-MM-DD
Completed:
Status: In Progress | Blocked | Done
```

Checkboxes (`- [ ]` / `- [x]`) track individual steps. A step that was deliberately skipped is marked `[x]` with `~~strikethrough~~` text and a `**skipped by choice**` note — never left unchecked. Unchecked must always mean "not yet done," never "decided not to do," so the checklist stays trustworthy at a glance.

## Scratch / staging content

Never stage temporary files in `~/Desktop` or `~/Documents` — both sync to iCloud, which silently pulls transient/local-only content into yet another cloud service. Default to `~/code/help` or `/tmp` for anything transient: downloaded scripts, backup copies made mid-migration, log files, etc.

## Sync architecture (context — not itself tracked in this repo)

- Syncthing is the primary sync layer across Mac ↔ Synology NAS ↔ DS9 — open protocol, deterministic and inspectable conflict resolution, no vendor lock-in. NAS acts as an always-on Introducer node so devices stay in sync even when never online simultaneously.
- Synology Drive / Synology Photos serve household members who should *not* be on Syncthing directly — separate DSM user accounts, scoped Shared Folder permissions, official iOS/Android apps.
- OneDrive is being decommissioned as the primary sync target on the main laptop. Don't assume it's still an active sync destination when encountering older references to it in configs or scripts.
