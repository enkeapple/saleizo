---
name: bootstrapping-claude-md
description: >-
  Use when a project has no CLAUDE.md yet (or only a stub) and you need to set
  up the agent's entry point and operating manual for the repo. Triggers on:
  "set up CLAUDE.md", "initialize CLAUDE.md", "create the project's Claude
  config", "bootstrap the engineering system", "give Claude a persona/pipeline
  for this repo".
allowed-tools: Read, Grep, Glob, Write, Edit
---

# Bootstrapping CLAUDE.md

Set up the two-file CLAUDE.md system every other instruction hangs off:

- **`CLAUDE.md` (repo root)** — the entry point: what the project is, the real commands, where rules/skills live, and the one-paragraph "how to work here".
- **`.claude/CLAUDE.md`** — the operating manual: the engineer persona, the non-negotiables, the task pipeline, the verification checklist, and the session-handoff flow.

**Core principle: interview the human for the initial facts, then ground everything else in the actual repo — never invent.** A CLAUDE.md that guesses the stack, the commands, or the test setup makes the agent work *worse*. Ask what only the human knows; discover the rest by reading.

This mirrors `bootstrapping-glossary` (which builds `.claude/rules/`); the CLAUDE.md files point at those rules. For the intake interview style (one question at a time, with a recommended answer), borrow from `grilling`. For the session-handoff mechanics, wire to the `handoff` skill.

## When to use

- A repo with no `CLAUDE.md`, or a thin stub that doesn't define how the agent should work.
- Standing up the engineering system for a new project.

## When NOT to use

- The files exist and just need correcting → `auditing-claude-md`.
- A single convention or domain rule → `writing-rules` / `bootstrapping-glossary`.

## Step 1 — Intake interview (ask, don't invent)

Before writing, collect what only the human can tell you — one question at a time, with a recommended default. The full question set is in [references/intake-questions.md](./references/intake-questions.md). At minimum:

- **What the app is** — product, platforms, the domain in one or two sentences.
- **The managing engineer's position** — e.g. *Principal Mobile Dev*, *Staff Backend*, *Senior Frontend*. This sets the **Role/persona** the agent acts as and the bar it holds. Do not default to a generic "senior engineer" — use the position given.
- **Stack & real commands** — confirm against `package.json`/Makefile/CI; ask for anything not discoverable. Crucially, whether there IS a test pipeline — never assume one.
- **Where rules/skills/commands live** and any **session-handoff** preference.
- **Behavioral baseline (opt-in)** — whether the team adopts a stack-agnostic conduct set (the recommended default four: Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution), a variant of it, or none. Recommend the default; if declined, emit no baseline section. The canonical default set is in [references/behavioral-baseline.md](./references/behavioral-baseline.md).

**Resolve placeholder keys (hybrid).** The templates use the keys in [placeholder-keys.md](../shared/placeholder-keys.md); resolve each by that file's HYBRID rule — auto only when exactly one disk fact maps with no judgment, else the key stays a `<key>` and becomes an intake question. Never infer a command silently.

Discover the rest (stack pins, folder layout, existing rules) by reading the repo.

## Step 2 — Write the two files

Open each template and follow the fixed section order, filled example, and per-section notes it already carries — the structure (and the per-section guidance: real commands not validator one-liners, Role = the intake position, "no test pipeline → say so") lives there, don't re-derive it here:

- **Root `CLAUDE.md`** ([assets/root-claude-md-template.md](./assets/root-claude-md-template.md)) — the scannable entry point.
- **`.claude/CLAUDE.md`** ([assets/operating-manual-template.md](./assets/operating-manual-template.md)) — the operating manual.

What a template can't know is your repo. These rules override its defaults:

- **Transclude every `[SECTION: file]` block 100% verbatim from `assets/sections/<file>.md`.** The invariant process blocks (rule-precedence, Non-negotiables, Communication, Operating modes, Behavioral baseline, Search-before-ask, Git boundary, Status block, Skill discipline, Lessons promotion, root Hard rules) live one-per-file under `assets/sections/`, NOT inline. Copy the file unchanged; fill only an explicit `<slot>` inside it. **Never retype a section from memory** — that is how siblings drift; byte-identity is structural (one source, copied).
- **After generating more than one repo, verify byte-identity.** `diff` the SECTION regions between two sibling files; the diff must be empty except inside the explicit `<slots>`. A non-empty diff on a SECTION region means a block was retyped instead of transcluded — re-copy it from the canonical file.
- **Honor the [FILL] / [COND] tag on the rest.** **[FILL]** blocks keep their frame and take repo-verified slots. **[COND]** blocks are included verbatim only when the repo has the named feature, else dropped whole.
- **Single-source every `src/**` path through the operating manual's `## Key files` table.** Author each anchor once there (label · path · role); EXPLORE, CODE, the Completeness Checklist, and Search-before-ask refer to it by **label**, never by re-printing the path. A raw anchor path outside `## Key files` is path-noise — move it in and reference the label.
- **The persona is one value in two files.** The `<POSITION>` in the operating manual's `## Role` and the persona string in the root's "Engineering system" summary must be identical, verbatim — same intake fact.
- **Ground every command, path, skill, and hook in the repo this session** — a cited command/hook/path that doesn't exist is a hallucination.
- **A sibling app's CLAUDE.md is never a source — the template + THIS repo are.** In a multi-app vault it is tempting to copy a neighbouring project's files "for consistency". Do not: every symbol, checklist row, `Key files` path, and lesson trigger is grounded in THIS repo, and any structure not in the template (e.g. a `Typical triggers:` line) is not imported from a neighbour. Consistency comes from the shared template, not from copying a sibling — copying is how a passenger app ends up citing a driver app's symbols.
- **Hook-tied clauses are conditional** — keep skill-gate / bypass / token-guard / lessons-nudge references ONLY for hooks the repo actually has.
- **Skill-owned workflows route through the `Skill` tool, not a direct file edit.** When the manual documents a workflow a skill owns — lesson capture, handoff/plan persistence, spec authoring — instruct invoking that skill, never an `Edit`/`Write` to the artifact the skill manages (`lessons-learned.md`, a `/tmp` plan): a direct edit bypasses the skill's discipline, routing, and metrics. Keep it conditional — route through the skill only where the repo HAS one; else document the direct fallback. (The templates already do this for `handoff`; match that pattern for lessons.)

**Behavioral baseline (only when adopted at intake)** — seed one named section in the operating manual from [references/behavioral-baseline.md](./references/behavioral-baseline.md), each adopted principle with its one-line meaning (the section `auditing-claude-md` later verifies). Declined → emit nothing; never inject conduct rules a repo did not ask for.

## Step 3 — Session-jumping / handoff flow (required)

Document how work survives the context limit, because long tasks will hit it. The operating manual must state: when the turn ends incomplete OR context nears the limit, persist a handoff doc (goal, done, remaining, exact next step, files touched, open decisions, working-tree state), end the turn cleanly, and resume from that doc next session. Wire the mechanics to the `handoff` skill rather than re-describing them. The status block's `Next:` line points at the handoff doc.

## Red Flags — STOP

- Writing either file before the intake interview — guessing the app, stack, or commands.
- A generic persona ("senior engineer") instead of the position the human gave.
- Assuming a test pipeline / TDD when the repo has none — verify, don't assume.
- One mega-file instead of the entry-point + operating-manual split.
- A non-negotiable or pointer that tells the agent to `append`/`Edit` a skill-owned artifact (e.g. the lessons log) directly when the repo has the skill that owns it — that bypasses the skill; route through the `Skill` tool instead.
- A pipeline with no Completeness Checklist, or verification rows with invented commands.
- A flat single-line status block (fields joined by `·`/`,`) instead of the structured, verdict-first markdown form in the template — or reaching for emoji to make it scannable, which breaks the manual's own "no emoji" rule.
- Rewording a **[STRICT]** block (Non-negotiables, Communication, Operating modes, Search-before-ask, Git boundary, Status block, Behavioral baseline) instead of copying it verbatim — that is the run-to-run drift the tags kill.
- The same `src/**` anchor path printed in more than one section instead of living once in `## Key files` and referenced by label — path-noise.
- The root's "Engineering system" persona not matching the operating manual's `## Role` `<POSITION>` verbatim.
- A symbol/checklist row/lesson trigger/non-template structure copied from a sibling app's CLAUDE.md — grounding is THIS repo (a real vault had a passenger app carrying a driver app's `syncLocations`/`PrintService`); a shared title is the same defect.
- FILL narrative in manifesto voice — a three-beat refrain ("Name the domain, walk the phases…"), a slogan ("ship 10% done"), an imperative tic ("read them, do not infer"), mid-sentence emphasis-bold, or the whole app in one run-on — instead of plain README prose. De-slop via `tightening-prose`.
- A `[SECTION]` block retyped instead of transcluded from `assets/sections/<file>.md`, so its text is not byte-identical to a sibling repo's — copy the file, don't reproduce it from memory.
- Any stack/command/path claim not verified by a read this session.
- Emitting a behavioral-baseline section the team did not adopt (injecting unrequested conduct rules) — or, having adopted one, naming a principle without its one-line meaning so the audit cannot verify it.
