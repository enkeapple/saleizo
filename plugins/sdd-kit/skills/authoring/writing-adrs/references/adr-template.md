# ADR Templates

Match the repo's existing ADR **structure** first (location, numbering, status, sections) — but never copy a `path:line`-in-prose or embedded-rules habit from older ADRs; the readability discipline overrides it. When there is no convention, use one of the two shapes below — **pick the register** (see the skill body): **narrative** for a conceptual / approach decision where the reasoning is the value, **template** for a decision bound to one concrete mechanism. Both obey the same discipline: **be brief** (each section a few sentences, the whole ADR fits one screen — a record, not a walkthrough); **no `path:line` in the prose** (name code by file + symbol; line anchors live ONLY in a short `Related files` section, file → symbol, at most one short `path:line`, never ranges, never a long dump); **no embedded "developers MUST…" list** (link practices to the repo's conventions location). An optional **`Related`** header field carries provenance and cross-links — the originating ticket/issue id (illustrative: `PROJ-1234`), sibling ADRs, and the conventions doc that holds any practices this decision implies (this is where the "no embedded rules" link goes). `Deciders` is optional too. Resist only `Implementation Notes` or raw external-URL dumps — that bloat is a smaller model's tell.

## Narrative shape

The lighter form — `Context` + `Decision` + `Related files`, **no** separate `Options`/`Consequences` sections. The trade-off (why not the alternatives, what it cost) is woven into the prose. Default to this for most decisions.

```text
# ADR-NNNN — <short imperative title>

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** <team / author>                                  (optional)
- **Related:** <ticket id, e.g. PROJ-1234>, [ADR-NNNN](NNNN-….md), [conventions doc](…)   (optional)

## Context
<What forced it: the problem, constraints, current state. ≤ ~120 words.>

## Decision
<We <decision in one or two sentences, active voice>. Then, in prose: why the chosen
path won over the alternatives — name them and what they cost — and the cost we
accept. Name code by file + symbol (`handleTokenRefresh` in `baseQuery.ts`); no
path:line here. ≤ ~120 words.>

## Related files   (optional, keep short)
- `baseQuery.ts` → `handleTokenRefresh` — <one-line what it is>
```

## Template shape

The heavier form — for a weighty mechanism-bound decision where a reader wants the alternatives and costs laid out navigably. The four bold slots are **REQUIRED** — an ADR in this register missing any one is incomplete. (If two full sections feel like bloat, use the narrative shape instead.)

```text
# ADR-NNNN — <short imperative title>

- **Status:** Accepted
- **Date:** YYYY-MM-DD
- **Deciders:** <team / author>                                  (optional)
- **Related:** <ticket id, e.g. PROJ-1234>, [ADR-NNNN](NNNN-….md), [conventions doc](…)   (optional)

## Context           (REQUIRED)
The problem, the constraints, the current state. What forced a decision. (≤ ~120 words.)

## Decision          (REQUIRED)
The single choice made, in one short paragraph (≤ ~120 words). Name the code that
implements it by file + symbol in plain text (`handleTokenRefresh` in `baseQuery.ts`)
— NO `path:line` here; line anchors go in `Related files` only. Do not narrate every
branch — state the choice, not the control flow.

## Options considered (REQUIRED)
- **Option A (chosen)** — why it won.
- **Option B** — why it lost.
- **Option C** — why it lost.

## Consequences       (REQUIRED)
- Negative / cost: … (the price you are accepting — there is always one; this is the
  load-bearing part, do not skip it)
- Follow-ups: what must change later as a result.
- (Positive only if it is not already obvious from the Decision — skip the redundant restate.)

## Related files      (optional, keep short)
- `baseQuery.ts` → `handleTokenRefresh` — <one-line what it is>
- `utils.ts` → `forceLogout` — <one-line what it is>
```

## Notes

- **`Status`** uses the repo's vocabulary. Default set: `Accepted`, `Superseded by ADR-MMM`, `Deprecated`. A brand-new ADR for a decision already in code is `Accepted`, not `Proposed`.
- **Be brief.** Each section a few sentences; the whole ADR fits on one screen. A record states *what* and *why* — it does not narrate the code's control flow. If a section reads like a walkthrough, cut it.
- **`path:line` ONLY in `Related files`.** Body prose names code by file + symbol with no line numbers. Collect the few important anchors in one short `Related files` section — file → symbol, at most one short `path:line` for the single anchor that pinpoints the decision. Never a range, never one per claim, never a long dump — that is the code-map anti-pattern that rots on the next commit. Every reference you write is one you opened this session; an unopened `path:line` is fabricated.
- **No embedded rules.** Practices ("always import leaf files", "gitignore the cache artefact") are not ADR content. Record the decision and its consequences; put the practices in the repo's conventions location (a rule, a lint check, `CONTRIBUTING`) and link to it.
- **Numbering.** `max(existing number) + 1`, zero-padded to the repo's width. Never backfill a gap, never reuse a number, never collide.
- **The weighed alternatives are what justify the ADR existing** — they are the trade-off the Gate required (the `Options considered` slot in the template shape; the "why the chosen path won" paragraph in the narrative shape). If you cannot fill them with real alternatives, the decision probably failed the Gate.
