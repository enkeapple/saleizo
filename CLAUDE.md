# SDD Workflow — marketplace & Claude entry point

A **Claude Code skill marketplace** and the in-place repo that develops it. The repo publishes 10 flat, per-concern plugins via `.claude-plugin/marketplace.json` — **saleizo-core** (the gated Spec-Driven-Development chain plus `systematic-debugging` and `handoff`), **saleizo-commands** (short user-typed alias commands that delegate to the canonical SDD skills), **saleizo-authoring** (test-first authoring of skills/hooks/rules/lessons/ADRs), **saleizo-foundation** (adopt/bootstrap/audit the framework in a consumer repo, plus routing/telemetry review), **saleizo-design** (deep-module design, architecture review, code-quality review), **saleizo-prose** (de-slop / humanize prose, store release notes), **saleizo-learning** (user-invoked learning skills), **saleizo-controls** (the routing-bypass detection, telemetry, session, and quality hooks that the harness reads from `.claude/skills-routing.json`), **saleizo-react-native** (React Native accessibility / WCAG auditing), and **saleizo-docs** (scaffold/audit/extend a consumer repo's project documentation as manifest-declared views over machine-readable sources). The product is not an app — it is the skills themselves and *how they interact*. The goal is a flexible system that surfaces its own bottlenecks (a misfiring skill, a leaky hand-off, an over-rigid step), which become lessons → rules → skill edits.

## How to work here (read first)

Authoring or changing a skill runs through **RED → GREEN → REFACTOR → VALIDATE** (the `writing-skills` TDD methodology). Applying the framework to a consumer repo runs the chain `grilling → writing-specs → writing-plans → pre-implementation-protocol → inline-driven-development | subagent-driven-development → verifying-implementation` (each task test-first via `test-driven-development`). Full operating manual: [.claude/CLAUDE.md](./.claude/CLAUDE.md).

**Hard rules:**

- **No behavioral skill (or skill edit) without a failing test first — tiered by edit-type.** Classify each edit by the reversion test ("revert this — does a subagent behave differently?"): behavioral → full RED→GREEN (watch the baseline fail before writing; wrote it first? delete, start over); descriptive → one cited real prior failure inline; mechanical → validators only. Full classifier in [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md) → Iron Law.
- **Agnostic by default.** A skill never hard-depends on one project's stack, paths, or commands — the consumer repo fills specifics.
- **Capture a qualifying lesson the same turn.** Only when it passes the (A)+(B) bar — a concrete reusable check AND a recurring/non-obvious class (most turns produce none); `writing-lessons` owns the bar. Recurring (3×) → `writing-rules`.
- **Verify before "done".** Validators pass AND a GREEN subagent run confirms the behavior — code/markdown existing is not "done".
- **Skill names are structural claims.** A reference to a skill must match its real dir/`name` under `plugins/*/skills/**` and its routing key in `.claude/skills-routing.json` — verify, don't recall.

## What this project is

Agnostic skills authored flat under `plugins/<kit>/skills/<name>/` (no category dir) across the nine skill-bearing kits (`saleizo-core`, `saleizo-commands`, `saleizo-authoring`, `saleizo-foundation`, `saleizo-design`, `saleizo-prose`, `saleizo-learning`, `saleizo-react-native`, `saleizo-docs`; `saleizo-controls` ships hooks only — ten plugins total, each with its own `.claude-plugin/plugin.json`) and discovered by Claude Code via the installed marketplace plugins, plus the harness around them: the marketplace manifest `.claude-plugin/marketplace.json`, guard hooks in `hooks/guards/` surfaced via `.claude/hooks/` symlinks (wired by root `settings.json`), routing/metric/session/quality hooks in `plugins/saleizo-controls/hooks/` (wired by its `hooks.json`), `.claude/rules/domains/` (framework + domain glossary) and the concern folders `.claude/rules/{verification,authoring,workflow,conduct}/` (cross-cutting rules), `.claude/skills-routing.json`, `.claude/state/`. No application code, no `package.json`, no build.

This repo's own design docs follow a single convention: **specs live in `docs/specs/YYYY-MM-DD-<topic>.md`, plans in `docs/plans/YYYY-MM-DD-<topic>.md`** — never bare `specs/` or `plans/` at the root. This is the convention `writing-specs`/`writing-plans` detect via "where the project keeps design docs"; keeping it single-valued is what makes the output path deterministic.

## Common commands

No build / dev / test pipeline — this is a skills marketplace, not an app. Verification is **(a)** the skill validators (frontmatter ≤1024, name regex, reference links resolve, fence balance, word count) and **(b)** subagent RED/GREEN pressure runs. Both are defined in the operating manual → "Workflow" / "Completeness Checklist", not run as project scripts. Read-only `git` inspection is the only routine shell use.

## Skill routing

| Task | Skill |
| --- | --- |
| Run the full gated SDD pipeline end-to-end on a change (front door) | `sdd-lifecycle` |
| Resolve a ticket ID / URL into a faithful requirements bundle before design | `resolving-requirements` |
| Turn a fuzzy idea into a shared, concrete design | `grilling` |
| Turn an approved design into a concrete spec | `writing-specs` |
| Turn a spec into a task-by-task implementation plan | `writing-plans` |
| Run the readiness check before executing a plan (or before coding with no plan) | `pre-implementation-protocol` |
| Investigate a bug / failure to a confirmed root cause (standalone; hands the fix to `test-driven-development`) | `systematic-debugging` |
| Implement test-first (RED→GREEN→REFACTOR) | `test-driven-development` |
| Execute an approved plan solo, in-session (coupled tasks or a small plan) | `inline-driven-development` |
| Execute an approved plan via a fresh subagent per task (independent tasks) | `subagent-driven-development` |
| Check shipped code against an approved spec | `verifying-implementation` |
| Adopt / install the framework into a fresh consumer repo (ordered: copy → symlinks → bootstraps → routing → verify) | `adopting-framework` |
| Create / audit the two CLAUDE.md files | `bootstrapping-claude-md` / `auditing-claude-md` |
| Create / audit the base domain rules (glossary, framework) | `bootstrapping-glossary` / `auditing-glossary` |
| Create / audit the README skills catalog | `bootstrapping-readme` / `auditing-readme` |
| Find conflicts/contradictions across skills, rules, and routing | `auditing-conflicts` |
| Audit hook scripts against their wiring (orphan / dangling / broken-symlink / event-matcher / fixture-gap drift) | `auditing-hooks` |
| Review routing/telemetry health — bypasses, friction, hand-off leaks — into a triage digest | `reviewing-telemetry` |
| Audit what consumes the context window (CLAUDE.md, rules, skills, MCP, hooks) into a budget snapshot | `context-budget` |
| Adherence-test production skill compliance against the routed triggers | `skill-comply` |
| Capture a lesson; promote a recurring one to a rule | `writing-lessons` → `writing-rules` |
| Author or change any skill (test-first) | `writing-skills` |
| Author or change a Claude Code hook (test-first) | `writing-hooks` |
| Record an architectural decision as an immutable ADR (gate it, maintain the index, supersede — never edit) | `writing-adrs` |
| Design a deep module / find a seam (shared deep-module vocabulary) | `codebase-design` |
| Architecture review — surface deepening opportunities (user-invoked, not trigger-routed) | `improve-codebase-architecture` |
| Pressure-test a decision from five independent role-lenses and synthesize a verdict | `decision-council` |
| De-slop an existing chunk of prose (remove the AI tells) | `tightening-prose` |
| Rewrite a draft into publication-ready prose (article / blog / post register) | `humanizing-prose` |
| Turn a release diff into user-facing store release notes (Google Play / App Store) | `drafting-release-notes` |
| Audit / improve React Native screen accessibility against WCAG 2.2 AA | `accessibility` |
| Set up a consumer repo's project documentation from scratch (manifest + managed docs over sources) | `scaffolding-docs` |
| Audit project documentation for drift against its sources and fix it | `auditing-docs` |
| Add a new documentation type (author a derivation contract test-first) | `extending-docs` |
| Approaching the context limit / ending with unfinished work | `handoff` |
| Short user-typed aliases (deterministic entry; same skills) | `/sdd`→`sdd-lifecycle`, `/grill`→`grilling`, `/spec`→`writing-specs`, `/audit`→`verifying-implementation`, `/adr`→`writing-adrs` |

When a user prompt contains a registered trigger and the corresponding skill is not invoked within a few tool calls, `detect-bypass.sh` (from `saleizo-controls`) warns and logs the event to `.claude/state/_metrics.jsonl` (gitignored). Triggers are listed in [.claude/skills-routing.json](./.claude/skills-routing.json).

## Where rules live

| Layer | Folder |
| --- | --- |
| Domain rules (glossary, framework charter) | [.claude/rules/domains/](./.claude/rules/domains/) |
| Verification guards (the false-clean "check didn't establish what it claimed" family) | [.claude/rules/verification/](./.claude/rules/verification/) |
| Skill / rule / test authoring discipline (agnostic authoring, scoping, self-containment, RED baseline, routing sync) | [.claude/rules/authoring/](./.claude/rules/authoring/) |
| SDD-chain UX presentation (interactive gates, phase-task visualization) | [.claude/rules/workflow/](./.claude/rules/workflow/) |
| Cross-cutting agent conduct (concise responses, git conventions, model selection, markdown style) | [.claude/rules/conduct/](./.claude/rules/conduct/) |
| Code-quality conventions (clear names, concise functions, no over-engineering, reuse-first, …) | [.claude/rules/clean-code/](./.claude/rules/clean-code/) |
| Anti-patterns to refuse (error-handling, type-escape-hatch, debugging residue, security baseline, …) | [.claude/rules/anti-patterns/](./.claude/rules/anti-patterns/) |
| Repo-local consumer config (e.g. the `resolving-requirements` ticket source) | [.claude/rules/flbco/](./.claude/rules/flbco/) |

Rules load on demand, not auto-injected. Bootstrap them in a consumer repo with `bootstrapping-glossary`; keep them true with `auditing-glossary`.

Architectural decisions about the framework itself are recorded as immutable ADRs — see [README → Architecture Decision Records](./README.md#architecture-decision-records).

## Engineering system

Full operating manual (system prompt for HOW to work): [.claude/CLAUDE.md](./.claude/CLAUDE.md). Covers the **Role** (Principal AI/Workflow Engineer), the **Non-negotiables** (Iron Law, agnostic-by-default, read-before-assert, validate-before-done, capture-bottlenecks), the **operating modes** (AUTHOR / AUDIT / APPLY), the **RED → GREEN → REFACTOR → VALIDATE** authoring workflow, the **Completeness Checklist** for a skill change, the **session-handoff** flow, search-before-ask, the git boundary, and the status-block format.

Process basics (Implementation Protocol, Suspicion Protocol, evidence-based verification, question discipline): [.claude/rules/domains/framework.md](./.claude/rules/domains/framework.md). Domain glossary: [.claude/rules/domains/glossary.md](./.claude/rules/domains/glossary.md).
