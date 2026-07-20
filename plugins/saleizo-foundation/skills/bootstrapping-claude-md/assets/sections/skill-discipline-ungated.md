## Skill discipline

Skills carry domain rules, routed by [skills-routing.json](./skills-routing.json) (trigger keywords → skill body). When a prompt matches a trigger, invoke the `Skill` tool before opening tools that read/edit that domain. Order: Skill first (loads rules), then search-before-ask inside the workflow. Routing here is followed by **discipline, not a gate** — this repo has no bypass-detection or skill-gate hook, so a missed trigger is a self-correction, not a blocked action; treat the routing table as a strong convention.
