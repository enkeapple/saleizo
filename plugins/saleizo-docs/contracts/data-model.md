```yaml
id: data-model
title: Data model
abstractSource: "the project's persisted-data schema definition"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - prisma/schema.prisma
  - db/migrations
  - ORM model classes
  - *.sql DDL
auditTier: hybrid
blocks:
  - id: entities
    render: >
      one Markdown table row per entity/table — `| entity | key fields |` — sorted
      lexicographically by entity name; key fields listed in schema-declared order;
      one header row; empty source → header row only
staleness: "hybrid — the entities derived-slice hash differs from blocks[].rev, AND/OR the schema source content hash differs from sourceRev (the prose is then flagged for human review)"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new data-model doc. The rendered `entities` block is machine-owned; the surrounding prose is the doc owner's and is covered by the `stale` signal.

- **Intro / relationships** — human-owned prose describing how the entities relate, the invariants, and non-obvious modeling choices. Covered by the `sourceRev` staleness signal; flagged `stale` when the schema changes, never auto-rewritten.
- **Entities** — the managed block below, re-derived from the schema source.

### Managed-block marker example

```md
<!-- docs:managed contract="data-model" block="entities" source="prisma/schema.prisma" rev="sha256:…" -->
| entity | key fields |
|--------|------------|
<!-- docs:managed:end block="entities" -->
```

Hybrid tier → the manifest entry carries BOTH `blocks[]` (the entities rev) AND `sourceRev`.
