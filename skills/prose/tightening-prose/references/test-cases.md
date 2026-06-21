# Test Cases — tightening-prose

Persisted pressure scenarios this skill is validated against. The `validate` gate loads this file and runs each case WITH the skill in context, then inverts (would a cold pass comply WITHOUT it?). This is a **shaping / efficacy** skill, not a discipline gate — an in-vault subagent is an honest baseline (no operating-manual contamination to suppress).

RED baselines below were observed during the build (cold subagents, no skill).

## TC1 — cleanup efficacy: catch the long tail (shaping)

- **Setup:** A slop-laden paragraph: "Here's the thing… it's not just about blocking traffic — it's about protecting the system. It turns out the design really needs to be robust. … the token-bucket algorithm leverages a fairly elegant mechanism to navigate the tricky waters of fairness. The decision to use Redis emerges naturally… Let me walk you through it. The stakes are high." Task: tighten it.
- **Baseline (RED), observed:** Cold pass removed the obvious tells (throat-clearing, "Let me walk you through", "stakes are high") but **left the long tail**: the empty adverb "elegant(ly)", the false-agency "emerges naturally", and the binary-contrast opener "not X — it's Y".
- **With skill (GREEN):** The ordered pass + catalog catches the long tail — cuts "elegant", names the actor for "emerges naturally" ("We chose Redis"), and collapses the binary contrast to the positive claim.
- **Exercises:** the catalog closing the coverage gap cold taste leaves (steps 4/5/6).

## TC2 — register carve-out: no over-correction (efficacy / agnostic)

- **Setup:** Already-clean technical prose: "The read-modify-write must be atomic — two concurrent requests for the same key cannot both spend the last token. Refill is computed lazily. No background ticker, no sweep over dormant buckets." Task: tighten it.
- **Baseline (RED), expected:** A naive anti-slop pass that imports the narrative `stop-slop` bans **over-corrects** — flags the em-dash, the -ly adverbs ("atomically"/"lazily"), and the fragment as tells, and damages correct technical prose.
- **With skill (GREEN):** The "Register first" carve-out keeps the em-dash (parenthetical density), the precise adverbs ("atomic", "concurrent", "lazily"), and the deliberate negative-listing — output is unchanged or near-unchanged.
- **Exercises:** the technical-register carve-out; the "fights the medium" red flag.

## TC3 — no-op guard: not a prevention pass on fresh strong-model output (scope)

- **Setup:** A strong model is asked to draft an SDD artifact (design overview / spec summary) from scratch, even from a hype-laden input. Question: does running tightening-prose on that fresh output add value?
- **Baseline (RED), observed:** Cold strong-model generation is **already clean** — no slop emitted, sloppy input stripped on the way in (build probes 1a/1b/3). A prevention pass here changes nothing.
- **With skill (GREEN):** The skill's "When to use" + red flag stop the agent from running on fresh clean output and reporting a no-change result as a "pass" — it applies only to existing slop-laden text.
- **Exercises:** the no-op scope boundary (`scoping-skill-value`); the "no-change ≠ pass" red flag.
