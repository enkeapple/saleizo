# Audit Report — example (illustrative)

A filled `auditing-hooks` report in the REQUIRED fixed shape over a repo with all five drift classes present — the locked finding shape, the per-class clean line, the out-of-scope parking, a one-line Summary, and the single C-drift picker. Paths are _(illustrative — your repo's layout may differ)_.

```text
# Hook Wiring Audit — kit marketplace

## Findings   (D1–D5 in order; each finding in the locked finding shape)
[D1 Orphan script] Medium
  what:     hook-z.sh exists on disk but no wiring command names it
  evidence: plugins/kit/hooks/hook-z.sh  ↔  (absent from .claude/settings.json + plugins/kit/hooks/hooks.json)
  recommend: mechanical — wire it under its intended event, or delete the dead script (owner)

[D2 Dangling wiring] High
  what:     a PostToolUse command points at a script that does not exist
  evidence: plugins/kit/hooks/hook-y.sh (missing)  ↔  plugins/kit/hooks/hooks.json:6
  recommend: mechanical — restore hook-y.sh or remove the wiring entry

[D3 Broken symlink indirection] High
  what:     the surfaced guard symlink resolves to a missing target
  evidence: .claude/hooks/guard-b.sh -> ../../hooks/guards/guard-b.sh (missing)  ↔  .claude/settings.json:8
  recommend: mechanical — repoint/recreate the symlink, or drop the guard-b wiring

[D4 Event/matcher mismatch] High
  what:     a script that inspects an Edit/Write payload is wired under PreToolUse matcher "Read"
  evidence: plugins/kit/hooks/hook-edit-guard.sh (reads tool_input.file_path)  ↔  plugins/kit/hooks/hooks.json:9 (matcher "Read")
  recommend: owner-action — set the matcher to Edit|Write (which matcher is correct is the owner's call)

[D5 Fixture gap] Medium
  what:     a wired Stop hook has no fixture beside it
  evidence: plugins/kit/hooks/hook-x.sh (wired)  ↔  no plugins/kit/hooks/tests/hook-x.sh.cases
  recommend: mechanical — add a fixture stub via writing-hooks (crafted stdin -> asserted decision)

## Clean classes
(none in this example — all five classes have an instance; a clean class reads e.g. "D3 Broken symlink indirection: no drift found", one line per clean class, none omitted)

## Out of scope (noted, not findings)
- guard-a.sh matches *force* as a substring (over-broad) — hook logic, not wiring → writing-hooks / code review.
- hook-edit-guard.sh has no deny branch / hook-x.sh is a no-op vs its comment — logic, not wiring.

## Summary
- Findings: 5 (High 3 · Medium 2 · Low 0) · Clean classes: 0 · Out-of-scope notes: 2

## Decision
- `Apply recommended` → run each finding's fix in its lane (D1/D2/D3 mechanical, sequential, stop-on-first-failure; D5 fixture stub via writing-hooks; D4 owner — matcher choice).
- `Adjust per-finding` → walk the 5 findings one by one.
- `Stop` → take no action now.
```
