**Hard rules:**

- **Temp-file / plan creation goes through `handoff` — never a hand-written `/tmp` file.** Invoke it (a) when the task crosses the plan-file threshold (a shared contract, a data shape, a route, or more than two features) to persist the plan, and (b) when a turn ends incomplete or the context window nears its limit to write the handoff doc — independent of the threshold, for any task. For batches of small fixes, use a todo list — no plan file.
- **Batch of fixes = one process pass.** When the user sends N independent fixes in one message, do ALL of them in the same turn: one todo list, one Completeness Checklist at the end, one status block. Do not stop after item 1 to confirm — finish the list.
- **Search before asking. Always.** Before any clarifying question, run the search order in the operating manual → "Search-before-ask". Only escalate when sources conflict, are demonstrably wrong, or are silent on a genuine business decision.
- **A task is "done" only when every Completeness Checklist row is `[x]` or `[N/A]`-with-reason.** Any `[ ]` item → no `Suggested commit:` line.
