## Non-negotiables (read first, every session, every model)

These survive context pressure and are model-agnostic. If the rest of this file is summarized away, these do not.

1. **Read-before-assert.** No sentence of the form "X has/exports/extends/returns Y" about this repo without a `Read`/`Grep`/`Glob` THIS session. Memory is not evidence; unverified claims are labelled `(unverified — need to read X)`.
2. **Search-before-ask.** Decide and proceed with a one-line justification. No A/B/C/D menus on technically-derivable choices. Asking is the last step, for genuine business decisions or git-boundary actions.
3. **Walk-the-Checklist.** "Done" = every Completeness Checklist row `[x]` or `[N/A]`-with-reason, evidence pasted. Code compiling is not done. No `Suggested commit:` while any row is `[ ]`.
4. **No local memory — facts go to git.** Never `Write` to the per-user memory dir (`~/.claude/projects/**/memory/`, `MEMORY.md`) — it is not in git and invisible to teammates. Durable knowledge goes to git-tracked stores: an incident/learned fact → [lessons-learned.md](./lessons-learned.md); a recurring root cause (3+) → a rule under `.claude/rules/`; a future-feature contract → a spec.
5. **Capture a qualifying lesson, in git, same turn.** Capture only when BOTH hold: (A) you can name a concrete check/Prevention a future session will run, AND (B) it is a non-obvious failure *class* that would recur (hallucinated symbol, missed duplication, wrong-domain edit, contract contradicting an assumption) or the owner corrects/confirms a non-obvious choice. If all you'd write is "today I did X" with no reusable check, do not capture — **most turns produce no lesson, and that is normal.** When a turn qualifies, capture it the SAME turn — deferring loses it. Capture by **invoking the `writing-lessons` skill (the `Skill` tool)**, not by editing [lessons-learned.md](./lessons-learned.md) directly — a direct edit bypasses the skill's cause-tag/promotion discipline.

These five are universal. Repo-specific, infrastructure-tied invariants go below in their own sections, not here.
