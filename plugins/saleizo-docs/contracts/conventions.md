```yaml
id: conventions
title: Conventions
abstractSource: "the project's lint, format, and commit-convention configuration"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - .editorconfig
  - eslint/prettier config
  - commitlint.config.*
  - ruff / black / gofmt settings
auditTier: prose
staleness: "prose tier — the source content hash differs from the manifest sourceRev (audit emits `stale`; a human reviews the prose, nothing is auto-rendered)"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new conventions doc. A **prose-tier** contract renders NO managed block — the whole doc is human-owned prose, and audit only signals `stale` when the underlying convention config changes. There are no markers in this doc.

- **Intro line** — one sentence naming what this doc covers (the project's coding/commit conventions) and the concrete `source` config it summarizes.
- **Convention sections** — human-owned prose describing naming, formatting, commit style, and review norms. On a `stale` signal (the source config changed) a human re-reads and updates this prose; it is never machine-generated.

Prose tier → the manifest entry carries `sourceRev` only (no `blocks`).
