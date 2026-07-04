---
name: decision-council
description: >-
  Convene a council of five fixed, independent role-lenses on a decision, plan,
  or idea — each dispatched as its own subagent so the perspectives are genuinely
  independent, not one voice wearing five hats — then a separate chairman
  subagent synthesizes a verdict that surfaces the tensions instead of averaging
  them. Use to pressure-test a choice from many angles and get a decisive call.
  Triggers on: "convene a council", "council review", "consilium", "get me a
  panel", "five perspectives", "stress-test this decision from multiple angles",
  "multiple viewpoints and a verdict", "консилиум", "созови совет", "разбери с
  разных сторон и вынеси вердикт", "совет из ролей".
---

# Decision Council

Pressure-test a decision, plan, or idea through **five fixed role-lenses**, each run as its own subagent — then a separate **chairman** subagent weighs them into a verdict. The value is what one mind cannot fake: five *independent* contexts that genuinely diverge, and a chairman that names the tensions instead of averaging them. Left alone, an agent role-plays all five voices in one context and converges on one tidy answer — this skill forbids that.

## The five roles (fixed — always all five, never substitute)

| Role | Lens |
| --- | --- |
| **The Contrarian** | pokes holes — the strongest honest case against the weakest assumptions and likely failure modes |
| **The First Principles Thinker** | strips surface detail to the root problem; questions whether the stated problem is the real one |
| **The Expansionist** | the dreamer — how this scales and grows, the ambitious upside |
| **The Outsider** | an expert from an unrelated field with zero domain context; asks the naive questions insiders skip |
| **The Executor** | the pragmatic operator — the concrete next steps, in order |

Left alone the model omits the Expansionist and the Outsider and lets the count drift; this fixed set closes that. What each role must *refuse* to do — and why it earns its seat — is in [running-a-council.md](references/running-a-council.md); the exact prompt each gets is in [council-prompts.md](assets/council-prompts.md).

## Process

1. **Frame the problem once.** Write a tight brief: the decision/idea, the real constraints (time, money, people, context), and what a good outcome looks like. The *same* brief goes to every role — no role gets context another lacks.
2. **Dispatch all five role subagents at once.** Issue the five calls in a *single batch* (one turn) so they run concurrently — one per role, each in its own context, each given ONLY the brief plus its role prompt from [council-prompts.md](assets/council-prompts.md). Use one general reasoning subagent type for all five (illustrative: `general-purpose`); tell them apart by a role-named label per dispatch (e.g. "Council: Contrarian"). Vary the model across roles where the harness allows. **Wait for all five to return** before step 3. (Playbook — batching, isolation, model diversity: [running-a-council.md](references/running-a-council.md).)
3. **Only then, dispatch the chairman** — a sixth, separate dispatch, after all five have returned — with the brief plus all five verdicts verbatim, using the chairman prompt. It does NOT re-poll the roles or add a voice; it synthesizes what came back.
4. **Present** the five role cards, then the chairman's verdict.

## Required output shape

Each **role subagent** returns, in order:

- **Position** — its one-sentence stance
- **Reasoning** — 2–4 points, through its lens only
- **Sharpest question** — the single question it forces the user to answer

The **chairman** returns, in order:

- **Where they agree** — genuine consensus only, not manufactured
- **Live tensions** — the real disagreements, named as A-vs-B, NOT dissolved
- **Verdict** — one decisive recommendation (never "it depends")
- **Next steps** — concrete and ordered

## Red flags — STOP

- Role-playing the five voices in one context instead of dispatching five subagents — the independence is fake and they will converge.
- Dropping, merging, or renaming a role, or adding a sixth — the five are fixed.
- Omitting the Expansionist or the Outsider — the two the model naturally skips.
- Role outputs that cross-reference each other ("pushing back on the pushback") — a tell they shared one context; re-dispatch independently.
- A chairman that averages into mush or hedges ("it depends") instead of naming tensions and deciding.
- The chairman written inline by the orchestrator instead of dispatched as its own synthesis pass, or fired before all five roles have returned.

## References

- [running-a-council.md](references/running-a-council.md) — dispatch playbook: why these five, what each must refuse, batching, isolation, model diversity, and the shared-context anti-pattern.
- [council-prompts.md](assets/council-prompts.md) — the five role prompts and the chairman prompt, injected verbatim into each dispatched subagent.
