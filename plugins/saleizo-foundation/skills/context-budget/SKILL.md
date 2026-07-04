---
name: context-budget
description: >-
  Use to audit what consumes the Claude Code context window before any work
  starts — CLAUDE.md files, always-on rules, the skill catalog, MCP server tool
  schemas, hooks, and agent definitions — and produce one fixed-shape budget
  snapshot with a token cost per category and a prioritized, disposition-tagged
  trim list. Distinct from routing/telemetry review and the runtime token
  guard. Triggers on: "context budget", "context bloat", "what's eating my
  context", "token budget audit", "trim my setup", "too many skills/rules",
  "reduce context usage", "проверь контекст-бюджет", "что ест контекст",
  "раздут контекст", "почистить сетап", "аудит токенов".
---

# Context Budget

Audit what consumes the context window before the first real turn, and report it in **one fixed shape** so two runs converge and can be diffed. A capable agent already knows *how* to eyeball config bloat; what it does NOT do reliably is (a) enumerate **every** consumer category — it works from "what happened to load in my session" and misses the biggest hidden one, **MCP tool schemas** — and (b) emit the **same categories, same token method, same snapshot** every run. Completeness + comparability are the value. The taxonomy and the shape ARE the skill.

## Boundaries (what this is NOT)

- **Not `reviewing-telemetry`** — that reads routing/bypass metrics from real sessions. This measures **static context-window cost** of the installed surface, not runtime routing behavior.
- **Not the `token-guard` hook** — that enforces a per-turn spend budget at runtime. This is an offline audit of what loads *before* the turn.
- **Reports only** — it never edits a rule, CLAUDE.md, or settings (see Hand-off).

## The consumer taxonomy — count EVERY category, in order

The always-on / pre-work context is the sum of these. Locate and token-count **each** — never report a budget that silently omits one (an omitted category reads as zero cost):

1. **CLAUDE.md files** — the project root, `.claude/CLAUDE.md`, and the global `~/.claude/CLAUDE.md`, including every `@import` they pull in.
2. **Always-on rules** — rule files that load unconditionally (no path/trigger scoping). A path-scoped rule that only loads on matching edits is NOT always-on — do not count it as pre-work cost; note it separately as conditional.
3. **Skill catalog** — every enabled skill's `description` (+ trigger tail) listed for routing, across ALL enabled plugins (project and global), not just this repo's.
4. **MCP server tool schemas** — each connected MCP server's tool definitions AND server instructions. **Often a large hidden consumer** (dozens of JSON tool schemas + a deferred-tools list); a budget that skips it is incomplete, not merely imprecise. Note whether the harness *defers* full schemas (only tool names resident until loaded on demand) — that changes the cost by an order of magnitude.
5. **Built-in tool schemas** — the always-loaded native tools (illustratively Agent, Bash, Read/Edit/Write, Skill, …), each with its usage notes and examples. Fixed harness cost (disposition almost always **keep**), but it commonly rivals the largest user-configurable category, so a complete budget must count it — do not fold it silently into MCP.
6. **Hooks** — any hook that injects context or system-reminders (most inject little; count what does).
7. **Agent definitions** — the available-agent-type list surfaced to the model.

## Token accounting — fixed so runs are comparable

- Measure each artifact's **rendered size** in bytes/chars (illustratively `wc -c`), then convert with a **stated, held-constant** chars-per-token ratio (~4 for English/markdown is the standard estimate) — OR an exact tokenizer when available. Do not mix an exact count for one category with an estimate for another; pick one method and record it in the report header so two runs are comparable.
- Count a consumer once, at the size it actually loads (a folded `description`, a rendered tool schema), not the whole source file when only part loads.

## The snapshot — REQUIRED fixed shape

Emit exactly these sections, in order:

```text
## Context budget — <scope>, <date>, est @ <N> chars/token

### Top-line
- Always-on total: <n> tokens (<pct>% of a <window>-token window)   (Δ vs <prev date>: <+/-n>, or "baseline")
- Largest consumer: <category> — <n> tokens

### By category
| Category | Component(s) | Tokens | % of always-on |
| --- | --- | --- | --- |
| CLAUDE.md | root + .claude + global | <n> | <pct> |
| always-on rules | <count> files | <n> | <pct> |
| skill catalog | <count> skills | <n> | <pct> |
| MCP tool schemas | <count> servers | <n> | <pct> |
| built-in tool schemas | <count> tools | <n> | <pct> |
| hooks | <count> | <n> | <pct> |
| agent defs | <count> | <n> | <pct> |

### Savings   (each: component · tokens · action → disposition)
1. <component> — ~<n> tok: <action>. → <trim | scope | relocate | keep>
(Nothing avoidable → "No avoidable always-on cost — the budget is justified.")

### Recommended next step
<one line: the single highest-leverage cut, or "none">
```

## Disposition vocabulary — one per savings line

| Disposition | Means |
| --- | --- |
| **trim** | delete or shorten the content itself |
| **scope** | add path/trigger gating so it loads on demand, not every turn |
| **relocate** | move a global always-on item to where it actually applies (e.g. a stack rule into the repos that use that stack) |
| **keep** | justified always-on cost — record it as kept, do not omit it |

## Hand-off — surface, never auto-apply

This skill **reports**; it does not touch config. Route each cut to its owner:

- **scope** a rule → the human edits that rule's own path/trigger frontmatter (the `skill-routing-sync` rule governs a routing change).
- **relocate** / disable a plugin or MCP server → the human edits the relevant settings.
- **trim** a CLAUDE.md / rule → author the edit via `writing-rules` / the doc's own owner.

Present the snapshot; the human picks which cuts to apply.

## Red Flags — STOP

- Omitting the **tool schemas** — both MCP and the always-loaded built-in tools (Agent/Bash/…). Measuring only markdown files misses the schema weight, which commonly rivals the largest markdown category; a budget without both schema rows is incomplete, not approximate.
- Measuring "what loaded in my session" instead of enumerating every taxonomy category — session-load is a sample, not the budget.
- Varying the chars-per-token ratio across runs, or mixing an exact tokenizer with an estimate across categories — the numbers stop being comparable and no Δ is possible.
- Counting a path-scoped (conditional) rule as always-on cost — distinguish always-on from conditional; only unconditional loads are pre-work budget.
- A free-form essay instead of the REQUIRED snapshot shape — two runs then diverge.
- A savings line with no disposition label (trim / scope / relocate / keep).
- Editing rules, CLAUDE.md, or settings from inside this skill — it reports; the human applies.
