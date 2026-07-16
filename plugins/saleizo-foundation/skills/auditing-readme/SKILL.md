---
name: auditing-readme
description: >-
  Use to check whether the README skills catalog still matches the skills on
  disk (names, descriptions, categories, links) and to correct it when it
  drifts. Triggers on: "audit the README", "is the skills catalog accurate",
  "README drift", "check the skills index", "update the README catalog".
allowed-tools: Read, Grep, Glob, Edit
---

# Auditing README

Verify each README's managed block against disk, report the drift per criterion, then correct it. **A stale catalog is worse than none**: it tells a browsing human the repo has skills it dropped, or hides ones it gained.

**Re-derive, don't skim.** Every row in a managed block is a derived claim, not prose. Re-derive each block from disk via the [catalog-derivation contract](./references/catalog-derivation.md) — the SAME contract `bootstrapping-readme` writes from — then compare. "Looks complete" is not an audit; a row that disagrees with disk is drift, not a detail.

**Audit every managed block the layout calls for** — the contract's *Repo mode* and *Per-plugin README composition* define which. Single-repo: the one root skills block. Marketplace: in EACH `plugins/<name>/README.md` its skills block (iff the plugin has skills) and/or hooks block (iff it wires hooks), PLUS the root README's plugin-index block. Beyond a wrong row, each of these is *itself* drift: a missing per-plugin README; a root README carrying a flat all-skills catalog instead of the plugin index; a hooks-only plugin whose README shows an empty `<!-- no skills found -->` block instead of its hooks catalog; a block rendered as a table or carrying a kind column instead of the bullet shape; a slug H1 where the Title-Case form is derived.

Audit only the managed blocks — scaffold prose (intro, Quickstart, Installation, Philosophy, …) is human-owned and out of scope. Pairs with `bootstrapping-readme`, which generates the blocks this skill keeps true.

## When to use

- Periodic check of `README.md` after adding/renaming/deleting skills or editing a `description`.
- The catalog "looks off" or you are about to rely on it.

## When NOT to use

- No README/catalog exists yet — that is `bootstrapping-readme`.
- Auditing shipped code against a spec — that is `verifying-implementation`.

## Process

0. **Classify the repo mode** ([catalog-derivation](./references/catalog-derivation.md) → Repo mode). Single-repo → run steps 1–4 once on the root block. Marketplace → run steps 1–4 per block (each plugin's skills/hooks blocks + the root plugin-index), and confirm the set of per-plugin READMEs matches marketplace.json — a listed plugin with no README is finding #1 for that plugin.
1. **Locate the managed block.** Find its marker pair (`<!-- skills:start --> … <!-- skills:end -->`, `<!-- hooks:start --> … <!-- hooks:end -->`, or `<!-- plugins:start --> … <!-- plugins:end -->` for the root index). **Criterion 1 first:** if the markers are missing, duplicated, reversed, or nested, that is finding #1 and it **blocks** criteria 2–6 (you cannot trust a malformed block) — report and stop.
2. **Re-derive the block from disk** per the [catalog-derivation contract](./references/catalog-derivation.md) (a skills catalog → ROOT, discovery, category, description, ordering, row shape; a hooks catalog → `hooks.json`, discovery, event grouping, description incl. header-comment/fallback, ordering, row shape; the plugin index → marketplace.json / each plugin.json, description, ordering, row shape).
3. **Compare every criterion** (see Report) — do not stop at the first drift; check all five across every row.
4. **Classify** each as Confirmed / Drift / Malformed.

## The report — REQUIRED fixed shape

Emit **exactly these three sections, in this order**, before any edit — same headings, same order, every run. Under **Findings**, one `###` sub-block per managed block audited (single-repo → one; marketplace → one per per-plugin skills/hooks block plus the root plugin-index). Do not rename a heading, add or drop a section, add a table column, or render the Summary as a table. This fixed shape is the point: two runs over the same drift must produce the same structure. A filled reference: [assets/audit-report-example.md](./assets/audit-report-example.md).

```text
# README Catalog Audit — <single-repo | marketplace>

## Findings

### <root skills | plugins/<name> skills | plugins/<name> hooks | root plugin-index>
| Criterion | Disk shows (this session) | Status |
| --- | --- | --- |
| 1 markers well-formed | <…> | <Confirmed | Drift | Malformed> |
| 2 every entry appears exactly once | <…> | <Confirmed | Drift> |
| 3 grouping + ordering match disk | <…> | <Confirmed | Drift> |
| 4 descriptions match the derived one | <…> | <Confirmed | Drift> |
| 5 row link resolves + bold-link bullet shape | <…> | <Confirmed | Drift> |

## Summary
- Blocks audited: <n> · Confirmed: <n> · Drift: <n> · Malformed: <n>

## Recommended disposition
- <block> — <Confirmed → no action | Drift/Malformed → regenerate the block via bootstrapping-readme>
```

The **Findings** table has exactly those three columns in that order, with the five criteria as rows 1–5 in that order (a malformed-markers row-1 blocks rows 2–5 for that block; report it and stop that block). The **Summary** is the one bullet line above, never a table. A drift is always resolved by **regenerating** the derived block, never a hand-patched row.

## Apply the correction

- Regenerate the block content from disk; replace only what is between the markers — prose outside is untouched.
- Re-run the compare pass on the regenerated block; it should show all Confirmed.

## Red Flags — STOP

- "The catalog looks complete" — no per-criterion re-derivation = the audit did not happen.
- Checking only the obvious gap and skipping the other criteria.
- Hand-patching one row instead of regenerating the derived block.
- Editing prose outside the markers.
- In a marketplace, auditing only the root README and skipping the per-plugin blocks, or looking only for `skills:` markers and missing a plugin's hooks block.
- The report deviates from the REQUIRED fixed shape — a renamed heading, an extra column, the Summary as a table, or the five criteria not rendered as rows 1–5 in order. The shape is fixed; match it every run.
