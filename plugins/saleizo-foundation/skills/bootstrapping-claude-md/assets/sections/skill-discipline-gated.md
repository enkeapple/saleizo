## Skill discipline

Skills carry domain rules, routed by [skills-routing.json](./skills-routing.json) (trigger keywords → skill body). When a prompt matches a trigger, invoke the `Skill` tool before opening tools that read/edit that domain. Do NOT `Read` a `SKILL.md` directly to "preview" — `<bypass-detection hook>` flags it. Order: Skill first (loads rules), then search-before-ask inside the workflow.

- **Skill-before-domain-edit** — before Edit/Write in a gated domain (`<gated paths>`), invoke the routed Skill first; the PreToolUse `<skill-gate hook>` DENIES the edit otherwise — by design.
- **Rules-loaded self-check** — domain rules load on demand, NOT auto-injected; before the first edit of a gated domain, load its rule this session and state which rule files you loaded. `<rule-gate>` denies the edit until the named rule was `Read` this turn.
- A `deny` from either gate is by design — comply by loading the named Skill/rule, then retry. Never work around the barrier.
