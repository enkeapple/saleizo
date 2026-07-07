# Scaffold Flow — detect → gate → generate

The step-by-step flow behind `scaffolding-docs`. The canonical schema is [../../shared/manifest-schema.md](../../shared/manifest-schema.md); the slices below are duplicated here for use at point of scaffolding.

## 1. Detect candidate sources

For each built-in contract, read the repo and locate the concrete source its abstract source could bind to. A contract's `bindingHints` list is illustrative, not exhaustive — the repo decides. Record, per doc-type:

- zero candidates → the doc-type does not apply to this repo; skip it (no entry).
- exactly one candidate → a clean binding; carry it to the proposal.
- two or more candidates → an **ambiguous binding**; it MUST go through the gate below.

## 2. Gate ambiguous bindings (interactive-gates — candidate-source selection)

When a doc-type has more than one candidate source, present a picker so the owner binds exactly one `source`:

```text
Source for `commands` — this repo has more than one candidate:
  1. package.json#scripts   → bind the npm scripts block
  2. Makefile targets       → bind the Makefile
(reply with a number; "Other" lets you name a different source)
```

Never resolve it yourself — not by guessing "the canonical one", not by documenting both. Silent resolution is the failure this gate prevents.

## 3. Classify external / prose docs

Before generating, classify each doc that is NOT backed by a built-in contract:

- **`external`** — content owned by another plugin's skill: a domain glossary, the root README, CLAUDE.md, ADRs, release notes. Record `{ "doc": "...", "kind": "external", "owner": "<plugin>:<skill>" }` and delegate to that owner; never generate or rewrite it here. Illustrative owners: `saleizo-foundation:bootstrapping-glossary` (glossary), `saleizo-foundation:bootstrapping-readme` (README), `saleizo-authoring:writing-adrs` (ADRs).
- **`prose`** — a freeform human doc with no contract and no external owner: `{ "doc": "...", "kind": "prose" }`. Existence and linkage only; no source, no rev.

## 4. Propose the manifest at the approval gate

Present the full proposed manifest as an Archetype-A picker: `Approve` → write it · `Request changes` → adjust bindings/classifications · `Redo detection` → re-scan. Do not write `.claude/docs-manifest.json` until approved.

## 5. Generate managed docs

For each `kind:"managed"` entry, in this order:

1. Fill the contract's prose scaffold template (headings, intro, human-owned sections) — this is the doc owner's space and is written once.
2. Render the managed block from the bound `source` using the contract's canonical (deterministic, sorted) render spec.
3. Wrap the rendered block in markers and stamp the derived-slice hash:

```md
<!-- docs:managed contract="commands" block="scripts" source="package.json#scripts" rev="sha256:…" -->
| script | description |
|--------|-------------|
| build  | compile     |
<!-- docs:managed:end block="scripts" -->
```

4. Write the SAME `rev` into the manifest entry's `blocks[]` `{ id, rev }`.

## 6. Record the tier fields

Field applicability by the contract's `auditTier` (machine → `blocks[]`, prose → `sourceRev`, hybrid → both) is single-sourced in [../../shared/manifest-schema.md](../../shared/manifest-schema.md) §1 "Field applicability by tier"; SKILL step 6 applies it at generation time.

`rev`/`sourceRev` are content hashes (`sha256:…`), git-independent — staleness works in a shallow clone or with uncommitted sources.
