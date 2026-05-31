# Git Commit Rules

Always follow [Conventional Commits](https://www.conventionalcommits.org/).

## Format

```
type(scope): short description
```

- `type` is one of: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`, `build`
- `scope` is optional but preferred — use the affected layer or component (e.g., `api`, `core`, `config`, `litellm`, `kilocode`)
- Subject line ≤ 72 characters, imperative mood, no period at end
- Body is optional — only include if the change needs explanation beyond the subject
- **Never** add `Co-Authored-By` trailers

## Examples

```
feat(litellm): add SKIP_DB_MIGRATIONS to plist
fix(kilocode): remove duplicate glob permission key
docs(agents): update Ollama model recommendations
chore(config): comment out DATABASE_URL in all profiles
```

## Anti-patterns

- No paragraph-style summaries
- No numbered breakdowns of changes
- No "This commit updates..." or "Changes include..."
- No trailing periods on subject lines
- No merge-commit-style descriptions
