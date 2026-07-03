```yaml
id: testing
title: Testing
abstractSource: "the project's test configuration and test-run entrypoints"
bindingHints:
  # illustrative — a manifest entry's `source` binds ONE concrete choice per project
  - package.json#scripts (test-prefixed)
  - pytest.ini / pyproject test config
  - jest / vitest config
  - Makefile test targets
auditTier: machine
blocks:
  - id: test-commands
    render: >
      one Markdown table row per test entrypoint — `| command | what it runs |` —
      sorted lexicographically by command; one header row; empty source → header
      row only
staleness: "the derived-slice content hash differs from the manifest blocks[].rev"
```

## Scaffold template

The human-owned shape a scaffolding skill fills in when creating a new testing doc. Everything outside the managed-block markers is prose the doc owner controls; regenerate/refresh never touches it.

- **Intro line** — one sentence naming what this doc lists (how to run the project's tests) and the concrete `source`.
- **Strategy notes** — an optional human-owned section on test layers (unit / integration / e2e), coverage expectations, or flaky-test policy; never generated or overwritten.

### Managed-block marker example

```md
<!-- docs:managed contract="testing" block="test-commands" source="package.json#scripts" rev="sha256:…" -->
| command | what it runs |
|---------|--------------|
<!-- docs:managed:end block="test-commands" -->
```
