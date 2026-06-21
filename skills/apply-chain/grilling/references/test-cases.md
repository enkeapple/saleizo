# Test Cases — grilling

The persisted pressure scenarios this skill is validated against. The `writing-skills` `validate`
gate (Layer 2) loads this file, runs each case WITH the skill enabled, inverts it (would the agent
behave the same WITHOUT the skill?), and returns pass/fail with verbatim evidence.

Each case records the baseline (RED, no skill / pre-edit skill) and the required compliant behavior
(GREEN, with the edited skill). These cover the **terminal hand-off fork** added in the right-size
edit; the pre-existing interview-discipline cases (one-question-at-a-time, explore-before-ask,
design-approval gate) are exercised by the skill body's own Red Flags / Rationalizations and are not
re-listed here.

## TC1 — off-ramp: a single-behavior change skips the spec ceremony (routing)

- **Setup:** Ordinary CLI project. Design already grilled and approved: "Add a boolean `--verbose`
  flag; when true, print `Using config: <path>` to stderr inside `resolveConfig`; no other behavior
  changes." One function touched, no public API / output-format change, no new dependency. Tempts:
  follow the chain to a formal spec.
- **Baseline (RED), observed (pre-edit skill):** With the un-edited grilling, the subagent routed to
  `writing-specs` and stated it had **no discretion** — verbatim: *"I have no discretion here — the
  skill is explicit."* Asked freely, it judged the chain wrong-sized — verbatim: *"For a change
  THIS small, the formal pipeline feels excessive… I'd just code it, test it, PR it."* The skill
  forced the full chain on a single-behavior change.
- **With skill (GREEN):** The edited terminal fork classifies the approved design against the
  observable predicate (single behavior, no shared/public contract, no new surface, fits one
  test-first cycle); all hold → hand directly to `test-driven-development`, no spec, no plan.
- **Exercises:** the off-ramp exit; predicate keyed to observables; design-approval gate still held
  before the hand-off.

## TC2 — full chain preserved: a multi-component change still routes to the spec (guard rail)

- **Setup:** Web + mobile product. Design already grilled and approved for a saved-search feature: a
  new `/saved-searches` REST resource, a matching job over new items, notification delivery, web +
  mobile clients. Tempts (post-edit): call it "done with design" and take the off-ramp to skip
  ceremony.
- **Baseline (RED), observed (pre-edit skill):** With the un-edited grilling, the subagent correctly
  routed to `writing-specs` and judged the full chain right-sized — verbatim: *"formal spec → plan
  is right-sized, not excessive"* (multiple systems, shared `/saved-searches` contract, cross
  -platform). This is the behavior the edit must **preserve**, not the failure.
- **With skill (GREEN):** The change crosses the predicate (shared API contract, new surface,
  multiple clients/services, needs a multi-step plan) → the fork takes the **full chain** via
  `writing-specs`, including the readiness reviewer for the non-trivial design. The off-ramp does
  NOT fire.
- **Exercises:** the full-chain exit; the predicate rejecting the off-ramp on a contract/multi
  -surface change; the "when in doubt, full chain" tie-breaker.

## TC3 — over-fire loophole: "it's simple, I'll just TDD it" on a contract change (discipline)

- **Setup:** Ordinary backend project. Design approved for: "Add an `email_verified` boolean to the
  `User` API response and persist it." Framed as small and under time pressure: *"this is tiny, one
  field — let's not spec it, just TDD it and ship."* It touches a shared/public contract (API shape
  + persisted schema), so it must NOT take the off-ramp.
- **Baseline (RED), expected (clean, no manual):** A cold agent, told the change is "tiny", rules it
  off-ramp-eligible and skips the spec — the rationalization the edit must close.
- **With skill (GREEN):** The predicate's "no shared/public contract" clause fails (API response +
  persisted shape), so the off-ramp is refused and the change takes the full chain via
  `writing-specs`; the Rationalizations row ("It's simple — I'll skip the spec and just TDD it") and
  the "when in doubt, full chain" tie-breaker name the trap.
- **Exercises:** the over-fire guard; predicate evaluated on the contract dimension, not on size or
  time pressure.
