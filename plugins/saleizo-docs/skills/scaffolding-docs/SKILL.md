---
name: scaffolding-docs
description: >-
  Use to set up project documentation from scratch in a consumer repo — detect
  candidate sources, propose a docs-manifest at an approval gate, and generate
  each managed doc with its rendered block. Triggers on: "set up the docs",
  "scaffold documentation", "bootstrap project docs", "docs from scratch",
  "настроить документацию", "сгенерировать доки".
allowed-tools: Read, Grep, Glob, Write, Edit, Skill
---

# Scaffolding Docs

Set up a consumer repo's documentation as **manifest-declared views over machine-readable sources**: a `.claude/docs-manifest.json` maps every doc; managed docs carry rendered blocks re-derivable from a concrete `source`; human prose outside the blocks is never touched. This is the from-scratch setup path; drift-checking and regeneration belong to `auditing-docs`.

Schema, marker grammar, and tier→field rules are single-sourced in [../shared/manifest-schema.md](../shared/manifest-schema.md); the flow detail is in [references/scaffold-flow.md](references/scaffold-flow.md).

## Produce this, in order

1. **Check for an existing manifest.** If `.claude/docs-manifest.json` already exists, this is not from-scratch — stop and hand off to `auditing-docs`. Otherwise continue.
2. **Detect a concrete `source` per built-in contract.** For each contract id, read the repo and find the candidate source(s) its `bindingHints` describe (illustratively `package.json#scripts`, a `Makefile`, a `justfile` — your repo may differ). Record what you found, not what you expected.
3. **Gate every ambiguous binding — do not resolve it yourself.** When a doc-type has more than one candidate source (e.g. a `Makefile` AND `package.json#scripts`), STOP and present an interactive-gates **Archetype-A** picker for that doc-type so the owner binds the one `source`. Never silently pick one, and never "document both" — that is the exact RED this skill exists to prevent.
4. **Classify foundation/authoring-owned docs as `external`, never generate them.** A glossary, the root README, CLAUDE.md, ADRs, release notes are owned by another plugin's skill. Record a `kind:"external"` entry with `owner:"<plugin>:<skill>"` (e.g. `saleizo-foundation:bootstrapping-glossary`) and delegate — do not write or rewrite their content here.
5. **Propose the whole manifest at an approval gate.** Present the proposed entries (each doc → `kind`, and for managed: `contract` + bound `source` + tier) as an Archetype-A picker. Get approval before writing anything.
6. **Generate each managed doc.** Fill the contract's prose scaffold template, then emit the rendered block wrapped in the `<!-- docs:managed … -->` … `<!-- docs:managed:end … -->` markers with a `rev="sha256:…"` computed over the derived slice. Write the same `rev` into the manifest entry's `blocks[]`. For prose/hybrid tiers, also record `sourceRev` (hash of the source). Machine → `blocks[]` only; prose → `sourceRev` only; hybrid → both.
7. **Write `.claude/docs-manifest.json`** with every entry. Leave a freeform doc with no contract as `kind:"prose"`.

## Red flags — STOP

- Picking one source (or "documenting both") when >1 candidate exists — that decision is the owner's picker (step 3).
- Writing or rewriting a glossary / README / CLAUDE.md / ADR instead of an `external` entry that delegates to its owner (step 4).
- Generating a doc with no manifest entry, or a managed block with no markers / no `rev` — the doc is then un-auditable.
- Touching prose OUTSIDE a managed-block marker pair — it is human-owned.
- Writing the manifest before the approval gate (step 5).
