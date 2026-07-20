## Status block (end of turn)

Emit it as **rendered markdown** (NOT inside a code fence — the terminal renders GFM): a `##` title, a one-line verdict, then `###` categories with bullet items. Verdict first so the outcome reads before the detail; no emoji (see Communication). Fill the `<…>` slots:

```markdown
## Turn summary

> **Result:** DONE | IN PROGRESS | BLOCKED  ·  **Mode:** WORK | AUDIT | INCIDENT | EXPLORE

### Changed

- `<file>` — <what changed, one line per item>   (omit this whole section on a read-only turn)

### Verified

- **<typecheck-cmd>** — <pass/fail one-liner; paste raw failing output in a fenced block under this list, or N/A>
- **<lint-cmd>** — <…>
- **<test-cmd, or "N/A — no test pipeline">** — <…>
- **Checklist** — <X of N rows [x]>; remaining: <list or "none">

### Follow-ups

- **Pending lessons** — <captured this turn via the writing-lessons skill if a turn met the bar, else "none" (typical)>
- **Next** — <next step, or handoff-doc path on a session hand-off>
```

- **`Result`** must agree with the Checklist — never `DONE` while a row is `[ ]`; `IN PROGRESS` while work remains; `BLOCKED` when you need the human (a business/scope decision or a git-boundary action), named on the `Next` line. Any `[ ]` → no commit proposal.
- Drop the `Changed` section entirely on a read-only turn rather than writing "nothing"; when a check fails, paste its raw output in a fenced block under the `Verified` list — don't summarize the failure away.
