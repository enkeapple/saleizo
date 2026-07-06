---
name: writing-skills
description: Use to create, edit, rename, split, or validate a skill — walks the test-first RED→GREEN→REFACTOR loop so the change is reproducible and reviewed before shipping. Covers a skill's description and its references/assets too. Triggers: "write/create/author/edit/change/validate a skill", "new skill", "improve a skill's description", "split a skill", "написать/создать/отредактировать/улучшить скилл", "новый скилл", "разбить скилл".
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, Skill
---

# Writing Skills

A skill exists to wrangle determinism out of a stochastic system, in service of **Predictability**
(defined in [`vocabulary.md`](./references/vocabulary.md)). This skill builds and changes skills
**test-first**: you watch an agent fail without the skill, then comply with it. **Bold terms** are
defined there too.

## The Iron Law

**No skill, and no skill edit, without a failing test first.** The "test" is a subagent pressure
run, not a unit test (see [`testing.md`](./references/testing.md)): run
the scenario WITHOUT the skill and watch it fail (**RED**) before you write. Wrote it first? Delete
it. Start over. No exception for "simple additions", "just a section", or "it's only docs" —
**editing a skill doc IS editing code.**

## Step 0 — classify the mode

- **create** — the skill does not exist on disk yet → write it test-first.
- **edit** — the skill exists; you are changing it → the Iron Law applies to the change.
- **split / merge / rename** — you are changing the *set* of skills or a skill's identity → the shape-change rules ([`shape-changes.md`](./references/shape-changes.md)) apply on top of edit.
- **validate** — you only want to check an existing skill → go straight to the gate.

## create

1. **RED.** Run the baseline pressure scenario(s) WITHOUT the skill; record the agent's
   rationalizations verbatim. For a *discipline* skill, suppress any injected operating manual
   (else the baseline is contaminated). No failure reproduces → classify in-repo-discipline vs
   export-bound before cutting; a green in-repo RED is a cut only for the former, never for an
   export-bound skill (full decision tree: [`testing.md`](./references/testing.md)).
2. **Match the form to the failure** (table below) before writing.
3. **GREEN (author check).** Write the minimal skill addressing those exact failures — in the form
   the failure calls for. Re-run the scenarios WITH the skill; confirm compliance. This is YOUR
   check, not the gate — it does **not** satisfy Layer 2.
4. **Offer the optional levers.** Decide whether the skill wants `allowed-tools` or `model`
   ([`frontmatter.md`](./references/frontmatter.md)) — offer them with their
   trade-offs; do not bake them in by reflex.
5. **REFACTOR.** Close each new loophole the agent invents (rationalization-table row + red flag).
6. **Stage the test cases for the gate — do NOT persist them in the skill.** Write the RED
   baselines (verbatim) and GREEN expectations to a temporary working file OUTSIDE the skill tree
   and hand its path to Layer 2; the gate consumes and deletes it. Cases are ephemeral scaffolding,
   never skill content under `references/`.
7. **validate** (the gate).

## edit

The Iron Law holds for edits. Establish a diff-scoped **RED** on the behaviour you are changing
(a scenario the current skill fails or under-specifies), make the minimal change, re-run for
**GREEN**, then run the gate.

## split / merge / rename (a shape change — re-RED **and** sync routing)

A shape change is a **branch**: it adds two obligations on top of the Iron Law — re-RED each
resulting contract, and sync the routing registry and every name/path reference (registry key/`name`,
directory, `name:` frontmatter, alias bodies, path links) in the same change, then re-confirm each
skill still fires and no cross-link dangles. Full procedure:
[`shape-changes.md`](./references/shape-changes.md).

## validate (the gate — self-contained, runs after create/edit and standalone)

Two layers, both defined inside this skill — no dependency on any repo hook:

1. **Layer 1 — static pre-flight.** Run the eight checks with the bundled runner:
   `bash scripts/validate.sh <skill-dir> [skills-routing.json] [role]`. Their authoritative
   definitions (and the reimplementation note for a runtime without `bash`/`awk`/`grep`) live in
   [`validation-checklist.md`](./references/validation-checklist.md). Fail fast here before spending
   a subagent.
2. **Layer 2 — dynamic run.** Dispatch the validation subagent
   ([`agents/validator.md`](./agents/validator.md)) to RUN the staged test cases (from step 6, or
   synthesized for a foreign skill that staged none) and return a verdict — an **independent**
   dispatch, a fresh subagent, NOT your own GREEN run from step 3. That prompt owns the procedure:
   invert each case (would it comply WITHOUT?), verbatim evidence, delete the temp file after. A
   static "looks good" is never a pass.

Never declare a skill done on Layer 1 alone, and never ship on a Layer-2 FAIL.

## Match the Form to the Failure

| Baseline failure | Right form | Wrong form |
| --- | --- | --- |
| Knows the rule, skips it under pressure | prohibition + rationalization table + red flags | soft "prefer…/consider…" |
| Complies, but output is the wrong shape | positive recipe: state what the output IS, in order | prohibition list |
| Omits a required element it already produces | structural REQUIRED slot in the template | prose reminder |
| Behaviour should depend on a condition | conditional keyed to an observable predicate | unconditional rule + exemptions |

No nuance clauses ("don't X unless…") — they reopen the negotiation; express a real exception as
its own conditional.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "It's just a doc edit, no test needed." | Editing a skill doc IS editing code. RED first. |
| "Too simple to test." | Simple skills mislead silently. The baseline run is cheap. |
| "It reads fine — it's valid." | Reading ≠ running. Layer 2 runs it; a static read is not a verdict. |
| "The baseline complied, so the skill works." | If it complied WITHOUT the skill, the skill proves nothing — re-aim at a real failure. |
| "I'll keep the draft as reference while I test." | Delete means delete. A kept draft is a write-first skill. |
| "My GREEN run passed, so Layer 2 is done." | GREEN is the author's check; Layer 2 is an independent subagent that inverts each case. Separate dispatch, different question. |
| "Persisting the cases is harmless — I'll just keep the `test-cases.md`." | Cases are ephemeral gate scaffolding, not skill content; a persisted file ships as skill clutter. Stage in a temp file, delete after the gate. |
| "It's export-bound — clean baseline, ship it." | "Valuable for weaker consumers" ships any no-op. RED a representative floor, or log an exception naming the concrete behaviour it fixes — never a silent ship (`testing.md`). |
| "Renamed the folder, it still works." | A rename is a routing change: registry key/`name`, frontmatter, alias prose, path links — same edit — then re-confirm it fires. |

## Red Flags — STOP

- Skill (or edit) written before a RED was observed.
- Declaring done on a static read, with no Layer-2 subagent run.
- Declaring validated on your own GREEN run, with no independent Layer-2 dispatch — the author's GREEN is not the gate.
- Persisting a `test-cases.md` inside the skill (e.g. under `references/`) — cases are ephemeral gate scaffolding, not skill content; stage them in a temp file and delete after the gate.
- Reaching the gate with no staged cases though you observed RED/GREEN this run, forcing the validator to synthesize and re-derive with author bias.
- A baseline that "complies" inside a repo whose manual it inherited (contaminated RED).
- A nuance/exemption clause smuggled into a recipe.
- "Export-bound" invoked to ship a baseline-complied skill with no RED against a floor and no logged, behaviour-naming exception.
- A split / rename that touched folders or bodies but not the routing registry and every name reference (key/`name`, frontmatter, alias prose, path links).
- `name` ≠ dir, or a routing entry for a `disable-model-invocation` skill.

## Reference files

Bundled material sits in sibling dirs by **role** — the copy/fill/inject test lives in [`vocabulary.md`](./references/vocabulary.md) under *External file*.

The `agents/` directory holds subagent prompts. Read one when you need to spawn that subagent:

- [`agents/validator.md`](./agents/validator.md) — the Layer-2 validation subagent: run a skill's test cases, invert each, return a verdict.

The `references/` directory holds material you read for guidance:

- [`vocabulary.md`](./references/vocabulary.md) — the leading words every **bold** term maps to.
- [`testing.md`](./references/testing.md) — subagent pressure scenarios, the mandatory control, reps, trigger-precision testing.
- [`shape-changes.md`](./references/shape-changes.md) — split / merge / rename: re-RED each contract, sync routing + name references, sweep orphaned cross-links.
- [`frontmatter.md`](./references/frontmatter.md) — the authoritative frontmatter field set incl. `allowed-tools`/`model`.
- [`validation-checklist.md`](./references/validation-checklist.md) — the Layer-1 static checks (the authoritative definitions).

The `scripts/` directory holds material the skill executes:

- [`scripts/validate.sh`](./scripts/validate.sh) — the runnable Layer-1 runner: all eight checks in one pass (illustrative `bash`/`awk`/`grep`).
