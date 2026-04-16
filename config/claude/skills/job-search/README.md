# Job Search

Grouped job-search skill for structured opportunity evaluation, resume tailoring, interview preparation, live interview note-taking, and post-interview debrief.

## What this skill covers

- Opportunity evaluation
- Resume tailoring
- Recruiter and interview prep
- Live interview note-taking
- Post-interview debrief
- Optional private personalization via a local candidate profile

## Inputs

Use any that are available:

- Job description
- Company or recruiter notes
- Reference resume document(s)
- Experience inventory
- Candidate profile
- Interview notes
- Private local profile

If some context is missing, continue with the best available information and explicitly list what is missing.

## Workspace conventions

This skill expects a local job-search workspace root, referred to here as `JOB_SEARCH_WORKSPACE`.

Recommended mapping:

```text
JOB_SEARCH_WORKSPACE = <OBSIDIAN_VAULT>/job_search
```

Recommended structure:

```text
JOB_SEARCH_WORKSPACE/
├── source/
│   ├── experience-inventory.md
│   ├── reference-resume-ai-workflows.md
│   └── reference-resume-embedded.md
├── companies/
│   └── Chronograph/
│       ├── Chronograph.md
│       ├── Chronograph-product-screenshot.png
│       ├── interviews/
│       ├── job-descriptions/
│       ├── people/
│       └── resumes/
├── contracting/
├── niche-markets/
└── _system/
```

- `source/` holds your global experience inventory and reference resumes.
- `companies/` holds per-company workspaces.
- `contracting/` holds contract and fractional opportunities.
- `niche-markets/` holds sector research and search strategies.
- `_system/` holds tracking files like job matrices and comparison views.

## Private personalization

This public skill supports optional private personalization via a separate root, `PRIVATE_CONFIG_ROOT`.

Expected path:

```text
PRIVATE_CONFIG_ROOT/job-search/candidate-profile.private.md
```

If a private candidate profile is available, apply it before making recommendations.
If it is not available, continue using public templates and explicitly note missing personal context.

Never expose private values unless the user asks.
Never copy private profile content into public repository files.

See `docs/personalization.md` for more detail.
