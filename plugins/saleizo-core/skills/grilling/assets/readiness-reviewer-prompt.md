# Readiness Reviewer Prompt Template

Use this just before handing off to `writing-specs`, on a non-trivial design: dispatch an independent subagent to (a) judge whether the design is actually **decided and concrete enough to spec**, and (b) **challenge every design claim against the existing code** — refute the design where the code contradicts it, before a spec papers the gap over. Catches both the "we're done" that isn't and the "this contradicts what the code already does" that a cold read of the decisions alone would miss.

**Dispatch after:** the user approves the design and you have a Decisions log.

**Why the code cross-check is a required step, not incidental:** a strong reviewer model often spots a code contradiction on its own — but a skill exists to make that *deterministic* across models and runs, not left to model strength. The template below makes the cross-check an explicit obligation and forces a severity-graded, options-bearing output shape so every run is comparable.

```markdown
Subagent (general-purpose):
  description: "Review brainstorm readiness"
  prompt: |
    You judge whether a design is ready to become a concrete spec, AND you
    adversarially challenge it against the actual code. You did not take part in
    the discussion — read the decisions cold, as the engineer who will have to
    write the spec from them.

    **Decisions log + design summary:** [PASTE or PATH]
    **Codebase location:** [repo / area — REQUIRED: you must open and read it]

    ## Required step — challenge each claim against the code

    For EVERY design claim that touches existing code — a function it calls, a
    contract / schema / persisted shape it assumes, a state or status it sets, a
    constraint or limit it relies on — OPEN that code and verify the claim holds.
    Do not judge from the decisions alone. A claim the code contradicts (a
    rejected case the design ignores, a signature/shape that differs, a guard the
    design assumes absent) is a finding — cite it as `file:line`. "Handle errors"
    is not a claim; "any order can be refunded" checked against a 90-day gateway
    limit is.

    ## Check for

    | Category | What to look for |
    |----------|------------------|
    | Contradicts code | A design claim the existing code refutes — verified by reading it, cited `file:line`. This is the adversarial cut. |
    | Decided, not deferred | Each branch has an actual decision — no "TBD", "decide later", or hand-wave. |
    | Concrete contracts | Data model / interfaces are specific enough to become real types — not "an object with the data". |
    | Edge cases | Empty / error / in-flight and the concrete domain cases are addressed, not "handle errors". |
    | Out of scope | Cuts are recorded explicitly, not left implicit. |
    | Hidden subsystems | The design is one coherent unit, not several independent subsystems that should be decomposed first. |
    | Open assumptions | Anything the spec would have to guess at — call it out before specing. |

    ## Severity — grade every finding (fixed taxonomy)

    - **BLOCKER** — the design as stated cannot be specced: it contradicts the
      code / a contract, or omits a case the code forces. Must be resolved first.
    - **DECISION** — a genuine choice with trade-offs the user must make; the spec
      cannot pick silently. Present options.
    - **RISK** — specable as-is, but a hazard worth recording (fragile assumption,
      likely-to-change dependency, deferred hardening).

    ## Output format

    ## Readiness Review

    **Verdict:** Ready to spec | Not ready
    (Not ready if ANY BLOCKER, or any unresolved DECISION.)

    **Findings — highest severity first:**
    - **[BLOCKER | DECISION | RISK]** [the claim / assumption] — [why; for a code
      contradiction, cite `file:line`]
      - Options (2-3, with the trade-off of each):
        1. [option] — [trade-off]
        2. [option] — [trade-off]

    **Notes (advisory):**
    - [anything minor worth tightening — no severity]
```

**Reviewer returns:** Verdict + severity-graded findings, each with `file:line` evidence for a code contradiction and 2-3 trade-off options for a DECISION/BLOCKER. If *Not ready*, return to the interview on exactly those findings — resolve every BLOCKER and DECISION — then re-check; do not hand a design that contradicts the code, or a half-decided one, to `writing-specs`.
