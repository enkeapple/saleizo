# Testing With Subagents

How a skill earns "done": you watch a fresh agent **fail** the scenario without the skill (**RED**),
then **comply** with it (**GREEN**). If you didn't watch it fail first, you don't know the skill
teaches anything. This is the same RED→GREEN the test-first cycle runs, with the agent's *behaviour*
as the unit under test.

## A pressure scenario

A scenario that actually exerts pressure has:

- **Concrete A/B/C choices** that force an explicit decision — no hypothetical deflection ("must choose and act" framing).
- **3+ combined pressures** stacked (below) — one pressure is easy to resist; a stack reproduces real-world resistance.
- **Real constraints**: specific deadlines, file paths, prior work — not "imagine you're busy".

### Pressure types to stack

| Type | Mechanism |
| --- | --- |
| Time | deadline / deploy window closing |
| Sunk cost | hours already invested, fear of "waste" |
| Authority | a senior or manager overriding |
| Economic | job / promotion / survival framed as at stake |
| Exhaustion | end-of-day fatigue, plans waiting |
| Social | fear of looking dogmatic or inflexible |
| Pragmatic | "be pragmatic, not dogmatic" rationalization |

## The cycle

- **RED** — run the scenario WITHOUT the skill. Record the agent's rationalizations **verbatim** — those exact excuses become the skill's rationalization table. Watch the failure happen; do not infer it.
- **GREEN** — write the minimal skill addressing those specific failures, then re-run the same scenario WITH the skill. The agent should now comply.
- **REFACTOR** — each new excuse the agent invents under the skill gets: an explicit negation in the rules, a rationalization-table row, a red-flag symptom, and (if it mis-fires) a sharper description. Re-run until compliance holds.

## The control is mandatory

**Always run a no-guidance control.** If the agent complies on the bare scenario WITHOUT the skill,
there is nothing to fix — the skill would be a no-op. Stop and re-aim at a failure that actually
reproduces (invert the test: *would the agent comply WITHOUT the skill?* — if yes, the scenario
exerts no pressure).

### Caveat — a contaminated discipline baseline

A subagent dispatched inside a repo that injects an operating manual (a charter, an Iron Law,
read-before-assert) inherits that discipline, so a discipline-RED run may "comply" by obeying the
*inherited manual*, not your skill — a false no-failure. Observed: a baseline validator, told it was
an ordinary project, still cited "this repo's Suspicion Protocol #4". To measure a true discipline
baseline, run WITHOUT that injection (a controlled system prompt, or a real consumer repo). Output-
*shape* failures stay measurable in-repo regardless.

### Export-bound vs in-repo-discipline — a green in-repo RED is not a cut

Before reading a green in-repo RED as "no-op, cut it", classify the skill by **whose** discipline it
exists to enforce:

- **in-repo-discipline** — its value is enforcing discipline on THIS strong, tool-equipped agent. A
  green in-repo RED genuinely means no-op: the agent you are protecting already complies, so there is
  nothing to teach. Cut or re-aim.
- **export-bound** — its value is for weaker / non-agentic consumer harnesses in other repos. A
  tool-equipped agent recons, verifies, and self-checks by default at EVERY tier (Haiku included), so a
  green in-repo RED across tiers says nothing about the export target — it only shows that *this*
  agent does not need the skill. That is **not** a cut signal.

For an export-bound skill with a green in-repo RED, the **required default** is option 1 — option 2
is a narrow, logged fallback, NOT an equal alternative:

1. **RED against a representative export floor (do this).** A weaker / non-agentic harness: a
   controlled system prompt stripped of agentic recon, or a real consumer repo at the target's tier.
   Reproduce the failure where the skill's real consumers live. This is the only path that keeps the
   claim falsifiable, so reach for it first.
2. **Ship on a logged exception (only when no floor is reachable).** Record, in the skill's Edge
   Cases, all three: (a) the in-repo RED was a no-op, (b) *why* no representative floor could be run
   — after actually attempting one (a controlled stripped-down system prompt is cheap; assert
   unreachability only once it genuinely fails, never as a first move), and (c) the **concrete
   weaker-consumer behaviour** the skill is presumed to fix. This is an
   explicit, auditable exception — never a blanket "valuable for weaker consumers" that would license
   shipping any no-op. **If you cannot name the concrete behaviour in (c), you have no evidence — cut
   the skill.**

Record which basis you used. A green in-repo RED is "no-op here / valuable there" — never a silent
cut, and never a silent ship.

## Reps and reading

- **5+ reps per variant.** A single sample lies; variance across reps is itself a signal — five different shapes means the wording isn't binding yet.
- **Read every flagged match manually.** Template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
- **Micro-test wording before full scenarios.** Full pressure runs are the final gate but slow; verify the wording first with one fresh sample per call (system prompt = the realistic context; user message = a task that tempts the failure), always against the no-guidance control.

## Trigger precision (test the description, not only the body)

The `description` is the skill's router — it decides *when* the skill fires. A body that works is
worthless if the skill never triggers, and costly if it fires on the wrong prompts and crowds every
turn's context. So test the description like behaviour, especially after any edit that touches it:

- **Positive set** — 5+ realistic prompts a user would type when they DO want this skill (varied:
  formal and casual, some naming the artifact, some only implying it). Each must fire.
- **Negative / near-miss set** — 5+ prompts that share vocabulary but need something else (an adjacent
  skill, or a plain answer). Each must stay quiet.
- Run both and read each result. **Over-triggering** (a negative fires) is as much a defect as
  **under-triggering** (a positive misses): the first taxes context every turn, the second makes the
  skill dead weight. Adjust the description and re-run until both sets are clean — a keyword-stuffed
  description that also blows the frontmatter size check is the classic failure of "make it trigger more".

## Iterating across rounds

The `validate` gate's staged cases are a temporary file, deleted after each run (SKILL.md step 6) —
right for a one-shot check. When you are *iterating* on a skill across several rounds (draft → run →
improve → re-run), keep the cases and the RED/GREEN transcripts in a **sibling workspace dir** —
`<skill>-workspace/` alongside the skill, **never inside the skill tree** — so each round re-runs the
same cases instead of re-deriving them. That workspace is scratch: not shipped, not part of the
skill. Only the ban on persisting cases *inside* the skill (e.g. under `references/`) is absolute;
an external workspace is fine and speeds the loop.

## Meta-test

If the agent violates *despite* the skill, ask: "how could this skill have been written to make the
right choice crystal clear?" The answer reveals whether the gap is documentation clarity or a weak
underlying principle.
