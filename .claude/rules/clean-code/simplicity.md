---
description: 'Solve the stated problem with the least code that works — prefer the simplest readable construct over clever compression'
paths:
  - '**/*.{ts,tsx,js,jsx}'
---

# Simplicity — solve it with the least code that works

## When

STOP and simplify whenever a diff introduces: nested `if/else` more than two levels deep where an early return would flatten it; a `reduce` doing what a `map`/`filter`/`find` already expresses; a lookup table or wrapper layer standing in where a plain literal or direct value would do at a single call site; or any construct you had to explain aloud before trusting it. Applies while writing new code and while reviewing a diff — not a call to rewrite unrelated working code. (A *config object / options bag* built for one value is not this rule's finding — that is anticipated-future-variance structure, owned by [no-over-engineering](./no-over-engineering.md).)

## Why

Every extra branch, layer, or clever trick is a moving part a future reader must hold in mind to trust the change is correct. The simplest construct that solves the stated problem is the fastest to review, the safest to change, and the least likely to hide a bug in its own cleverness. The common AI reflex is to over-build: reach for a generic helper, a config layer, or a dense one-liner when a plain guard clause or a direct loop would say the same thing in less mental effort — optimizing for looking sophisticated instead of being clear.

## Implementation

**Write the plainest construct a reader can verify at a glance, not the fewest characters.**

- **Guard clauses over pyramids:** return/throw early on the invalid or edge case first, then let the main logic run unindented — don't nest the happy path inside `if` after `if`.
- **The direct array method over a repurposed one:** a plain `map`, `filter`, or `find` when that's the actual shape of the work; reach for `reduce` only when the result genuinely isn't a map/filter (e.g. building a single aggregate value).
- **A literal over a layer, for one use:** a single hard-coded constant or inline value beats a factory or lookup table that exists to serve exactly one call site. (A *config object / options bag* for one value is speculative structure, not present-tense clutter → [no-over-engineering](./no-over-engineering.md).)
- **Readability wins ties:** if a shorter version needs a comment to explain what it does, the longer, plainer version is the simpler one.

```text
❌ WRONG — nested pyramid, and reduce standing in for filter+map:
function getActiveNames(users: User[]): string[] {
  return users.reduce((acc, u) => {
    if (u.active) {
      if (u.name) {
        acc.push(u.name.toUpperCase());
      }
    }
    return acc;
  }, [] as string[]);
}

✅ CORRECT — guard clause shape, direct filter + map:
function getActiveNames(users: User[]): string[] {
  return users
    .filter((u) => u.active && u.name)
    .map((u) => u.name.toUpperCase());
}
```

## Edge Cases

- **When NOT to apply** — essential/irreducible complexity (a genuinely multi-branch state machine, a real multi-step algorithm) is not the target; don't flatten a diagram-shaped problem into a false one-liner to "look simple".
- A dense clever one-liner that trades readability for brevity is NOT simpler under this rule — fewer characters is not the goal, fewer things-to-hold-in-mind is.
- Splitting one clear function into several indirection layers "for simplicity" often makes it harder to follow — see-also [no-needless-indirection](./no-needless-indirection.md).
- Splitting a function along *genuine* responsibilities (fetch vs validate vs persist) is NOT the target here — that is required by [concise-functions](./concise-functions.md); this rule discourages only layers that add no responsibility. "Fewest things to hold in mind" counts branches, layers, and named concepts a reader must track — not raw function count and not characters; do not cite this rule to resist a correct responsibility-split.
- Before writing a new helper to solve this, check whether one already exists — see-also [reuse-before-reimplement](./reuse-before-reimplement.md).
- Adding a *class/interface/strategy/config-system/extension-point* the stated task did not ask for is speculative structure for a hypothetical future, not present-tense simplicity — that is see-also [no-over-engineering](./no-over-engineering.md), a distinct concern.
- A guard clause that itself grows past a few conditions is a sign the function is doing too much, not a case for more nesting.
- **Export-floor policy rule.** A strong agent already writes guard clauses and direct `map`/`filter` cold, so an in-repo RED reproduces no failure (the strong-model no-op / contaminated control of [scoping-rule-value](../common/scoping-rule-value.md)); its always-on load is earned in weaker / non-agentic consumer harnesses where the over-build reflex is default. RED against a representative consumer floor, not the in-repo tier.

## Review Checklist

- [ ] No `if` nested more than two levels deep where an early return/guard clause would flatten it.
- [ ] Every `reduce` call is building a genuine aggregate, not standing in for a `map`/`filter`/`find`.
- [ ] No lookup table or wrapper layer stands in for a plain literal at a single call site — check its reference count (a *config object / options bag* for one value is [no-over-engineering](./no-over-engineering.md)'s finding, not this rule's).
- [ ] No line needs an inline comment just to explain what it does — that flags a clever construct for the simpler one.
- [ ] Diff was read once as "could this be plainer without losing correctness?" before marking it done.
