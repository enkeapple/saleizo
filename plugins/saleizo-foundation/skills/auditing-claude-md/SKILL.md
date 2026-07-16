---
name: auditing-claude-md
description: >-
  Use to check whether the project's CLAUDE.md files (root entry point and
  .claude/CLAUDE.md operating manual) still match the repo and each other, and
  to correct them when they drift. Triggers on: "audit CLAUDE.md", "is CLAUDE.md
  accurate", "the commands in CLAUDE.md look stale", "CLAUDE.md drift", "update
  the engineering system", "check the operating manual".
allowed-tools: Read, Grep, Glob, Edit
---

# Auditing CLAUDE.md

Verify the two CLAUDE.md files — the root entry point and `.claude/CLAUDE.md` operating manual — against the current repo AND against each other, report the drift, then correct it. **A wrong CLAUDE.md is worse than none**: a stale command or a dead pointer misleads every session that trusts it.

**Every concrete thing these files assert — a command, a file/folder path, a stack version, a routed skill/command, a cross-link — is a structural claim, and editing CLAUDE.md is editing code.** Re-verify each against the repo this session; a command not in `package.json`, a pointer to a missing folder, a stack version that disagrees with the lockfile are drift, not detail. Memory is not evidence.

Mirrors `auditing-glossary` (same discipline, applied to the foundational rules). Pairs with `bootstrapping-claude-md` (which creates these files).

## When to use

- Periodic maintenance, especially after dependency bumps, script renames, folder moves, or adding/removing skills.
- A command or pointer "looks off", or the two files seem to disagree.

## When NOT to use

- The files don't exist yet → `bootstrapping-claude-md`.
- Auditing `.claude/rules/` content → `auditing-glossary`.

## Process

1. **Enumerate every concrete claim across BOTH files.** List each: command (tables + checklist verification rows), file/folder path & cross-link, stack/version claim, routed skill or slash command, and any named protocol.
2. **Verify each against the repo this session.** The repo's manifest (`package.json`/`Cargo.toml`/`go.mod`/…)/Makefile/CI for commands; the filesystem for paths/folders; the lockfile for versions; the skill/command registry for routing targets. Do not stop at the obvious one — the unrunnable checklist row is usually the one you'd skim. Then apply, to every generated slot in both files, the five **manual-governance drift classes** in [references/drift-classes.md](./references/drift-classes.md) and the **placeholder-key** detection contract in [placeholder-keys.md](../shared/placeholder-keys.md). Each reference carries its own falsifiable signals — read them per signal, don't eyeball.
3. **Run the cross-file consistency pass.** The root and the manual must agree: same pipeline name/vocabulary, same Role/position, same commands, no contradiction. The root stays a thin index — governance that is duplicated in both files is drift waiting to happen; it should live in the manual and be pointed to.
4. **Classify each finding:** Confirmed / Stale doc (repo right, doc outdated) / Code drift (doc states an intended rule the repo violated — fix may be the *code*) / Broken (command/path/skill that resolves to nothing) / Inconsistent (the two files disagree).
5. **Decide direction before editing:** Stale/Broken → fix the doc. Inconsistent → pick the single source (usually the manual) and make the other point to it, don't duplicate. Code drift → surface as a decision, don't silently rewrite the doc to bless it.

## The report — REQUIRED fixed shape

Emit **exactly these five sections, in this order**, before any edit — same headings, same order, every run. Do not rename a heading, add or drop a section, add a table column, or render the Summary as a table. This fixed shape is the point: two runs over the same drift must produce the same structure. A filled reference: [assets/audit-report-example.md](./assets/audit-report-example.md).

```text
# CLAUDE.md Audit

## Claims checked
| Claim | File | Repo shows (this session) | Status |
| --- | --- | --- | --- |
| <claim> | <root | manual> | <what the repo shows> | <Confirmed | Stale doc | Broken | Code drift | Inconsistent> |

## Cross-file consistency
- <pipeline | Role | commands | pointers>: <agree | MISMATCH — the two files disagree, consolidate to …>
(all agree → the single line: "Root and manual agree — no cross-file mismatch.")

## Summary
- Confirmed: <n> · Stale doc: <n> · Broken: <n> · Code drift: <n> · Inconsistent: <n>

## Decisions needed
- <each Code-drift / Inconsistent / ambiguous-source finding> — recommended: <disposition>
(none → the single line: "No decisions needed — every finding is a surgical fix.")

## Decision
<the archetype C-drift picker — the three options in "Required decision after the report" below>
```

The **Claims checked** table has exactly those four columns in that order (no index column). The **Summary** is the one bullet line above, never a table. The **Decision** section is the C-drift picker verbatim, never folded into a prose trailer.

## Required decision after the report

End with **one** picker (archetype C-drift; markdown-list fallback), never one picker per finding — which is why the report records a recommended disposition per finding:

- `Apply recommended` → apply each finding's recommended disposition (stale/broken fixed surgically; code-drift only as recommended).
- `Adjust per-finding` → walk findings one by one.
- `Stop` → take no action now.

## Apply the corrections

- **Stale / broken:** fix the specific command/path/version — surgical, not a rewrite. Re-verify each fix.
- **Inconsistent:** consolidate to the single source; make the other a pointer.
- **Code drift:** apply only what the user chose.
- Keep the root a thin entry point; keep Confirmed claims untouched.

## Red Flags — STOP

- "I read it, looks fine" — no per-claim verification = the audit didn't happen.
- Auditing one file and ignoring the other, or skipping the cross-file consistency pass.
- Fixing a drifted command by duplicating governance into the root instead of pointing to the manual.
- The report deviates from the REQUIRED fixed shape — a renamed heading, an extra column, the Summary as a table, a dropped Cross-file consistency section, or the Decision merged into a prose trailer. The shape is fixed; match it every run.
- A **manual-governance drift signal** fires and you let it pass — eyeballing the lessons / design-docs / baseline wording instead of running the falsifiable signals in [references/drift-classes.md](./references/drift-classes.md).

## Rationalizations

| Excuse | Reality |
| -------- | --------- |
| "The commands look right." | Looks ≠ runs. Check each against the repo's manifest/Makefile/CI; the stale one is the row you'd skip. |
| "Only the flagged line is wrong." | Nothing flags the rest. The audit covers every command, path, and pointer in both files. |
| "Repo changed, so the doc is stale." | Maybe — or the repo drifted from an intended rule. Decide direction; don't auto-bless the code. |
| "The two files say it differently, I'll leave both." | Two copies drift apart — that's how they got here. One source; the other points to it. |
| "The manual's lessons/design-docs/baseline wording is close enough." | The five manual-governance drift classes each misfire silently; apply [references/drift-classes.md](./references/drift-classes.md) per signal, don't eyeball them — including a baseline section that's absent only when the repo *declared* none. |
