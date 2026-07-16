# ADR-0001 — Tier the Iron Law by edit-type and add adherence testing (Law #2)

- **Status:** Accepted
- **Date:** 2026-07-09
- **Deciders:** Oleksandr Bilyk (owner)
- **Related:** decision-council pressure-test of the Iron Law (this session); [framework.md](../../.claude/rules/domains/framework.md) (Iron Law / Implementation Protocol); [.claude/CLAUDE.md](../../.claude/CLAUDE.md) (Non-negotiables, Completeness Checklist)

## Context

The repo's #1 Non-negotiable — "no skill or skill edit without a failing RED test first; no exception for simple edits" — is TDD ported onto markdown-instruction authoring, where the "test" is a subagent pressure run (RED without the skill, GREEN with it). Two defects surfaced. (a) Production telemetry shows a ~98% skill-bypass rate: skills that all passed RED→GREEN are routed around in real use, so the authoring gate has near-zero predictive validity for adherence. (b) A blanket "no exception even for a typo" forces either a fabricated RED or a silent bypass on edits with no behavioral hypothesis to falsify; the repo's own lessons already log "test passes for the wrong reason" and "overtrusting GREEN". A five-lens decision-council pressure-test of the law itself forced the choice.

## Decision

Tier the Iron Law by edit-type, classified by a mechanical reversion test — "if I revert this edit, does a subagent given the same task behave differently?". **Behavioral** edits (new skill, or a body change to a recipe/prohibition/decision point) → full RED/GREEN. **Descriptive** edits (frontmatter `description`, triggers, reference prose that does not change the recipe, word-count/structure) → one cited real prior failure inline in the commit. **Mechanical** edits (typo, link, fence, formatting) → validators only. An edit with no citable failure is filed one tier down **with that absence stated** (honest-downgrade), never silently. Separately, introduce **Law #2 — adherence testing**: a recurring `skill-comply` + `reviewing-telemetry` run against production samples with a tracked bypass baseline, because authoring rigor is only verifiable against production adherence. Canonical text lives in `framework.md`; both CLAUDE.md files point at it.

## Options considered

- **Option A (chosen) — Tier + Law #2.** Keeps the paired run where it uniquely proves a specific edit changes a fresh agent's behavior, drops it where there is no behavior to change, and adds the missing production-adherence measurement. Won because it preserves the law's real guarantee while ending the fabricate-or-bypass tax and finally instrumenting the 98% number.
- **Option B — Keep the blanket law unchanged.** Rejected: the "no exceptions, even for a typo" clause forces fabricated REDs or silent bypass on trivial edits (superstition, not discipline), and never addresses adherence.
- **Option C — Scrap RED/GREEN entirely, replace with "cite the failure before you fix".** Rejected: a citation alone cannot establish that a *new* behavioral skill changes a fresh agent's behavior — the one thing the paired cold/skilled run uniquely does.

## Consequences

- **Negative / cost:** the Descriptive tier's "cite-or-downgrade" bar relies on honest self-reporting; a dishonest downgrade re-creates the bypass one tier down. Law #2 adds a recurring token/time cost and needs a kill switch before any unattended run.
- **Follow-ups:** write the tier classifier + honest-downgrade clause into `framework.md`; update the Completeness Checklist "RED observed" row (Tier 2 citation / Tier 3 N/A — mechanical); reduce both CLAUDE.md Iron Law paragraphs to pointers at `framework.md`; stand up Law #2 as a gated `skill-comply` + `reviewing-telemetry` run — its **unattended** form must first pass the prior councils' RED-gate (name one real 30-day undetected defect) and ship a kill switch; re-poll after one measurement cycle on whether the bypass rate moved (if it did not, the authoring gate was the wrong lever and routing/trust is next).

## Related files

- `.claude/rules/domains/framework.md` → Iron Law / Implementation Protocol — canonical location of the tier classifier and honest-downgrade clause.
- `.claude/CLAUDE.md` → Non-negotiables #1 + Completeness Checklist — Iron Law pointer and the "RED observed" row.
- `CLAUDE.md` → Hard rules — Iron Law pointer.
