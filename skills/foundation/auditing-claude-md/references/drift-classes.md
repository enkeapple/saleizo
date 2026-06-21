# CLAUDE.md Drift Classes — manual-governance checks

Beyond the universal claim-verification (every command, path, version, and routing target checked against disk), a generated or hand-edited CLAUDE.md drifts in four governance-specific ways. Each has a falsifiable signal: flag it when the signal fires, and steer to the correct form. These apply only to a repo whose manual governs that construct — a repo that does not run the SDD chain owes no design-docs or lessons line.

| Drift class | Signal (what to grep/read for) | Why it is drift | Correct form |
| --- | --- | --- | --- |
| **Bypass wording** | a non-negotiable or pointer telling the agent to `append`/`Edit` a skill-owned artifact directly (e.g. `lessons-learned.md`, a plan file) when the routing registry HAS a skill that owns that workflow | the direct-edit instruction bypasses the skill, skipping its cause-tag / promotion / plan discipline | route through the `Skill` tool; name the owning skill |
| **Over-broad capture criterion** | a lessons mandate on "any friction" / every turn, or a `Pending lessons` status line with no "none"/N/A default, or the mandate stated without the (A)+(B) bar | floods the log with one-offs and trains the agent to ignore it; most turns should produce no lesson | gate capture on (A) a concrete reusable check AND (B) a recurring/non-obvious class |
| **Append-only lessons model** | the log called **append-only**, or "mark each entry `→ promoted`" instead of deleting the contributing entries on promotion | the stale model — git is the history, not the live log | transient backlog: promotion deletes the contributing entries and records the tag in a `## Promoted clusters` ledger |
| **Design-docs convention** | a chain repo (routes `writing-specs` / `writing-plans`) whose CLAUDE.md names no single design-docs home, or two competing ones (`specs/` and `docs/specs/`, or `plans/` and `docs/plans/`) | the skills' "where the project keeps design docs" detection then resolves non-deterministically (a coin-flip output path) | name exactly one home per artifact (the `docs/specs/` + `docs/plans/` defaults unless the repo keeps one elsewhere) |

Placeholder-key drift (an unresolved `<key>` token, or a registry example-noun baked into a generator-owned slot) is a separate detection contract — see [placeholder-keys.md](./placeholder-keys.md) § Auditor detection contract.
