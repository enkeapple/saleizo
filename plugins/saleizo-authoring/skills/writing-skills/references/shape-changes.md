# Shape Changes — split / merge / rename

Changing the *set* of skills, or a skill's identity, is a **branch** distinct from a plain edit: the
failure mode is not a bad body but a broken link between what is on disk and what the router knows.
The Iron Law still holds (RED before you write); these are the obligations it adds on top.

## Re-RED each resulting contract

A skill's identity is its contract, so a shape change creates new contracts to prove:

- **split** — two new contracts. Establish a RED for each half on the behaviour it now *solely* owns,
  then GREEN it. A split is not a cut-and-paste; each half earns its own failing test. Bright line: if
  you cannot state a scenario one half handles that the other does not, the halves are not distinct
  contracts — that is cosmetic separation, not a split; don't split.
- **merge** — one new contract. RED the combined behaviour (a scenario the merged skill must handle
  that neither half fully did), then GREEN.
- **rename** — the contract is unchanged, so no new behavioural RED; the diff-scoped check is that the
  skill still *fires* under its triggers after the move (see routing sync below).

## Sync routing + every name reference in the same change

An added / renamed / removed skill is not done until the router and every reference agree with disk.
Update, together, in one change:

- the **routing registry** entry — both the key **and** the `name` field;
- the **directory** name;
- the **`name:` frontmatter** (the invariant `name === dir === routing key` must hold);
- any **alias body** that names the skill (an alias is a structural name reference);
- any **path-based link** to it from another skill — a Markdown link whose target is
  `../old-name/SKILL.md` — not only literal-slug matches, which a naive grep for the bare name misses;
- any **human-facing catalog** the consumer maintains that lists the skill by name (a README skills
  table, a routing or docs index, a top-level guide). These are name references too, even when a
  separate skill owns the catalog's upkeep — a rename that leaves a stale catalog row is an orphaned
  reference, so grep the whole repo for the old name, not just the skill tree.

Then **re-confirm it fires**: its triggers resolve to it. A folder renamed but not registered ships a
dead skill.

## Sweep orphaned cross-links after a split

A link that crossed the seam now dangles. Layer-1 check 5 catches a dead *file* link; a prose
reference *by name* ("see the X step below", now in the other half) needs a grep. Fix or re-home each.

## Completion

The shape change is done only when: each resulting contract is RED→GREEN, the routing registry and
all name/path references match disk, every skill still fires under its triggers, and no cross-link
dangles. Then run the `validate` gate on each resulting skill.
