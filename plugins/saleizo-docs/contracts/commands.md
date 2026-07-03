```yaml
id: commands
title: Commands
abstractSource: "the project's task/command runner definition"
bindingHints:
  # illustrative — not a requirement; a manifest entry's `source` binds to ONE concrete choice per project
  - package.json#scripts
  - Makefile targets
  - justfile / Taskfile recipes
  - Cargo/other task aliases
auditTier: machine
blocks:
  - id: scripts
    render: >
      one Markdown table row per command — `| script | description |` — sorted
      lexicographically by script name; one header row; empty source → header
      row only
staleness: "the derived-slice content hash differs from the manifest blocks[].rev"
```

## Scaffold template

The scaffold below is the human-owned shape a scaffolding skill fills in when creating a new commands doc. Everything outside the managed-block markers is prose the doc owner controls; a regenerate/refresh operation never touches it.

- **Intro line** — one sentence naming what this doc lists (the project's runnable commands) and where they come from (the concrete `source`, e.g. "derived from `package.json#scripts`").
- **Grouping / notes** — an optional human-owned section below the managed block for grouping commands by purpose (build / test / release / …) or calling out a command that needs extra context. This section is never generated or overwritten; it is the doc owner's space.

### Managed-block marker example

```md
<!-- docs:managed contract="commands" block="scripts" source="package.json#scripts" rev="sha256:…" -->
| script | description |
|--------|-------------|
<!-- docs:managed:end block="scripts" -->
```
