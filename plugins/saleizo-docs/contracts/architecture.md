```yaml
id: architecture
title: Architecture
abstractSource: "the project's top-level source layout"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - src/
  - app/ + lib/
  - packages/ (monorepo roots)
  - cmd/ + internal/ (Go layout)
auditTier: hybrid
blocks:
  - id: module-tree
    render: >
      the top-level module/directory tree under the source root — one line per
      immediate child directory with a one-phrase role, sorted lexicographically;
      nested contents summarized, not expanded; empty source → an empty tree note
staleness: "hybrid — the module-tree derived-slice hash differs from blocks[].rev, AND/OR the source-tree content hash differs from sourceRev (the prose is then flagged for human review)"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new architecture doc. The rendered `module-tree` block is machine-owned; everything outside the markers — including the prose the `stale` signal flags — is the doc owner's.

- **Intro / overview** — human-owned prose describing the system's shape, the main flows, and the key decisions. This is the hybrid prose the `sourceRev` staleness signal covers: when the source tree changes, audit flags it `stale` so a human re-reads it — it is never auto-rewritten.
- **Module tree** — the managed block below, re-derived from the source layout.

### Managed-block marker example

```md
<!-- docs:managed contract="architecture" block="module-tree" source="src/" rev="sha256:…" -->
- `api/` — HTTP surface
- `core/` — domain logic
<!-- docs:managed:end block="module-tree" -->
```

Hybrid tier → the manifest entry carries BOTH `blocks[]` (the module-tree rev) AND `sourceRev` (the source-tree hash driving the prose `stale` signal).
