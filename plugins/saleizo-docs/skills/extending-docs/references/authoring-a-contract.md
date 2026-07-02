# Authoring a Contract — step list

The detailed procedure behind `extending-docs`. The canonical schema is [../../shared/manifest-schema.md](../../shared/manifest-schema.md); this file is the test-first authoring recipe.

## A contract is data, not a skill

A contract file (`contracts/<id>.md`) is a YAML derivation-spec header plus a prose scaffold template. It has no frontmatter `name`, no routing entry, no `Skill`-tool invocation. Therefore:

- `writing-skills`' validators (frontmatter ≤1024 bytes, `name` regex, `name === dir`) do **not** apply.
- A contract's acceptance tests are exactly two: (1) a schema-valid header, and (2) a scaffold→audit round-trip.

## Tier decision

| Tier | Use when | Manifest fields the entry carries |
| --- | --- | --- |
| `machine` | the doc's content IS a losslessly derived block (a table/tree with a total order) | `blocks[]` only |
| `prose` | no derivable block — the doc is human prose whose freshness tracks a config source | `sourceRev` only |
| `hybrid` | a derived block AND human narrative prose around it | `blocks[]` AND `sourceRev` |

The trap: forcing a judgment-dependent field (a free-text summary, a rationale) into a `machine` block. It is not losslessly re-derivable, so audit reports drift on every run. Split it: the losslessly-derivable facts go in the block; the narrative goes in hybrid prose under `sourceRev`.

## Canonical render

The `blocks[].render` string must pin, unambiguously:

- an explicit **total order** — a stable sort key (e.g. "sorted lexicographically by name", "reverse-chronological by date, ties by descending semver");
- how **each column/field** is extracted, with no judgment step;
- the **empty-source** behavior (usually "header row only").

Two agents following the render on the same source must produce byte-identical output. If they can't, the spec is under-determined.

## The empirical RED→GREEN (do NOT skip)

1. Build a small fixture source (a realistic sample of the abstract source).
2. Render the block from it TWICE, independently, following only the render spec.
3. Diff the two. Byte-identical → GREEN. Differ → RED: the order or a field is under-specified; tighten step 3's render and repeat.

Reasoning that the render "should be" deterministic is not this test. Observe two identical renders.

## The round-trip (acceptance test)

1. Scaffold a doc from the fixture via `scaffolding-docs` (manifest entry + generated block + `rev`).
2. Run `auditing-docs` → it must report **CLEAN** (no drift on unchanged input).
3. Mutate the fixture source (add/remove/change one element).
4. Re-run `auditing-docs` → it must report **exactly one** finding: `managed-drift` for a machine/hybrid block, or `stale` for a prose contract.

A contract that fails either half — phantom drift on unchanged input, or no finding after a real change — is not done.

## Register

Add `contracts/<id>.md`. When instantiating the doc-type in a project, add its manifest entry with the tier's fields (see the tier table). The contract file itself carries no manifest entry — that is per-project.
