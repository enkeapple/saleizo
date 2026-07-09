---
description: Before asserting a usage/behavior conclusion from an aggregate, a metric's shape, or a theoretical/worst-case cost (telemetry, routing, latency, cost audits), verify it against the real underlying data — exclude non-production noise, read the emitting mechanism, and confirm which branch is actually taken. A count/shape/worst-case is a lead, not a verdict. Always-on; triggered by asserting a telemetry/usage/audit conclusion, not by a file type.
---

# Usage-Claim Verification

## When

STOP and apply this before you assert any conclusion about **usage or behavior** drawn from an aggregate, a metric's shape, or a theoretical/worst-case cost — e.g. "skill X is the dominant bypass offender", "this branch is the bottleneck", "this metric reads 100% because of Y" — in a telemetry/routing review, a latency/cost audit, or any report over instrumented data. Applies the moment you are about to name a cause, an offender, or a bottleneck.

Do NOT skip because the number "looks decisive" — the three incidents below all looked decisive and were wrong.

## Why

An aggregate count, a degenerate metric shape, or a branch's theoretical cost is a **lead, not a verdict**. Promoted from three reproduced incidents that each named the wrong cause/offender/bottleneck this way:

- **Fixture noise in the aggregate** — a raw per-skill bypass count named `writing-specs` (87, of which 58 from one prompt_hash) as the defect; excluding `fixture*` sessions dropped it to 5 and the real offender was `resolving-requirements`. `scripts/metrics-report.sh` does NOT exclude fixtures, so its headline is contaminated.
- **Metric-shape diagnosis** — a 100% bypass-rate was diagnosed from its shape twice (guessed regex, guessed instrumentation) before reading the emitting hook's actual match logic and the raw per-event records.
- **Theoretical branch cost** — a latency audit ranked `subagent-driven-development` the dominant cost from its dispatch count on paper, without checking that the owner almost always runs the `inline` branch (0 dispatches).

## Implementation

Before naming a usage/behavior conclusion in an audit or report, do all three that apply:

1. **Exclude non-production noise, then confirm the finding survives.** Drop fixture/test sessions (e.g. `select((.session|tostring|test("fixture"))|not)`) and any synthetic data from the aggregate; re-run and confirm the conclusion still holds on production-only events. Treat a pre-built aggregator's headline (e.g. `metrics-report.sh`) as contaminated until you have checked what it includes.
2. **Read the emitting mechanism, not just the printed value.** Before asserting *why* a metric reads as it does, read the instrumentation that produces it — the hook's matching logic (incl. `grep` case flags), the metric's definition (per-turn vs cross-turn), the raw per-event records.
3. **Confirm which branch is actually taken.** For a user-selectable fork (mode A/B, sync/async, cached/cold), establish the branch actually exercised — ask the owner or read real telemetry — before ranking any branch-specific cost. Never rank a branch dominant on its theoretical/worst-case shape alone.

```text
❌ WRONG — "writing-specs: 87 bypasses, 58 from one prompt_hash" reported as the defect, straight
   from the raw aggregate; the 58 were one fixture session (excluded → count drops to 5).
❌ WRONG — ranked subagent-driven-development the dominant latency cost from its dispatch count on
   paper, without checking which fork branch the owner actually runs.

✅ CORRECT — re-aggregated excluding `fixture*` sessions before naming the offender; read the
   emitting hook before asserting a metric's cause; re-ranked the bottleneck only after confirming
   (owner / telemetry) which branch is actually taken.
```

## Edge Cases

- **When NOT to apply:** an exploratory glance at a metric that you do NOT report as a verified finding; this rule governs only conclusions asserted as fact.
- Distinct from [search-scope-verification](./search-scope-verification.md) (see-also): that rule governs a search-tool mechanics bug producing a false "0 results = absent". Here the tooling works — the defect is treating an aggregate/theoretical proxy as the verified fact. Both can fire on one audit; apply each to its own claim.
- **Pure-policy rule** — this is a charter-class distillate promoted from three reproduced incidents; its evidence is those reproductions, so it carries no single cold RED/GREEN target case (a strong in-repo agent already verifies and self-contaminates the control — the gate-4 skip in [scoping-rule-value](./scoping-rule-value.md)).

## Review Checklist

- [ ] Any reported usage/telemetry/audit conclusion excluded fixture/test/synthetic data and was confirmed to survive on production-only events.
- [ ] A "why the metric reads X" claim was made only after reading the emitting mechanism (hook logic, metric definition, raw events), not from the value's shape.
- [ ] A branch-specific cost/bottleneck ranking confirmed which branch is actually taken (owner or telemetry) before ranking.
- [ ] A pre-built aggregator's headline was checked for what it includes (e.g. fixtures) before being quoted as the production picture.
