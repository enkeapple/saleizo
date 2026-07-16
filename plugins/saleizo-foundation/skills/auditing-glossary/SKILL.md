---
name: auditing-glossary
description: >-
  Use to check whether the foundational rules (the domain glossary and framework
  charter under .claude/rules/domains/) still match the current code, and to
  correct them when they drift. Triggers on: "audit the rules", "is the glossary
  still accurate", "the framework rule looks stale", "rule drift", "check the
  base rules", "update the glossary".
allowed-tools: Read, Grep, Glob, Edit
---

# Auditing Glossary

Verify the foundational rules — the domain glossary and framework charter — against the current code, report the drift, then correct it. **A wrong rule is worse than no rule**: it actively misleads the next session by laundering a stale claim as truth.

**Every concrete thing a rule asserts — a symbol, path, route, type, command, or ownership-table cell — is a structural claim, and editing a rule doc is editing code.** Re-verify each against the code *this session*; a claim that greps to nothing is a hallucination, not a detail. Memory does not count — the file is right by definition, your recollection is not.

Pairs with `bootstrapping-glossary`, which creates the foundational docs this skill keeps true.

## When to use

- Periodic maintenance of `.claude/rules/domains/` (glossary, framework) — especially after refactors, renames, or dependency/command changes.
- A rule "looks off" or contradicts something you just saw in the code.
- Before relying on a foundational rule for a non-trivial task.

## When NOT to use

- The docs don't exist yet — that is `bootstrapping-glossary`.
- Auditing shipped code against a spec — that is `verifying-implementation`.

## Process

1. **Enumerate every concrete claim.** Walk the doc and list each verifiable assertion: every path, route/constant, type/enum, command, and ownership-table cell. The unflagged majority matters as much as anything that "looks" stale.
2. **Verify each against current code.** `grep`/`read` for the real symbol/path/command — do not stop at the one obvious drift. Record the result per claim. Also flag **placeholder-key drift** against [placeholder-keys.md](../shared/placeholder-keys.md): an unresolved `<key>` token left in a generated glossary/charter, or a registry example-noun in a generator-owned slot, is drift; cautionary prose naming a noun is not.
3. **Classify each claim:**
   - **Confirmed** — matches the code.
   - **Stale doc** — code is correct, the doc is out of date (renamed route, moved path, changed command).
   - **Code drift** — the doc states an intended rule and the code violated it (an unauthorized divergence). The fix may be to revert the *code*, not the doc.
   - **Hallucination** — the claim greps to nothing in either; it never existed or both moved.
4. **Decide direction before editing** (the source-of-truth call): for *stale doc* and *hallucination*, fix the doc. For *code drift*, do NOT silently rewrite the rule to bless the divergence — surface it as a decision: revert the code to the rule, or change the rule deliberately?

## The report — REQUIRED fixed shape

Emit **exactly these four sections, in this order**, before any edit — same headings, same order, every run. Do not rename a heading, add or drop a section, add a column, or render the Summary as a table. This fixed shape is the point: two runs over the same drift must produce the same structure. A filled reference: [assets/audit-report-example.md](./assets/audit-report-example.md).

```text
# Domain-Rules Audit — <doc filename>

## Claims checked
| Claim (doc says) | Code shows (grep/read this session) | Status |
| --- | --- | --- |
| <claim> | <what the code actually shows> | <Confirmed | Stale doc | Code drift | Hallucination> |

## Summary
- Confirmed: <n> · Stale doc: <n> · Code drift: <n> · Hallucination: <n>

## Decisions needed
- <each Code-drift / ambiguous-source finding> — recommended: <revert code | change the rule>
(none → the single line: "No decisions needed — every finding is a surgical doc fix.")

## Decision
<the archetype C-drift picker — the three options in "Required decision after the report" below>
```

The **Claims checked** table has exactly those three columns in that order (no index column). The **Summary** is the one bullet line above, never a table. The **Decision** section is the C-drift picker verbatim, never folded into a prose trailer.

## Required decision after the report

End with **one** picker (archetype C-drift; markdown-list fallback), never one picker per finding — which is why the report records a recommended disposition per finding:

- `Apply recommended` → apply each finding's recommended disposition (stale-doc/hallucination fixed surgically; code-drift only as recommended).
- `Adjust per-finding` → walk findings one by one.
- `Stop` → take no action now.

## Apply the corrections

- **Stale doc / hallucination:** fix the specific cell/line — a surgical edit, not a rewrite of the whole doc. Re-verify the corrected claim.
- **Code drift:** apply only what the user chose.
- Leave Confirmed claims untouched.
- After editing, re-run the enumerate→verify pass on what you changed; the diff should touch only the drifted claims.

## Red Flags — STOP

Symptoms you can catch yourself in (the table below is the *excuse* behind each):

- The doc "passed" but you ran no grep/read this session — that is a reading, not an audit.
- Your edit changes a claim you never enumerated in step 1 — you checked only the flagged cell.
- The diff rewrites whole paragraphs to correct a single wrong cell.
- A rule now matches drifted code and you never surfaced the revert-or-change choice.
- The report deviates from the REQUIRED fixed shape — a renamed heading, an extra column, the Summary as a table, or the Decision merged into a prose trailer. The shape is fixed; match it every run.

## Rationalizations

| Excuse | Reality |
| -------- | --------- |
| "It looks accurate." | Looks ≠ verified. Grep each claim; the stale one is usually the cell you'd have skipped. |
| "Only the flagged row is wrong." | Nothing flags the others. The audit covers every claim or it isn't an audit. |
| "Code changed, so the doc is stale." | Maybe — or the code drifted from an intended rule. Decide direction; don't auto-bless the code. |
| "I'll just rewrite the doc fresh." | A rewrite re-introduces unverified prose. Fix the drifted claims surgically. |
