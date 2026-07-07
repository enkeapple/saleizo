# Running a Council — dispatch playbook

Read-for-guidance depth behind [SKILL.md](../SKILL.md). The core recipe (frame → dispatch five at once → chairman after → present) lives in SKILL.md and is complete on its own; this file explains *why* the panel is these five and *how* to run the dispatch well. The exact injectable text is the single source in [council-prompts.md](../agents/council-prompts.md) — this file does not restate it.

## Why these five, and what each must refuse

The panel is fixed at five because a free-forming agent, asked for "different perspectives", reliably collapses the set: it invents a skeptic and a cost lens, then stops — omitting the growth and the naive-outsider views, and letting the count drift run to run. Each role earns its seat by refusing what the others cover:

- **The Contrarian** owns the downside. Its failure mode is drifting into "it depends" or a balanced both-sides — that is not its job; it makes the strongest honest case *against*.
- **The First Principles Thinker** owns the framing. It must refuse to accept the stated problem as given — its value is asking whether a cheaper, more direct path reaches the real goal.
- **The Expansionist** owns the upside. Its failure mode is shrinking into caution (that is the Contrarian's seat) — it must reach for the 10x version and adjacent opportunity.
- **The Outsider** owns the naive question. It must refuse domain jargon and insider assumptions — the most insightful question is often the most basic one nobody asks anymore.
- **The Executor** owns the next move. It must refuse to re-litigate whether to act — it assumes a direction and names concrete, ordered steps.

## Dispatch well

- **One concurrent batch.** Issue all five dispatch calls in a single turn so they run in parallel — five sequential calls waste wall-clock and tempt you to let a later role read an earlier one's output.
- **Genuine isolation.** Each role subagent gets ONLY the shared brief plus its own role prompt. No role sees another's answer; that isolation is the whole point — it is what makes the divergence real rather than a single mind harmonizing five voices.
- **Role by label, not by agent type.** All five use the same general reasoning subagent type; distinguish them with a role-named label on each dispatch (e.g. "Council: Contrarian"). The role comes from the injected prompt.
- **Model diversity where available.** If the harness offers a choice of models, vary the model across the five roles — different models surface different blind spots, and diverse independent judges beat five copies of one. (This is the review-diversity lever, distinct from a controlled RED/GREEN pair where the model is held constant.)
- **Chairman after, and separate.** Dispatch the chairman only once all five have returned, as its own call carrying all five verdicts verbatim. Writing the synthesis inline in the orchestrator's context re-imports the convergence the council exists to avoid.
- **Run the chairman on the most-capable tier available, distinct from any single role's model.** The synthesis is the highest-judgment step — it produces the decisive verdict across genuine disagreement — so it is the final/high-stakes-review case: top capability *and* an independent model (illustrative: the roles on cheaper/varied tiers, the chairman on the strongest). This is the review-diversity lever, not a RED/GREEN constancy pair; do not pin it to a role's tier for "consistency."

## The failure this prevents (worked contrast)

**Anti-pattern — one context, five hats.** Asked to "convene a council", an agent left alone writes all five voices itself. They cross-reference ("pushing back on the pushback"), harmonize, and converge on one tidy verdict; the role set drifts (five one run, six the next) and the growth/outsider lenses vanish. The output looks like a council but is one argument in costume.

**Correct — five isolated dispatches.** Each role, in its own context, commits fully to its lens and cannot see the others, so the Contrarian and the Expansionist genuinely pull apart. The chairman is the *first* point where all five meet — so the tensions it names are real, not manufactured, and the verdict is a decision made across true disagreement rather than an average of one mind's five moods.
