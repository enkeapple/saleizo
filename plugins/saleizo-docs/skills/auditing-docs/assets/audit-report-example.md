# Audit Report — fixed shape (example)

The shape `auditing-docs` emits. Every finding is one of the seven row-types and carries a recommended disposition from that row-type's fixed set. This is illustrative content over an illustrative repo — your findings and paths differ.

## Docs Audit — `acme-web`

Manifest: `.claude/docs-manifest.json` (v1, docsRoot `docs/`). 6 findings.

| # | Row-type | Doc / target | Detail | Recommended |
| --- | --- | --- | --- | --- |
| 1 | `managed-drift` | `docs/commands.md` (block `scripts`) | re-derive from `package.json#scripts` adds a `start` row absent in-file | `regenerate` |
| 2 | `stale` | `docs/conventions.md` | source hash differs from `sourceRev` since last sync | `refresh` |
| 3 | `external` | `docs/glossary.md` | owner `saleizo-foundation:bootstrapping-glossary` reports: 1 term undefined | `delegate` |
| 4 | `external-unavailable` | `docs/legacy.md` | owner `acme-internal:legacy-api-docs` is NOT installed — FAIL LOUD | `treat-as-prose` \| `install-owner` |
| 5 | `orphan` | `docs/extra.md` | under `docsRoot`, named by no manifest entry | `adopt` \| `ignore` |
| 6 | `marker-malformed` | `docs/dupe.md` | two blocks share `block="scripts"` | `repair` |

A clean audit prints `No findings — all entries verify.` and skips the picker.

## Resolution — one batched picker (interactive-gates C-drift)

Never one picker per finding. The findings above each already carry a recommended disposition, so a single batched picker resolves them all:

```text
Audit found 6 issues, each with a recommended disposition (table above).
  1. Apply recommended   → regenerate #1, refresh #2, delegate #3, treat-as-prose #4, adopt #5, repair #6
  2. Adjust per-finding  → walk the findings one by one and pick a disposition for each
  3. Stop                → take no action now
(reply with a number)
```

On `Apply recommended`: regenerate/refresh restamps `rev`/`sourceRev` in both the marker and the manifest, repair fixes the markers, delegate hands off to the owner skill; then the affected checks are re-run and must report clean. `external-unavailable` (#4) is never silently resolved — it stays loud until the owner is installed or the doc is explicitly downgraded to prose.
