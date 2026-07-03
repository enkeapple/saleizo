```yaml
id: dependencies
title: Dependencies
abstractSource: "the project's dependency manifest"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - package.json#dependencies
  - requirements.txt
  - Cargo.toml#dependencies
  - go.mod require block
auditTier: machine
blocks:
  - id: dependencies
    render: >
      one Markdown table row per DIRECT dependency — `| package | version |` —
      sorted lexicographically by package name; one header row; transitive/lock
      entries excluded; empty source → header row only
staleness: "the derived-slice content hash differs from the manifest blocks[].rev"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new dependencies doc. Everything outside the managed-block markers is prose the doc owner controls; regenerate/refresh never touches it.

- **Intro line** — one sentence naming what this doc lists (the project's direct dependencies) and the concrete `source`.
- **Rationale notes** — an optional human-owned section explaining why a non-obvious dependency is present or pinned; never generated or overwritten.

### Managed-block marker example

```md
<!-- docs:managed contract="dependencies" block="dependencies" source="package.json#dependencies" rev="sha256:…" -->
| package | version |
|---------|---------|
<!-- docs:managed:end block="dependencies" -->
```
