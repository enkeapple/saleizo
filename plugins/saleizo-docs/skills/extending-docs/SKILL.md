---
name: extending-docs
description: >-
  Use to add a new documentation type to a project — author a new derivation
  contract test-first (schema-valid + scaffold→audit round-trip) and register
  it in the docs-manifest. Triggers on: "add a doc type", "new documentation
  type", "extend the docs", "custom doc contract", "добавить тип документации",
  "новый контракт документации", "расширить доки".
allowed-tools: Read, Grep, Glob, Write, Edit, Skill
---

# Extending Docs

Add a new doc-type **contract** to a project. A contract is a **data file** — a derivation spec, not a `SKILL.md` — so `writing-skills`' frontmatter validators (frontmatter ≤1024, name regex) do NOT apply here. A contract's tests are two, and both must pass before it ships: a **schema-valid header** and a **scaffold→audit round-trip** that proves the render is idempotent. Schema and marker grammar are single-sourced in [../shared/manifest-schema.md](../shared/manifest-schema.md); the step list is [references/authoring-a-contract.md](references/authoring-a-contract.md).

## Produce this, in order

1. **Name the doc-type and its abstract source, and pick the tier.** `abstractSource` is a category ("the project's release history"), never a concrete path. Tier: **machine** (a purely derived block), **prose** (no block — staleness only), or **hybrid** (a derived block plus human prose the `sourceRev` signal covers).
2. **Write the contract header** per the schema: `id` (= filename), `title`, `abstractSource`, illustrative `bindingHints`, `auditTier`, `blocks[].render`, `staleness`. Machine → `blocks` only; prose → no `blocks`; hybrid → `blocks` + a `staleness` naming both signals.
3. **Make the render canonical and deterministic.** Specify an explicit total order (a stable sort key) and how EACH field is losslessly extracted from the source. A field that needs judgment or lossy summarization (e.g. a free-text "summary" joined from commit messages) is NOT machine-derivable — a machine block containing it re-derives differently every run and audit reports perpetual drift. Move such content to human prose and make the contract **hybrid**.
4. **RED then GREEN the render EMPIRICALLY — never from a structural read.** Build a fixture source, render the block TWICE independently, and confirm the two are **byte-identical**. Differ → the render is not canonical yet (unspecified order or a lossy field, step 3); fix and re-render. A contract "looks correct" is not a pass — you must observe two identical renders.
5. **Round-trip validate (the acceptance test).** Scaffold a doc from the fixture via `scaffolding-docs` → run `auditing-docs`: it reports **CLEAN**. Then mutate the source → re-audit reports **exactly one** `managed-drift` (machine/hybrid) or `stale` (prose). Both halves must hold: clean on unchanged, one finding on change.
6. **Register.** Add the contract file under `contracts/`; when instantiating for the project, add its manifest entry with the tier's fields.

## Red flags — STOP

- Declaring a contract correct from a structural/reasoning read without the empirical two-render idempotence test (step 4).
- A machine block with no explicit total order, or a judgment/lossy field (a "summary" column) — non-idempotent, perpetual drift; move it to hybrid prose (step 3).
- Running `writing-skills`' frontmatter/name validators on a contract — wrong tool: a contract is data, its tests are schema-valid + round-trip.
- Shipping without the scaffold→audit round-trip (step 5), or with a round-trip that is not clean-on-unchanged AND one-finding-on-change.
- An `abstractSource` naming a concrete path instead of a category.

## Edge Cases

- **Export-bound skill.** Its value is for consumer harnesses adding doc-types — including weaker/non-agentic ones. A strong tool-equipped agent may already round-trip by reflex (a green in-repo baseline), but the empirical-round-trip mandate is what a weaker consumer harness needs; the skill is scoped to that floor, not cut on an in-repo no-op.
