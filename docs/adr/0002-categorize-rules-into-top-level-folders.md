# ADR-0002 — Categorize rules into top-level concern folders

- **Status:** Accepted
- **Date:** 2026-07-23
- **Deciders:** Oleksandr Bilyk
- **Related:** [ADR-0001](0001-tier-the-iron-law-and-add-adherence-testing.md), [rule-self-containment](../../.claude/rules/authoring/rule-self-containment.md), [markdown-style](../../.claude/rules/conduct/markdown-style.md)

## Context

`.claude/rules/common/` had grown into a 16-file catch-all mixing four unrelated concerns — false-clean verification guards, skill/rule authoring discipline, SDD-chain UX presentation, and cross-cutting agent conduct. Navigating it by filename alone was guesswork. The sibling folders `domains/`, `clean-code/`, `anti-patterns/` were already concern-scoped; `common/` was the exception. Rules resolve by bare-name glob (`rules/**/<name>.md`) and by `paths:` content, so folder location is organizational, not functional — but three `ruleGates` entries in `skills-routing.json` and several `CLAUDE.md` see-also links pin full `rules/common/...` paths.

## Decision

We split `common/` into four top-level folders — `verification/`, `authoring/`, `workflow/`, `conduct/` — as siblings of the existing concern folders, and emptied `common/`. Chosen over **sub-folders inside `common/`**, which would push files to three levels deep and break every `../../CLAUDE.md`-style relative link in the moved files (top-level folders keep the two-level depth those links assume); and over an **index-only README**, which leaves the flat directory and delivers no real structure. The cost we accept: the three pinned `ruleGates` paths, the `CLAUDE.md` "Where rules live" table, `lessons-learned.md` provenance, and the consumer-vault copies must all be updated in lockstep with the move — a wide but one-time edit.

## Related files

- `.claude/rules/{verification,authoring,workflow,conduct}/` — the four new concern folders (`common/` now empty)
- `.claude/skills-routing.json` → `ruleGates` — three entries pinning moved-rule paths; updated to the new folders
- `CLAUDE.md` → "Where rules live" — the human-facing folder map
