---
description: >-
  Before shipping any edit that REMOVES content from a skill body or its
  references (dedup, prune, SSoT-pointer replacement, disjoint-list split),
  classify every removed chunk as no-op / relocated(name+verify the home) /
  dropped(blocker), treat a proactive cross-skill trigger as load-bearing, and
  confirm with an independent Layer-2 on a different model/context — self-review
  misses the drop it just made.
paths:
  - 'plugins/**/SKILL.md'
  - 'plugins/**/references/*.md'
  - '.claude/skills/**/*.md'
---

# Dedup Drop — Classify Every Removed Chunk

## When

STOP and apply this **before shipping any edit that removes content from a `SKILL.md` body or its `references/*.md`** via a dedup, prune, single-source-of-truth (SSoT) pointer replacement, or disjoint-list split. The failure this guards is a **silent drop**: a load-bearing element removed without a surviving, reachable home.

Do NOT skip because the removed content "delegates to another skill", "is covered elsewhere", or "is just the mirror of a Red Flag" — those three framings are exactly what let the recorded drops slip past self-review.

## Why

Three different dedup levers each silently dropped a load-bearing element the author's own review missed (promoted from a 3× lesson cluster):

- **Workflow-hook trimming** — cut bullets that "delegate to another skill", conflating re-teaching that skill's *mechanics* (safe) with the *trigger to invoke it at a specific moment* (unique to this skill — cutting it stops the behavior).
- **SSoT-pointer replacement** — replaced an inline block with a pure pointer, pushing the identity the consumer needs *at point of use* behind the pointer along with the definitions that belong there.
- **Disjoint Checklist/Red-Flags split** — removing mirror-inverse items also removed a completion gate whose Checklist home was the author's "am I done?" sweep.

The unifying root cause: a "covered elsewhere / mirror item" framing classified the drop as safe without verifying every consumer path still had what it needs — and self-review cannot catch the error it just committed.

## Implementation

Run these three steps before shipping the pruning edit:

1. **Classify every removed chunk** — for each removed block, sentence, or bullet, assign one label:
   - `no-op` — truly redundant; the identical instruction survives elsewhere verbatim.
   - `relocated(home)` — name the exact file/section it lands in AND confirm that home is reachable on this skill's normal invocation path.
   - `dropped` — no surviving home. **A `dropped` label blocks the ship**: restore it, inline a compact substitute, or document the deliberate behavior removal.
2. **Test each bullet that names another skill** for the trigger-vs-mechanics split:
   - *re-teaches the other skill's mechanics* (how it works, what it produces) → safe to cut; that skill owns it.
   - *triggers or offers invoking it at a specific moment* (when / whether to act) → **load-bearing**; keep the trigger, cut only the re-taught mechanics.
3. **Dispatch an independent Layer-2** on a **different model/context** with the diff plus your classification table; its job is to confirm every `relocated` has a reachable home and no `dropped` chunk was load-bearing. A same-model, same-context review is not independent — the author's blind spot propagates.

```text
❌ WRONG — self-review only; "delegates to another skill" used as the cut signal.
Removed four §3 bullets because they "re-teach what grilling / the glossary skills own."
Self-review passed. Two were cross-skill triggers (offer an ADR on rejection; update the
glossary as terms crystallize) that fire nowhere else → behavior silently lost.

✅ CORRECT — classification table, then independent Layer-2.
Removed four bullets → classify:
  - bullet 1: no-op (identical text in the target skill)
  - bullet 2: relocated(grilling §…) — verified reachable
  - bullet 3: DROPPED blocker — a trigger no other skill names → restore compactly
  - bullet 4: re-taught mechanics only → safe cut
Independent Layer-2 (different model) confirmed 1/2/4, flagged 3. Bullet 3 restored as
trigger + action only (mechanics still single-sourced).
```

## Edge Cases

- **When NOT to apply** — a pure formatting/typo fix that removes no semantic content; no classification needed.
- **Whole-skill deletion** is out of scope — that is a routing / orphan-reference question, not chunk classification.
- **Disjoint Checklist vs Red-Flags** — a completion gate ("am I done?") may legitimately live in BOTH lists; disjointness applies only to mirror-inverse items that add no new information. Never drop a completion-gate Checklist row just because its inverse survives in Red Flags.
- **SSoT-pointer replacement** — the fix for a dropped point-of-use identity is NOT to revert the single source: keep the names/identity the consumer needs inline, with the full definitions behind the pointer.
- **Empirical basis** — this rule was promoted from three reproduced incidents rather than a synthetic cold RED/GREEN; the reproductions are the evidence it steers behavior (see also [scoping-rule-value](./scoping-rule-value.md) for the cluster-promotion carve-out — not required to apply this rule).

## Review Checklist

- [ ] Every removed chunk carries a label: `no-op` / `relocated(home)` / `dropped`.
- [ ] No `dropped` chunk ships unresolved (restored, substituted, or its removal explicitly documented).
- [ ] Every `relocated(home)` names a specific file/section AND was verified reachable from this skill's normal invocation path.
- [ ] Every bullet naming another skill was tested for trigger-vs-mechanics; triggers kept, re-taught mechanics cut.
- [ ] An independent Layer-2 on a **different model/context** reviewed the diff + classification table before ship — a same-model review does not satisfy this.
