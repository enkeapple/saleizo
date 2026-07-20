---
name: writing-requirements
description: >-
  Use to turn a rough feature request, ticket title, or bullet points into a
  behaviour-only requirements document — user stories, In/Out of Scope, and
  numbered acceptance criteria — BEFORE any design or spec work. Produces a
  requirements doc that feeds `grilling` / `sdd-lifecycle`, not a technical spec.
  Triggers on: "write requirements", "requirements doc", "draft a user story",
  "acceptance criteria", "spec out this ticket", "turn this feature request into
  requirements", "напиши требования", "user story", "критерии приёмки".
---

# Writing Requirements

Turn a fuzzy feature request into a requirements document an implementer can build from with zero further clarification. The artifact is **behaviour** — WHAT the system must do, never HOW.

This is **not** `writing-specs`: no contracts, files-touched, or verification commands. It produces the requirements those later phases consume; its output feeds `grilling` (design) or `sdd-lifecycle`. Hand it forward — do not roll into a spec here.

Project-agnostic: fill app/service names and product vocabulary from the consumer repo's own reference docs, if any.

## Location & layout — story vs feature

Count the user stories first; the layout follows the count. Put it where the project keeps requirements (defaults below), distinct from `docs/specs/` and `docs/plans/`.

- **One story → a *story*.** A single file: `docs/requirements/stories/YYYY-MM-DD-<slug>.md`.
- **More than one story → a *feature*.** A folder `docs/requirements/features/YYYY-MM-DD-<slug>/` holding:
  - `requirements.md` — the feature overview: context, dependencies, the story index (one row per story, linking its file), and the Supporting Details shared across stories (glossary, cross-cutting tables, shared Open Questions). Template: [assets/feature-overview-template.md](./assets/feature-overview-template.md).
  - one file per story, `NN-<story-slug>.md` — each a full story (In/Out Scope, Entry Points, Functional Overview, Acceptance Criteria, and any story-specific Supporting Details).

Never pack several stories into one file: more than one story is a feature folder, one file each.

## Required sections (in order)

Every story follows this recipe — same sections, same order, every time. Use real markdown headings, never bold-text pseudo-headings: the story title is the file's `#` H1, each section below is a `##` heading, and the three Acceptance-Criteria sub-blocks (Success/Failure/Edge) are `###`. Copy-paste template: [assets/requirements-template.md](./assets/requirements-template.md).

1. **User Story** — `As a <role>, I want <capability>, so that <business value>.`
2. **In Scope** — flows/behaviours this story covers. Never empty.
3. **Out of Scope** — related flows deliberately excluded. Never empty — an empty list means the boundary is unset.
4. **Entry Points** (*conditional* — UI stories only; omit for backend/integration-only) — each navigation path, `<App> → <Page> → <action>`.
5. **Functional Overview** — 1–3 sentences, behaviour only.
6. **Acceptance Criteria** — three sub-blocks **Success / Failure / Edge Cases**, numbered **continuously** across all three (Success 1–3, Failure 4–5, Edge 6–…). Each item one testable, declarative statement.
7. **Supporting Details** — tables only: **Affected Apps and Services**; new **Texts** (page/button/field/error names introduced); any status/state tables the ACs depend on; and an **Open Questions** table.

Above the `#` H1, every requirements file opens with a YAML frontmatter block carrying a `status:` field (see *Lifecycle status* below) — frontmatter first, then a blank line, then the H1.

## Lifecycle status

Every requirements artifact carries a `status:` field in YAML frontmatter — the first thing in the file, a blank line before the H1. It tracks where the requirement sits in its life. The agent moves it **by hand at the matching gate**, one forward step at a time; it is not inferred or automated.

| `status` | Meaning | Set it when |
| --- | --- | --- |
| `draft` | Being written; not yet approved | on creation — the template default |
| `ready` | Approved; ready for development — handed to `grilling` / `sdd-lifecycle` | the user approves the requirements |
| `in progress` | Implementation is underway | development on the requirement starts |
| `done` | Delivered and verified | the requirement is implemented and confirmed |

- The order is fixed: `draft → ready → in progress → done`. Advance exactly one state at the gate that earns it; never pre-set a later state (no `done` on an unbuilt requirement).
- For a **feature** folder, the overview `requirements.md` carries the feature's overall status and each `NN-<story>.md` carries its own, so stories can progress independently.

## Discipline — behaviour, not implementation

- **Non-technical — a business reader must understand every line.** No code or code blocks, no data formats (JSON/XML/payload examples), no HTTP status codes, no transport/protocol vocabulary (webhook, endpoint, API, queue, worker, idempotency key, polling). Describe the business outcome, not the wire. Name an external system in plain business terms only when unavoidable ("the partner's booking integration") — never its mechanism. If a line needs a technical term to make sense, it belongs in the spec, not here.
- **WHAT, never HOW.** "The system sends a confirmation email" ✓; naming the mail provider, template, or a token row ✗. No schemas, algorithms, libraries, storage layout, or status codes — those belong to a later spec.
- **Declarative, system as subject.** "Upon *Save*, the system validates the postal code" ✓; "the admin scrolls and clicks *Save*" ✗. A user action appears only as the trigger.
- **Testable ACs.** No "should", no "etc.", no trailing "…" — every AC is verifiable as written.
- **Never fabricate.** A value the request did not give — expiry, rate limit, threshold — is an **assumption**: state it inline `> Assumption: X. Confirm or correct.` AND add an Open Questions row. Never present an invented number as fact.
- **Existing names in _italics_; new names in the Texts table** — not buried in AC prose.

## Process

1. Understand the request; interview the user (question/picker tool) for anything that would force a rewrite if wrong. Make reasonable assumptions for the rest and flag them.
2. Scope: which apps/services/external integrations are touched, and the hand-off points between them.
3. Draft from the template.
4. Self-check against [assets/quality-checklist.md](./assets/quality-checklist.md); fix every miss or flag it.
5. Save the doc with `status: draft` in its frontmatter. Advance the status by hand as the requirement passes each gate (`ready` on user approval, then `in progress`, then `done`) — see *Lifecycle status*.
6. **Validate with a cold subagent** — dispatch a fresh zero-context reviewer ([assets/requirements-reviewer-prompt.md](./assets/requirements-reviewer-prompt.md)) with the original request *and* the doc; it hunts implementation leakage, non-testable ACs, missing scope boundary, unflagged assumptions. Read its findings, then fix or report. Use this generic subagent — never a project-specific named validation agent.

## Hand-off

An approved requirements doc is an INPUT to design:

> Hand it to `grilling` (to design) or `sdd-lifecycle` (full pipeline). Do NOT invoke `writing-specs` from here — requirements precede the spec.

## Red Flags — STOP

- An HTTP status code, a JSON/payload/data-format snippet, a code block, or a transport word (webhook / endpoint / API / queue / worker / idempotency key) → technical leak; rewrite as a plain business outcome.
- A database schema, algorithm, library name, or HTTP status → implementation, not requirements.
- An AC with "should" / "etc." / trailing "…" → not testable; rewrite concretely.
- An empty or absent Out of Scope → boundary unset.
- A number the request never gave, stated as fact → move to an Assumption + Open Questions.
- Producing "contracts" or "files touched" → wrong artifact; that is `writing-specs`, downstream.
- A requirements file with no `status:` frontmatter, or a status jumped ahead of its gate (e.g. `done` on an unimplemented requirement) → add/correct it; advance one state at the gate that earns it.

## Rationalizations

| Excuse | Reality |
| --- | --- |
| "It's an integration — I must describe the protocol and payload." | The wire — protocol, payload, status codes, retries — is the spec's job. State the business outcome: what the partner's data means and what the system does with it, in plain terms. |
| "I'll add the table schema so it's unambiguous." | Storage is HOW. Describe the behaviour; the spec phase designs the schema. |
| "24 hours is the obvious expiry, I'll just write it." | Never stated = assumption. Flag it in Open Questions; an invented fact read as settled is the churn source. |
| "User stories are ceremony, the functional list is enough." | The story fixes role + value; without it Scope and ACs drift. Three lines — write them. |
| "Out of scope is empty, everything's in scope." | Empty = boundary undrawn. Name what looks related but is excluded. |
| "'The system should validate…' is clear enough." | "Should" is untestable. State the system doing it: "the system rejects an invalid postal code and shows an error message." |
| "The doc is written, I'll mark it done." | `done` means delivered and verified. A freshly written doc is `draft`; it becomes `ready` only on approval. Advance one state per gate — never skip to a later state. |
