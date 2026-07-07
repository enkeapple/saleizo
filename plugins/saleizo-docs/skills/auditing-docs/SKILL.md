---
name: auditing-docs
description: >-
  Use to audit project documentation for drift against its sources and apply
  fixes — re-derive machine blocks, flag stale prose, delegate external docs,
  and report a recommended disposition per finding. Triggers on: "audit the
  docs", "are the docs stale", "docs drift", "check documentation",
  "проверь документацию", "аудит доков", "дрейф документации".
allowed-tools: Read, Grep, Glob, Write, Edit, Skill
---

# Auditing Docs

Audit a consumer repo's `.claude/docs-manifest.json`-declared docs for drift, then apply approved fixes. The output is a **fixed-shape report**: every finding is one of seven row-types, each carrying a recommended disposition, resolved through one batched picker. Schema, tiers, and the row-type table are single-sourced in [../shared/manifest-schema.md](../shared/manifest-schema.md); the per-entry algorithm is in [references/audit-flow.md](references/audit-flow.md); the report shape is [assets/audit-report-example.md](assets/audit-report-example.md).

## Produce this, in order

1. **Load the manifest.** If `.claude/docs-manifest.json` is absent, emit a `missing-manifest` notice — a terminal pre-audit signal, **not** one of the seven report rows — offer to run `scaffolding-docs`, and stop; do not audit ad hoc.
2. **Check marker well-formedness first, on every managed doc.** Unmatched, nested, or duplicate-`block`-id markers → a `marker-malformed` finding; this blocks all tier checks on that doc until repaired (never regenerate a malformed block).
3. **Classify each manifest entry into exactly one row-type:**
   - **managed**, machine/hybrid tier → re-derive each block from `source` with the contract's canonical render; diff against the in-file block → `managed-drift` if it differs. Prose/hybrid → hash the source, compare to `sourceRev` → `stale` if it differs.
   - **external** → actually invoke the `owner` skill via the `Skill` tool and surface **its returned verdict verbatim** as the `external` finding's detail (**delegate**). A narrated intention ("delegating to owner skill") is not a delegation — the finding detail must be the owner's real verdict, never a placeholder, and never "out of scope / no action". If the owner plugin/skill is **not installed**, emit `external-unavailable` and **FAIL LOUD** — never a silent skip.
   - a manifest entry whose `doc` file is absent on disk → `missing`.
4. **Orphan sweep, bounded to `docsRoot`.** Any `*.md` under `docsRoot` named by no entry → `orphan`. Never sweep outside `docsRoot` (avoids false positives on build output).
5. **Emit the fixed-shape report.** Use only the seven row-types defined in [../shared/manifest-schema.md](../shared/manifest-schema.md) §5 (`managed-drift`, `stale`, `external`, `orphan`, `missing`, `external-unavailable`, `marker-malformed`); give every finding a recommended disposition from that row-type's fixed set — not ad-hoc severity or freeform advice. Match [assets/audit-report-example.md](assets/audit-report-example.md).
6. **Resolve through ONE batched picker** (interactive-gates **C-drift**): `Apply recommended` · `Adjust per-finding` · `Stop`. Never one picker per finding — that is why each finding already carries a recommended disposition.
7. **Apply approved fixes, then re-verify.** Regenerate each approved block, restamp its `rev` in both the marker and the manifest entry, refresh `sourceRev` where applicable, and re-run the affected checks to confirm they now report clean. Never touch prose outside a managed-block marker pair.

## Red flags — STOP

- Marking an `external` entry "out of scope / no action needed" instead of delegating to its owner (step 3).
- Writing a placeholder like "delegating to owner skill" as the `external` finding's detail instead of actually invoking the owner and surfacing its real verdict (step 3).
- Silently skipping an `external` doc whose owner is not installed — it MUST be `external-unavailable`, FAIL LOUD (step 3).
- An ad-hoc report (severity High/Med/Low, freeform actions) instead of the seven fixed row-types with recommended dispositions (step 5).
- One picker per finding instead of a single batched C-drift picker (step 6).
- Regenerating a block before repairing malformed markers (step 2), or restamping a `rev` without re-verifying (step 7).
- Editing prose outside the markers, or clobbering a human edit inside a block without offering `keep-as-prose`.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "External docs are out of scope for an audit." | The owner skill audits them — invoke it and surface its verdict; never mark an `external` entry "no action" (step 3). |
| "The owner isn't installed, so skip this entry." | That is `external-unavailable`, FAIL LOUD — never a silent skip (step 3). |
| "I can see the block drifted without re-deriving it." | A drift verdict is confirmed by an actual re-derive+diff; a placeholder or hand-edited `rev` must not mask real drift (step 3). |
| "One picker per finding reads clearer." | Findings already carry a recommended disposition — resolve through one batched C-drift picker (step 6). |

## Edge Cases

- **Export-bound skill.** Its value is for consumer harnesses auditing docs — including weaker/non-agentic ones. A strong agent may already delegate external docs and re-derive rather than trust `rev` by reflex (a green in-repo baseline), but the delegate-never-skip and re-derive mandates are what a weaker consumer harness needs; the skill is scoped to that floor, not cut on an in-repo no-op.
