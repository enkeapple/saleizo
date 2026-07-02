```yaml
id: api-surface
title: API surface
abstractSource: "the project's externally-exposed API definition"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - openapi.yaml / swagger.json
  - route definitions (router files)
  - gRPC/proto service definitions
  - GraphQL schema
auditTier: hybrid
blocks:
  - id: endpoints
    render: >
      one Markdown table row per endpoint — `| method + path | purpose |` — sorted
      by path then method (both lexicographic); one header row; empty source →
      header row only
staleness: "hybrid — the endpoints derived-slice hash differs from blocks[].rev, AND/OR the API-definition source content hash differs from sourceRev (the prose is then flagged for human review)"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new api-surface doc. The rendered `endpoints` block is machine-owned; the surrounding prose is the doc owner's and is covered by the `stale` signal.

- **Intro / auth & versioning** — human-owned prose on authentication, versioning, rate limits, and error conventions. Covered by the `sourceRev` staleness signal; flagged `stale` when the API definition changes, never auto-rewritten.
- **Endpoints** — the managed block below, re-derived from the API-definition source.

### Managed-block marker example

```md
<!-- docs:managed contract="api-surface" block="endpoints" source="openapi.yaml" rev="sha256:…" -->
| method + path | purpose |
|---------------|---------|
<!-- docs:managed:end block="endpoints" -->
```

Hybrid tier → the manifest entry carries BOTH `blocks[]` (the endpoints rev) AND `sourceRev`.
