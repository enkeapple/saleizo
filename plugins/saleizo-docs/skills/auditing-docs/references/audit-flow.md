# Audit Flow — per-entry algorithm

The decision procedure behind `auditing-docs`. The canonical schema and the row-type table are in [../../shared/manifest-schema.md](../../shared/manifest-schema.md); this file is the operational order.

## Fixed check order

Run the checks in this order so a malformed doc never gets regenerated and every disk file is accounted for:

1. **Manifest presence** — no `.claude/docs-manifest.json` → single `missing-manifest` finding, offer `scaffolding-docs`, stop.
2. **Marker well-formedness** (every managed doc, before any tier check) — see below.
3. **Per-entry tier / kind classification** — see below.
4. **Orphan sweep** — bounded to `docsRoot`.

## Marker well-formedness (step 2)

A doc is malformed if any of: an open `<!-- docs:managed … -->` with no matching `<!-- docs:managed:end block="…" -->`; nested markers; two blocks sharing one `block` id. Any of these → `marker-malformed` (disposition `repair`), and the doc's tier checks are skipped until repaired. Never regenerate a block inside a malformed doc — you cannot locate "the" block unambiguously.

## Per-entry classification (step 3)

For each manifest entry, produce exactly one finding (or none, if clean):

| Entry | Check | Row-type when it fails |
| --- | --- | --- |
| `managed`, machine | re-derive each block from `source` via the contract's canonical render; diff vs in-file block | `managed-drift` (`regenerate` \| `keep-as-prose`) |
| `managed`, prose | hash `source`; compare to `sourceRev` | `stale` (`refresh`) |
| `managed`, hybrid | BOTH: re-derive+diff each block AND hash-compare `sourceRev` | `managed-drift` and/or `stale` |
| `external`, owner installed | invoke the owner skill via `Skill`; surface its verdict verbatim | `external` (`delegate`) |
| `external`, owner NOT installed | detect the owner plugin/skill is absent | `external-unavailable` (`treat-as-prose` \| `install-owner`) — FAIL LOUD |
| any | the entry's `doc` file is absent on disk | `missing` (`scaffold` \| `remove-entry`) |

**Re-derive, don't trust `rev`.** `rev` short-circuits an unchanged block, but a drift verdict is confirmed by an actual re-derive+diff, not by hash comparison alone (a placeholder or hand-edited `rev` must not mask real drift).

**`external` is delegate, never skip.** An `external` entry is not "out of scope". Its whole point is that the owner skill audits it — invoke that skill and pass its verdict through. Only an *uninstallable* owner is a non-delegable case, and that is the loud `external-unavailable`, still never a silent skip.

## Orphan sweep (step 4)

List `*.md` under `docsRoot`. Any file named by no manifest entry → `orphan` (`adopt` \| `ignore`). Files OUTSIDE `docsRoot` are never orphan-swept; a doc outside `docsRoot` is audited only when it has an explicit manifest entry (e.g. a `managed`/`external` root `README.md`).

## Apply + re-verify (SKILL step 7)

After the batched picker approves dispositions:

- `regenerate` → re-render the block, replace the in-file block content, recompute the derived-slice hash, write it to BOTH the marker `rev` and the manifest entry's `blocks[].rev`.
- `refresh` → recompute `sourceRev` from the current source and write it to the manifest entry (the human reviews the surrounding prose).
- `repair` → fix the markers so the doc is well-formed, then re-run its tier checks.
- After applying, re-run the affected checks and confirm they now report clean. Prose outside markers is never modified.
