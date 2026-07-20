# Requirements Quality Checklist

Run this against every story before saving. If an item fails, fix it; if you cannot fix it without user input, flag it as an Open Question.

- [ ] Layout matches the story count: one story → a single `docs/requirements/stories/YYYY-MM-DD-<slug>.md`; more than one → a `docs/requirements/features/YYYY-MM-DD-<slug>/` folder with `requirements.md` + one `NN-<story-slug>.md` per story. Never several stories in one file. Separate from specs/plans.
- [ ] The file opens with YAML frontmatter carrying a `status:` field, one of `draft` / `ready` / `in progress` / `done`; a newly written doc is `draft` (advanced only at its gate, one state at a time).
- [ ] Each story file's title is its `#` H1; sections are `##`; the Success/Failure/Edge sub-blocks are `###`. Real headings, not bold pseudo-headings.
- [ ] Each story has a `As a <role>, I want <capability>, so that <value>` user story.
- [ ] **In Scope** and **Out of Scope** are both present and non-empty.
- [ ] **Entry Points** present for any UI-affecting story (paths as `<App> → <Page> → <action>`); omitted for backend/integration-only.
- [ ] **Functional Overview** is 1–3 sentences, behaviour only.
- [ ] Acceptance criteria are split into **Success / Failure / Edge Cases** and numbered **continuously** across all three.
- [ ] Every AC is testable — no "should", no "etc.", no trailing "…", no prose-only items.
- [ ] Non-technical — a business reader understands every line: no code blocks, no data formats (JSON/XML/payload), no HTTP status codes, no transport/protocol jargon (webhook, endpoint, API, queue, worker, idempotency key, polling).
- [ ] No implementation detail — no schema, algorithm, library, storage layout, or HTTP status. Behaviour only.
- [ ] Every criterion is declarative with the **system** as subject; a user action appears only as a trigger.
- [ ] Existing page/field/section names are in _italics_; new names live in the **Texts** table, not in AC prose.
- [ ] **Affected Apps and Services** table is present.
- [ ] Any value the request did not supply (expiry, limit, threshold) is an inline Assumption **and** a row in the **Open Questions** table — never stated as settled fact.
- [ ] The artifact is a requirements doc — NOT a spec (no contracts / files-touched / verification commands).
