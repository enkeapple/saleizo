# Docs Schema Reference

The single source of truth every `saleizo-docs` skill and contract cites: the `docs-manifest.json` schema, the contract-file header schema, the marker grammar for managed blocks inside a doc, the audit tiers, and the fixed set of audit report row-types. This is a reference doc, not a skill — it has no frontmatter and is not invoked via the `Skill` tool; skills under `plugins/saleizo-docs/skills/**` link to it.

## 1. docs-manifest schema (`.claude/docs-manifest.json`)

The manifest is a JSON object with three top-level fields:

- **`version`** (int) — schema version, currently `1`.
- **`docsRoot`** (string) — a directory path, e.g. `"docs/"`. AUTHORITY: (a) it bounds the orphan sweep — only `*.md` files UNDER `docsRoot` count as orphan candidates; (b) it is the default directory where scaffolding proposes NEW docs. It is NOT a hard boundary: a `managed` or `external` entry MAY name a `doc` path outside `docsRoot` (e.g. the repo root `README.md`).
- **`entries`** (array) — one object per tracked doc.

Each entry carries:

- **`doc`** (required) — repo-relative path to the doc.
- **`kind`** (required) — one of `managed` | `external` | `prose`.
- **managed-only fields**:
  - `contract` — a contract id (matches a `plugins/saleizo-docs/contracts/<id>.md` file).
  - `source` — the concrete, per-project binding of the contract's ABSTRACT `abstractSource` (see §2).
  - `blocks` — array of `{id, rev}`. Present iff the contract renders block(s) (machine or hybrid tier). `rev` is a content hash `sha256:…` of the DERIVED SLICE as of the last sync — git-independent (it hashes the rendered content, not a commit).
  - `sourceRev` — a `sha256:…` hash of the SOURCE itself (not the derived slice). Present for prose-tier and hybrid-tier staleness detection.
- **external-only field**: `owner` — `"<plugin>:<skill>"`, the plugin-qualified skill that owns this doc's content.
- **prose entries** are freeform: no `contract`, `source`, `blocks`, or `sourceRev`.

### Worked example

```jsonc
{
  "version": 1,
  "docsRoot": "docs/",
  "entries": [
    { "doc": "docs/commands.md", "kind": "managed", "contract": "commands",
      "source": "package.json#scripts",
      "blocks": [ { "id": "scripts", "rev": "sha256:ab12…" } ] },
    { "doc": "docs/architecture.md", "kind": "managed", "contract": "architecture",
      "source": "src/",
      "blocks": [ { "id": "module-tree", "rev": "sha256:cd34…" } ],
      "sourceRev": "sha256:ef56…" },
    { "doc": "docs/conventions.md", "kind": "managed", "contract": "conventions",
      "source": ".editorconfig+commitlint.config.js",
      "sourceRev": "sha256:aa11…" },
    { "doc": "docs/glossary.md", "kind": "external", "owner": "saleizo-foundation:bootstrapping-glossary" },
    { "doc": "docs/model-switch.md", "kind": "prose" }
  ]
}
```

This example shows all three managed audit tiers plus the two non-managed kinds:

- `docs/commands.md` — **machine** tier (`commands` contract): `blocks` only, no `sourceRev`.
- `docs/architecture.md` — **hybrid** tier (`architecture` contract): `blocks` AND `sourceRev` together.
- `docs/conventions.md` — **prose** tier (`conventions` contract): `sourceRev` only, no `blocks`.
- `docs/glossary.md` — **external**: owned by another plugin's skill, no contract/source/rev fields at all.
- `docs/model-switch.md` — **prose (freeform)**: not manifest-tracked content, no contract/source/rev fields at all.

### Field applicability by tier

- **machine** → `blocks` only (each block's `rev` = hash of the derived slice).
- **prose** → `sourceRev` only.
- **hybrid** → BOTH `blocks` AND `sourceRev`.

## 2. Contract-file header schema (`plugins/saleizo-docs/contracts/<id>.md`)

A contract is a markdown reference doc: a fenced ` ```yaml ` header followed by a prose scaffold template. Header fields:

- **`id`** — equals the file name (without `.md`) and the manifest entry's `contract` value.
- **`title`** — human-readable contract name.
- **`abstractSource`** — NEVER a concrete file or path. It names the *category* of source the contract renders from, e.g. "the project's task/command runner definition" — never "package.json". The concrete binding lives only in the manifest entry's `source` field (§1), per project.
- **`bindingHints`** — an illustrative list of concrete sources a manifest entry's `source` field could bind to for this contract (e.g. `package.json#scripts`, `Makefile`, `justfile`). Illustrative, not exhaustive, not a requirement.
- **`auditTier`** — one of `machine` | `prose` | `hybrid`.
- **`blocks`** — list of `{id, render}`. `render` is a canonical, deterministic rendering spec (e.g. "sorted by name") so re-deriving the block twice from the same source always produces byte-identical output.
- **`staleness`** — the rule that determines when this contract's tracked doc is stale (e.g. "source hash differs from `sourceRev`").

### Filled example — `commands` contract

```yaml
id: commands
title: Command / script reference
abstractSource: the project's task or command runner definition
bindingHints:
  - package.json#scripts
  - Makefile
  - justfile
auditTier: machine
blocks:
  - id: scripts
    render: sorted by name, one row per command with its description
staleness: exact re-derive of each block differs from the in-file block content
```

Below the header, the contract's prose scaffold template describes the markdown structure to generate around the managed block(s) (headings, intro prose, table shape) — the part a scaffolding skill fills in when creating a new tracked doc.

## 3. Marker grammar (managed blocks inside a doc)

A managed block is delimited by a paired open/close HTML-comment marker:

```md
<!-- docs:managed contract="commands" block="scripts" source="package.json#scripts" rev="sha256:…" -->
| script | description |
|--------|-------------|
<!-- docs:managed:end block="scripts" -->
```

Rules:

- All marker attributes are double-quoted.
- A single doc may contain multiple managed blocks; each has a unique `block` id within that doc.
- Prose OUTSIDE any marker pair is human-owned and is never modified by a scaffold/refresh/regenerate operation.
- Well-formedness — no nested markers, no duplicate `block` id within a doc, every open marker has exactly one matching close marker — is the FIRST audit check run on a doc (before any tier-specific check); a failure here reports `marker-malformed` (§5) and blocks further tier checks on that doc.

## 4. Audit tiers

- **machine** — exact re-derive of each block from `source`; diff the re-derived content against the in-file block content. Uses `blocks[].rev` (the derived-slice hash) to short-circuit when unchanged.
- **prose** — no re-derive attempted. The doc is `stale` when the current source content hash differs from the recorded `sourceRev`.
- **hybrid** — BOTH apply: each managed block is re-derived and diffed (as in machine), AND the surrounding prose gets the staleness signal from `sourceRev` (as in prose).

## 5. Audit report row-types

Exactly seven row-types. Every row carries a recommended disposition (feeding the batched drift-report picker used elsewhere in this vault):

| Row-type | Fires when | Recommended dispositions |
| --- | --- | --- |
| `managed-drift` | machine/hybrid: source re-derive differs from the in-file block | `regenerate` \| `keep-as-prose` |
| `stale` | prose/hybrid: current source content hash differs from `sourceRev` | `refresh` |
| `external` | an `external` entry's owner skill returned a verdict | `delegate` (surface the owner skill's verdict verbatim) |
| `orphan` | a `*.md` file under `docsRoot` matches no manifest entry | `adopt` \| `ignore` |
| `missing` | a manifest entry's `doc` file does not exist on disk | `scaffold` \| `remove-entry` |
| `external-unavailable` | an `external` entry's `owner` skill/plugin is not installed | `treat-as-prose` \| `install-owner` — FAIL LOUD, never a silent skip |
| `marker-malformed` | unmatched, nested, or duplicate-`block`-id markers in a doc | `repair` |
