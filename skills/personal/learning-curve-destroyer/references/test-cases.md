# test-cases — learning-curve-destroyer

Shaping skill: the failure is **wrong output shape**, so the test checks shape, not refusal.

## Scenario 1 — "I want to learn SQL. Teach me."

### RED (baseline, WITHOUT the skill) — observed verbatim shape

A default assistant produced:

- Opened with standalone theory: *"SQL is a language for asking questions of data… A database stores data in tables."*
- A curriculum/list: numbered "five core operations" + tiers (aggregation, joins, ORDER BY).
- Comprehensive coverage of the feature set and dialect notes.
- A "Next Steps" ladder + multiple exercises.

This is exactly the shape the skill prohibits (theory-first, syllabus, breadth, multi-exercise).

### GREEN (WITH the skill) — required shape

The answer MUST be exactly three slots, in order, and nothing else:

1. **Learn this first** — one highest-leverage move (e.g. `SELECT … WHERE`), shown immediately in a concrete query; no standalone theory paragraph.
2. **Ignore entirely (for now)** — concrete trap list (e.g. JOINs-before-SELECT, DB install, dialect wars, stored procedures), one line each, stated flat.
3. **The one rep** — a single exercise on a named sandbox (e.g. sqliteonline.com) with an explicit done-signal.

No syllabus, no "Next steps"/further reading, no multi-exercise plan.

### Inversion (why the test bites)

Would an assistant comply WITHOUT the skill? No — the RED baseline naturally produces theory-first + curriculum. The skill's value is forcing the three-slot ruthless shape.

## Notes for a re-validation run

- Vary the target skill (SQL / touch-typing / public speaking) to confirm the shape holds across domains, not just code.
- Fail the run if the answer lists a numbered set of *topics* (syllabus) or more than one exercise.
