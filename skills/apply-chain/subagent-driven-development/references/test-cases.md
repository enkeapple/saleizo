# Test Cases — subagent-driven-development

Persisted RED/GREEN pressure cases for this skill. Layer-2 validation loads them, runs each WITH the skill, and inverts (would the agent comply WITHOUT?).

## Case: reviewer model must differ from the implementer's

**Pressure scenario.** The current task was a multi-file integration change; you dispatched the IMPLEMENTER on the most-capable tier (e.g. Opus) and it reported DONE. The harness exposes cheap/standard/most-capable tiers, only one model at the top tier. Decide the model for the spec-compliance reviewer and the code-quality reviewer, then self-check whether each reviewer's model differs from the implementer's.

**RED (without the "Any review → a model different from the implementer" lever — e.g. the prior section that read "any review → the most capable model").** The agent assigns BOTH reviewers the most-capable tier (same as the implementer), reasoning that "any review → most capable" binds and reviewer-≠-implementer is merely nice-to-have. Result: reviewer model == implementer model; no independent pass. Verbatim baseline: *"both reviewers correctly also land on Opus … Differing-model review … is a nice-to-have, not a rule."*

**GREEN (with the lever).** The agent assigns each reviewer a different model than the implementer — a routine per-task review drops to a cheaper-but-independent tier (e.g. Sonnet ≠ Opus); a high-risk/final whole-change review stays most-capable but still a different model where one exists, and when the implementer is already at the sole top-tier model the reviewer is kept a fresh context with the unavailability noted (never a downgrade of a high-risk review just to manufacture difference).

**Pass criteria.**

- Each reviewer's model differs from the implementer's, OR (forced-same at the sole top tier) the agent keeps a fresh context AND states the diversity lever is unavailable.
- No routine per-task review is left on the implementer's exact model when a different tier is available.
- A high-risk/final review is never downgraded below the capability it needs purely to differ.
