# Root `CLAUDE.md` Template

The entry point. Mirror this section order exactly — it is the structure proven in real repos. Scannable, link-heavy: the root routes, the operating manual governs. Every command, path, and skill name is the real one, verified by reading the repo.

## How to fill this template — STRICT vs FILL

Same tags as the operating-manual template (read that one's "How to fill" note for the full rule):

- **[SECTION: file]** — an invariant block: **copy the entire contents of `assets/sections/<file>.md` verbatim** (transclude the file, do not retype). The root uses one: the `**Hard rules:**` block from `assets/sections/hard-rules.md`, byte-identical across every repo.
- **[FILL]** — replace the `<slots>` with facts verified by reading THIS repo this session; never invent a command, path, skill, or hook.
- **[COND]** — include verbatim only if the repo has the named feature; else drop the whole block.

**FILL prose is plain project description, not a manifesto.** `## What this project is` (and any FILL narrative) reads like a careful engineer's README: calm, complete, declarative sentences, one idea each — no performative refrains ("Name the domain, walk the phases, paste the evidence"), no slogans ("ship 10% done"), no imperative tics ("read them, do not infer"), no mid-sentence emphasis-bold, no one-sentence-whole-app run-ons. Keep normal technical density (em-dashes, fragments, tables are fine — this is a technical doc). See the operating-manual template's "How to fill" note and `tightening-prose` for the full register. The `**Hard rules:**` block below is STRICT/directive by design — this register governs FILL narrative, not the process directives.

## Section order (fixed)

1. `# <Project> — Claude entry point` — **[FILL]** project name, then a **[FILL]** one/two-sentence plain project description immediately after the title
2. `## How to work here (read first)` — **[SECTION: how-to-work.md]** (SDD-chain pipeline one-liner, front-door + operating-manual slots) + **[SECTION: hard-rules.md]** (verbatim)
3. `## What this project is` — **[FILL]** product + stack, grounded; plus, for an SDD-chain repo, the single design-docs location convention
4. `## Common commands` — **[FILL]** the real dev commands table
5. `## Skill routing` — **[FILL]** task → skill table
6. `## Slash commands` — **[COND]** only if the repo has `.claude/commands/`
7. `## Where rules live` — **[FILL]** layer → folder table
8. `## Engineering system` — **[STRICT]** frame; the section list and the persona string are `<slots>` (the persona MUST equal the operating manual's `## Role` `<POSITION>` verbatim)

## Template

```markdown
# <Project> — Claude entry point

<!-- [FILL] one- or two-sentence plain project description, immediately after the title (before any @import). Plain README register: what the app is, who it's for, platform; no manifesto/slogans. The fuller stack detail stays in ## What this project is below. -->
<One or two plain sentences: what this app is, who it's for, and the platform.>

[SECTION: assets/sections/how-to-work.md — transclude verbatim for an SDD-chain repo; fill the front-door-command and operating-manual-filename slots. A non-chain repo replaces this with its own [FILL] pipeline one-liner instead.]

[SECTION: assets/sections/hard-rules.md — transclude 100% verbatim; byte-identical across every repo, no per-repo edits]

## What this project is

<One or two sentences: product + platforms.> <Then the stack as the repo actually uses it.> Stack pins live in [`<stack-manifest>`](./<stack-manifest>) and [.claude/rules/](./.claude/rules/) — read them, do not infer.

Design docs follow one convention: specs in `docs/specs/YYYY-MM-DD-<topic>.md`, plans in `docs/plans/YYYY-MM-DD-<topic>.md` (the `writing-specs`/`writing-plans` defaults) — a single declared location so the output path stays deterministic.
<!-- Include the design-docs line ONLY if the repo applies the writing-specs/writing-plans chain; drop it otherwise. If the repo already keeps design docs elsewhere, name that ONE location instead of the defaults — but never leave it multi-valued: two competing dirs (e.g. both `specs/` and `docs/specs/`) make the output path a coin-flip from session to session. -->

## Common commands

| Task | Command |
|---|---|
| run / dev | `<run-cmd>` |
| typecheck | `<typecheck-cmd>` |
| lint | `<lint-cmd>` |
| lint autofix / format | `<format-cmd>` |
| test | `<test-cmd>` |
| native install / build / deploy | `<build-deploy-cmd>` |

<List every command the team actually runs — not just the basics. If there is no test pipeline, state it in one line here: e.g. "There is no `<test>` script; verification is `<typecheck>` + `<lint>` + manual, judged against the feature's spec.">

## Skill routing

| Task triggers a skill | Skill |
|---|---|
| <concrete task / file pattern> | `<skill-name>` |
| Approaching the context limit / ending a session with unfinished work | `handoff` |

When a user prompt contains a registered trigger and the corresponding skill is not invoked within a few tool calls, `<.claude/hooks/detect-bypass.sh or the repo's bypass hook>` warns and logs the event to `<.claude/skills/_metrics.jsonl>`. Triggers are listed in [.claude/skills-routing.json](./.claude/skills-routing.json).
<!-- Include the sentence above ONLY if the repo actually has a bypass-detection hook + routing registry; otherwise drop it. -->

## Slash commands

Process commands under `.claude/commands/`, each a multi-phase flow with user-approval gates:

| Command | When to use |
|---|---|
| `/<command>` | <one line — list every command the repo has> |

For trivial one-line fixes, skip the commands and edit directly.

## Where rules live

One row per rule folder the repo actually has:

| Layer | Folder |
|---|---|
| Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
| Cross-cutting process & policy (code style, file org, security, error handling) | [.claude/rules/common/](./.claude/rules/common/) |
| <framework/runtime patterns> | [.claude/rules/<area>/](./.claude/rules/<area>/) |
| <language idioms> | [.claude/rules/<area>/](./.claude/rules/<area>/) |
| <data / API layer> | [.claude/rules/<area>/](./.claude/rules/<area>/) |

## Engineering system

<!-- [STRICT] frame. The persona in parentheses MUST equal the operating manual's `## Role` <POSITION> verbatim — same intake fact in both files; a mismatch is the drift auditing-claude-md flags. List only sections the manual actually has. Strip this comment. -->
Full operating manual (system prompt for HOW to work): [.claude/CLAUDE.md](./.claude/CLAUDE.md). Covers the **Role** (`<POSITION — identical to the operating manual's ## Role>`), the Non-negotiables, <the manual's other actual sections — e.g. operating modes, the <PIPELINE> workflow, the Completeness Checklist, plan persistence & session-handoff, search-before-ask, git boundary, status-block format>.

Process basics (<Implementation Protocol, Suspicion Protocol, evidence-based verification, question discipline>): [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md).
```

## Notes

- **Hard rules** (here) ≠ **Non-negotiables** (in the operating manual). Hard rules are the 3-5 entry-point reminders a fresh session needs immediately; Non-negotiables are the discipline set that must survive context summarization. Overlap is fine; the root version is shorter.
- **Common commands** is the real dev/verification commands the human actually runs (run / typecheck / lint / build / test). Do not pad it with internal validator one-liners or invent a `test` script — if there is no test pipeline, say so in one line. A wrong command here wastes every session.
- **Skill routing** is first-class: a task→skill table so the agent loads the right skill before editing. Omit a row only if the skill genuinely doesn't exist.
- **Design-docs convention** is for repos that apply the `writing-specs`/`writing-plans` chain: declare ONE location (the `docs/specs/` + `docs/plans/` defaults, or the repo's existing single home) so the skills' "where the project keeps design docs" detection resolves deterministically. Two competing dirs are exactly what makes the output path drift; omit the line entirely for a repo that doesn't run the chain.
- Keep the root an index. Anything about *how* to work goes in `.claude/CLAUDE.md`.
