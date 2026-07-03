```yaml
id: environment
title: Environment / configuration variables
abstractSource: "the project's environment or configuration template"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - .env.example
  - config/*.yaml
  - app.config.* settings block
  - Helm values / deployment env
auditTier: machine
blocks:
  - id: env-vars
    render: >
      one Markdown table row per configuration variable — `| variable | purpose |`
      — sorted lexicographically by variable name; one header row; empty source →
      header row only
staleness: "the derived-slice content hash differs from the manifest blocks[].rev"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new environment doc. Everything outside the managed-block markers is prose the doc owner controls; regenerate/refresh never touches it.

- **Intro line** — one sentence naming what this doc lists (the project's configuration/environment variables) and the concrete `source` they are derived from.
- **Secrets note** — an optional human-owned section warning which variables are secrets and where real values live (a vault, CI secrets); never generated, never overwritten.

### Managed-block marker example

```md
<!-- docs:managed contract="environment" block="env-vars" source=".env.example" rev="sha256:…" -->
| variable | purpose |
|----------|---------|
<!-- docs:managed:end block="env-vars" -->
```
