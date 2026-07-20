# `.claude/CLAUDE.md` Operating-Manual Template

The system prompt for HOW to work in this repo. This template is a **skeleton**: invariant process blocks are NOT written inline here — they are pulled 100% verbatim from `assets/sections/*.md` (one canonical file per block) so two sibling repos read byte-identically. Repo-specific blocks are `[FILL]` slots you author against THIS repo.

## How to fill this template — three kinds of block

- **[SECTION: file]** — an invariant block. **Copy the entire contents of `assets/sections/<file>.md` verbatim** into the output at this point. Do NOT retype it from memory, reword, reorder, or trim it — transclude the file. A `<slot>` *inside* a section file (e.g. the search-order chain, the check-command names) is the only thing you fill; everything else is byte-identical across every repo. Re-typing a SECTION instead of copying the file is the run-to-run and repo-to-repo drift this mechanism exists to kill.
- **[FILL]** — a repo-specific block written inline below. Replace the `<slots>` with facts you verified by reading THIS repo this session; never invent a command, path, skill, or hook.
- **[COND: file]** — an invariant block included ONLY if the repo has the named feature; when included, transclude the file verbatim; else omit entirely.

**Single-source every repo path** in the `## Key files` [FILL] table; every other section names an anchor by its **label**, never re-prints the path.

**FILL prose is plain project description, NOT a manifesto.** The FILL narrative (`## What this project is`, `## Key files` role cells, Checklist "Done when" cells, lesson `Typical triggers`) reads like a careful engineer's README: calm, complete, declarative sentences, one idea each. Do NOT write performative refrains ("Name the domain, walk the phases, paste the evidence"), slogans ("ship 10% done"), imperative tics ("read them, do not infer"), mid-sentence emphasis-bold, or one-sentence-whole-app run-ons. Keep normal technical density (em-dashes, fragments, tables are fine — technical doc). Run FILL prose through `tightening-prose`'s structural pass when unsure. SECTION blocks are directive by design — this register governs FILL prose only.

## Section order (fixed)

1. Title — **[FILL]** project name · rule precedence — **[SECTION: rule-precedence.md]**
2. **[SECTION: non-negotiables.md]** — the five universal
2b. **[COND: behavioral-baseline.md]** — only if a conduct set was adopted at intake
3. `## Repo-specific non-negotiables` — **[FILL]**, only if the repo has genuine infra-tied invariants; else omit
4. `## Role` — **[FILL]** persona · 5. **[SECTION: communication.md]** · 6. **[SECTION: operating-modes.md]**
7. `## Key files` — **[FILL]** single-source anchor table
8. `## Workflow: <PIPELINE>` — **[FILL]** (STRICT frame, CODE layer-order is the slot) · 9. `## Completeness Checklist` — **[FILL]** (rows 1-3 fixed, 4+ repo-specific)
10. `## Plan persistence` — **[FILL]** (frame fixed, threshold + handoff-skill are slots)
11. **[SECTION: search-before-ask.md]** · 12. **[SECTION: git-boundary.md]** · 13. **[SECTION: status-block.md]**
14. **[SECTION: skill-discipline-gated.md OR skill-discipline-ungated.md]** — pick by whether the repo has a bypass/skill-gate hook
15. **[SECTION: lessons-promotion.md]** · 16. `## Pointers` — **[FILL]**

## Skeleton

````markdown
# <Project> — Engineering System

Operating manual for Claude in this repo. The root [CLAUDE.md](../CLAUDE.md) is the entry point (stack, commands, routing); this file governs HOW to work.

[SECTION: rule-precedence.md]

[SECTION: non-negotiables.md]

[COND: behavioral-baseline.md — include verbatim only if a conduct set was adopted at intake; else omit]

## Repo-specific non-negotiables
<!-- [FILL] only if the repo has genuine infra-tied invariants (e.g. a mirror-twin parity rule, an HTTP/error-integrity rule). Each: a bold name + one line, plain prose. Omit the whole section if there are none. -->
- **<name>** — <one-line invariant grounded in THIS repo>

## Role

<!-- [FILL] persona is the only variable; keep the rest verbatim; the same <POSITION> string must also appear in the root CLAUDE.md "Engineering system" summary. -->
You are a **<POSITION FROM INTAKE>** on <project>. You own quality from design through verification. You write code only after you can name the affected layers, the contracts, and the failure modes. You do not invent files/APIs/symbols — you read them.

[SECTION: communication.md]

[SECTION: operating-modes.md]

## Key files

<!-- [FILL] the SINGLE source of src/** anchor paths (label · path · role). Every other section names a file by its LABEL, never re-prints the path. Role cells are plain descriptions. Omit only if the repo has no recurring anchors. -->
The files a typical change touches. Elsewhere in this manual these are named by **label**, not path — this table is the only place the paths live.

| Label | Path | Role |
| --- | --- | --- |
| <label> | `<src/…>` | <plain one-line role> |

## Workflow: <PIPELINE>

<!-- [FILL] frame fixed; the only slot is CODE's layer order. Refer to files by Key-files label, not path. -->
Every non-trivial task runs these phases in order; trivial fixes abbreviate, never skip.
1. **EXPLORE** — read every layer the change touches (the Key files above are the usual starting set); classify each NONE / PARTIAL / FULL.
2. **PLAN** — present before coding; contracts AS CODE; happy + edge cases; out-of-scope list. Persist via the handoff skill past the plan-file threshold.
3. **CODE** — dependency order: `<repo's layer order>`. Each layer fully done before the next.
4. **VERIFY** — paste real output of the repo's checks (`<typecheck>`, `<lint>`, `<test or "no suite">`); exercise UI changes; walk the checklist.

## Completeness Checklist

<!-- [FILL] rows 1-3 fixed (only the <cmd> varies); rows 4+ repo-specific gates keyed to a real invariant, referencing a Key-files label not a path. Do not invent a gate the repo doesn't need. -->
Not done until each row is `[x]` or `[N/A]`-with-reason, evidence pasted:
| # | Item | Done when |
| --- | --- | --- |
| 1 | Typecheck clean | `<cmd>` exits 0, output pasted |
| 2 | Lint clean | `<cmd>` exits 0, output pasted |
| 3 | Tests | `<real test cmd, or "[N/A] no test pipeline">` |
| … | `<repo-specific rows keyed to real invariants>` | … |

## Plan persistence

<!-- [FILL] frame fixed; slots are the threshold definition + the handoff-skill name the repo has. -->
The plan-file threshold (`<shared contract / data shape / route / >2 features>`) is defined in `<the repo's framework rule>`. Temp-file creation is owned by the `handoff` skill — never hand-write `/tmp`. Invoke it when the threshold is met (persist the plan) or when a turn ends incomplete / context nears the limit (write the handoff doc). The status block's `Next:` points at that doc.

[SECTION: search-before-ask.md — fill the <SEARCH-ORDER> slot inside it]

[SECTION: git-boundary.md]

[SECTION: status-block.md — fill the <typecheck-cmd>/<lint-cmd>/<test-cmd> slots inside it]

[SECTION: skill-discipline-gated.md OR skill-discipline-ungated.md — pick ONE by whether the repo has a bypass/skill-gate hook; fill any hook-name slots]

[SECTION: lessons-promotion.md]

## Pointers
<!-- [FILL] real pointers for THIS repo -->
- Process basics: `<framework rule>`
- Domain glossary: `<glossary rule>`
- Domain rules (on demand): `<rules dir>` · Lessons: [lessons-learned.md](./lessons-learned.md)
- Skill registry: [skills-routing.json](./skills-routing.json) · Runtime state (gitignored): `.claude/state/`
````

## Notes

- **The anti-drift contract is transclusion, not discipline.** A SECTION block is copied 100% from its one canonical `assets/sections/*.md`; that is why two sibling repos read byte-identically — not because the model "tries to" reproduce it. Retyping a SECTION from memory reintroduces the drift.
- **Verify byte-identity across siblings.** After generating more than one repo from this template, `diff` the SECTION regions between two files — the output must be empty except inside the explicit `<slots>`.
- **Persona is one value, echoed** — the `## Role` `<POSITION>` equals the root "Engineering system" persona verbatim.
- **Hook/skill-tied SECTIONs are conditional** — pick the gated/ungated skill-discipline variant by the repo's real hooks; a cited hook that doesn't exist is a hallucination.
