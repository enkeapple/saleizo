---
description: >-
  When dispatching a subagent or workflow agent, assign its model to a DIFFERENT
  one from the implementer for review passes, so the reviewer does not inherit the
  implementer's blind spots. Reading/explore roles take the cheapest tier; an
  implement role takes the cheapest tier that reliably does it. A RED/GREEN
  efficacy or subagent-pressure pair instead holds the model CONSTANT across both
  halves, pinned to a consumer floor, so the injected rule is the only variable.
  Each dispatch carries a one-line cost rationale.
---

# Model Selection by Role

## When

STOP and choose the model deliberately whenever you spawn work in a separate context — an `Explore`/research subagent, an implementer subagent, a reviewer subagent, a **RED/GREEN efficacy or subagent-pressure test agent** (the paired cold runs a skill/rule change is verified with), or a `Workflow` `agent()` call with a `model` option. Applies to every dispatch, in any mode (AUTHOR / AUDIT / APPLY) and in a consumer repo.

## Why

Two levers. **Cost-tiering** (cheap for reading, capable for hard work) a strong caller already applies — keep it, but it is not the value. **Reviewer-model diversity** is the lever that does NOT happen by default: a reviewer left on the implementer's model inherits its blind spots and ratifies the same mistakes even with fresh context, and a capable agent skips the switch unless told ("review is as hard as writing, keep it on the strong model"). Forcing a *different* model is the genuinely independent pass.

## Implementation

Pick the model by the dispatched agent's **role**, and state the cost rationale in the dispatch (one line, so the choice is auditable):

- **review → a model DIFFERENT from the one that implemented (the load-bearing rule).** This is the lever a capable agent skips by default, reusing the implementer's model on the reasoning "review is as hard as writing". Routine per-task review: a different, often *cheaper* tier — independence, not raw power, catches the implementer's blind spots, and it saves tokens. Final whole-change or high-risk review: the most-capable tier, but still a different model than the implementer where the harness offers more than one. _Rationale: the model switch buys defect-catching a same-model reviewer structurally cannot._
- **cost-tiering of the other roles (a strong caller usually already does this — scaffolding, not the point).** Default to *the cheapest model sufficient for the task*; escalating capability is the exception you justify per dispatch, not the starting point. Read-only research/explore → the cheapest capable tier (bulk-token, low-judgment). A well-specified implement task → the cheapest tier that reliably does it (count turns, not just per-token price), escalating to the most-capable tier only for subtle, correctness-critical, or multi-file integration work. Do NOT default every implement task to the premium model.
- **reuse / existing-code search before implementing → dispatch it cheap; do NOT search inline on the implementer's tier.** The lookup for an existing implementation or wrapper (the search behind [reuse-before-reimplement](../clean-code/reuse-before-reimplement.md) — see-also, not required to apply this rule) is mechanical, high-recall, low-judgment work. When it is non-trivial (a large or unfamiliar codebase), dispatch it to a cheap-tier subagent rather than grepping inline on the implementer's often-premium tier. _Rationale: an implementer searching on its own expensive model is the silent default — a cheap search subagent returns the same hits for a fraction of the tokens._
- **RED/GREEN efficacy & subagent-pressure runs → hold the model CONSTANT across both halves, pinned to a representative consumer floor — NOT the most-capable tier, NOT diversified.** These are controlled experiments, not work-plus-review: the injected rule/skill is the ONLY variable allowed to change between the RED (no rule) and GREEN (rule injected) halves, so **both halves run on the same model** — different tiers across halves confound the verdict (the change could be the model, not the rule). Pin that shared model to the weakest harness the change must serve, not the strongest tier: a strong model already complies cold and reports a **false no-op** RED (or false-clean pressure run) — the contaminated-control failure `scoping-rule-value.md` and `scoping-skill-value.md` name. This is the **opposite** of the diversity lever above: diversity reviews a *work product*, constancy isolates a *single variable*, so do NOT apply the "reviewer differs from implementer" rule to a RED/GREEN pair. _Rationale: the inference a RED/GREEN run supports ("the rule caused the change") holds only when the model is held fixed and set low enough to exhibit the failure._

Name **tiers**, not a fixed model — the current Claude mapping is illustrative (cheap ≈ Haiku, standard ≈ Sonnet, most-capable ≈ Opus) and will shift as models are renamed.

### Quick reference — dispatched role → tier

A scannable default for the **cost-tiering** lever. Default a well-specified implement task to **standard**; escalate to **most-capable** only on a real trigger (first attempt failed, 5+ files, an architectural decision, or security-critical code). The **review** rows are deliberately not a fixed tier: a review tier is read off the *implementer's* model (one tier different), never off this table by task — that is the load-bearing rule above, and it overrides any row here.

The **Tier** column is authoritative; the model in parentheses is illustrative and will shift as models are renamed — bind to the tier, not the name.

| Task type | Tier (illustrative model) | Why |
| --- | --- | --- |
| Exploration / search · reuse / existing-code lookup | cheap (≈ Haiku) | bulk-token, high-recall, low-judgment; don't grep inline on the implementer's tier |
| Simple single-file edit · writing docs | cheap (≈ Haiku) | clear instructions, low judgment |
| Multi-file implementation | standard (≈ Sonnet) | best balance for coding |
| Complex architecture / design | most-capable (≈ Opus) | deep reasoning over many interacting parts |
| Debugging a hard bug | most-capable (≈ Opus) | must hold the whole system in mind |
| Security analysis / security-critical code | most-capable (≈ Opus) | cannot afford a missed vulnerability |
| Routine per-task review | **one tier different from the implementer** (prefer cheaper) | independence, not raw power, catches blind spots |
| Final / high-risk / security review | most-capable **and** different from the implementer | top capability *and* an independent pass |
| RED/GREEN efficacy / subagent-pressure run | **same model across both halves**, pinned to a representative consumer floor (NOT most-capable, NOT diversified) | isolate the rule/skill as the only variable; a strong model no-ops it → false-clean RED |

```text
❌ WRONG — caller's premium model inherited for everything; reviewer == implementer.
  dispatch(explore "map the auth module")        model: opus    # premium model just to read files
  dispatch(implement "add one well-specified fn") model: opus    # mechanical task overpaying
  dispatch(review the diff)                       model: opus    # same model → same blind spots

✅ CORRECT — model by role, each with a cost rationale, reviewer differs from implementer.
  dispatch(explore "map the auth module")        model: haiku   # bulk-token read role → cheapest tier
  dispatch(implement "add one well-specified fn") model: sonnet  # mechanical, full spec → standard, not premium
  dispatch(review the diff)                       model: haiku   # routine review → DIFFERENT & CHEAPER than the sonnet implementer (independence, not an upgrade)
```

## Edge Cases

- **When NOT to apply:** work you do yourself in the main context (no dispatch) — you cannot reselect your own running model mid-turn; this rule governs *spawned* agents only.
- **Implementer already on the most-capable tier** → there is no *higher* model for the reviewer. Keep the reviewer a different model anyway (a strong-but-distinct one) for independence; if the harness exposes only one top-tier model, fall back to a fresh-context same-model reviewer and **say so** — independence of context is the residual lever.
- **Only one model available** (no tier choice) → the cost-tiering collapses; still dispatch the reviewer as a fresh context and state that the diversity lever is unavailable.
- A `BLOCKED`/stuck subagent that needs *more* reasoning is re-dispatched on a more capable model — escalating capability on a real block is not a violation of "cheapest that works".
- **RED/GREEN vs review — structural discriminator, not judgment.** A **paired run whose only intended difference is an injected rule/skill/prompt** (RED without, GREEN with) → *constancy* (same model both halves, pinned low). A **single artifact judged for quality** (code, diff, doc) → *diversity* (reviewer ≠ implementer). Crossing them breaks the result: diversity on a RED/GREEN pair confounds the verdict; constancy on a review forfeits the independent pass. Can't point to the injected-only variable? It's a review — use diversity.
- **No model at the consumer floor available** (the harness exposes only strong tiers) → run RED/GREEN on the lowest available tier, hold it constant, and **state that the floor is above the real consumer's** — a green RED there is weaker evidence, per the export-floor carve-out in `scoping-rule-value.md`.

## Review Checklist

- [ ] The reviewer's model differs from the implementer's — derived one tier off the implementer (NOT read as a fixed task-row from the quick-reference table); or on a top-tier/single-model harness the reviewer is at least a fresh context and that is stated. The load-bearing check.
- [ ] Each subagent/workflow dispatch states the model tier AND a one-line cost rationale for that role.
- [ ] No premium model used for a pure research/explore/read-only role, and no premium default for a mechanical implement task.
- [ ] A non-trivial pre-implementation reuse/existing-code search was dispatched to a cheap tier, not run inline on the implementer's (premium) model.
- [ ] Model named as a tier (cheap/standard/most-capable) with any concrete model marked illustrative — not a hard-coded model as the only option.
- [ ] A RED/GREEN efficacy or subagent-pressure pair ran BOTH halves on the same model, pinned to a representative consumer floor — not diversified across halves, not defaulted to the most-capable tier (or the floor-above-consumer caveat was stated).
- [ ] Named which lever applies before picking — constancy for a RED/GREEN experiment, diversity for a work-product review — and did not cross them.
- [ ] Not applied to non-dispatched, in-context work.
