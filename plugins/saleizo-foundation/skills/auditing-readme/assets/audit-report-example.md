# README Catalog Audit Report — Filled Example

A concrete reference for the report's REQUIRED fixed shape. Every status is backed by a re-derive-from-disk run this session — not from memory. The example below is a single skills block; in a marketplace, emit one `###` sub-block per managed block (each per-plugin `skills:` / `hooks:` block plus the root `plugins:` index).

```text
# README Catalog Audit — single-repo

## Findings

### root skills
| Criterion | Disk shows (this session) | Status |
| --- | --- | --- |
| 1 markers well-formed | One `skills:start` + one `skills:end`, in order | Confirmed |
| 2 every entry appears exactly once | `old-planning-helper` listed but absent on disk; `writing-hooks` on disk but missing from block | Drift |
| 3 grouping + ordering match disk | Block has 2 categories; disk has 7 (`design`, `entrypoints`, `foundation`, `process`, `prose` missing) | Drift |
| 4 descriptions match the derived one | `grilling` row reads "brainstorming feature ideas"; derived is "Use before any creative or build work…" | Drift |
| 5 row link resolves + bold-link bullet shape | `skills/apply-chain/old-planning-helper/SKILL.md` does not exist; rows are plain links (no bold) instead of `- **[name](link)** — …` | Drift |

## Summary
- Blocks audited: 1 · Confirmed: 0 · Drift: 1 · Malformed: 0

## Recommended disposition
- root skills — Drift → regenerate the block via bootstrapping-readme (fully derived; re-deriving resolves every criterion at once)
```

Criterion 1 passed, so criteria 2–5 were evaluated; had markers been malformed, row 1 blocks the rest for that block. A block with any Drift/Malformed row counts once as Drift/Malformed in the Summary; regeneration resolves it — no row is hand-patched, prose outside the markers untouched.
