# Plan Reviewer Prompt Template

Use this when dispatching an independent subagent to review a written plan.

**Purpose:** verify the plan is complete, covers the spec, and is decomposed into actionable, buildable tasks before execution starts.

**Dispatch after:** the complete plan is written and saved.

```markdown
Subagent (general-purpose):
  description: "Review plan document"
  prompt: |
    You are a plan reviewer. Verify this plan is complete and ready to execute.
    You did not write it — read it cold, as the engineer who will build from it
    task by task, possibly out of order, with zero context for this codebase.

    **Plan to review:** [PLAN_FILE_PATH]
    **Spec for reference:** [SPEC_FILE_PATH]

    ## What to check

    | Category | What to look for |
    |----------|------------------|
    | Spec coverage | Every spec requirement maps to a task. No major scope creep. |
    | Show-don't-describe | Every code step has real code, not prose ("add validation", "pass the cursor"). Every test is written out, not referenced. |
    | Commands | Each verification step has an exact command + expected output — not "run the tests". |
    | Test-first + commits | Each task writes the test first, runs it to fail, implements, runs to pass, commits. |
    | Interfaces / types | Names and signatures used in later tasks match what earlier tasks produced. No undefined type/function/command. |
    | Task decomposition | Tasks have clear boundaries; each ends with an independently testable deliverable. |
    | Buildability | Could a zero-context engineer follow this without getting stuck or guessing? |

    ## Calibration

    Only flag issues that would make an implementer build the wrong thing,
    get stuck, or guess: a missing spec requirement, a code step with no code,
    an undefined name used in a later task, a contradiction. Minor wording and
    "nice to have" suggestions are not issues. Approve unless there are serious gaps.

    ## Output format

    ## Plan Review

    **Status:** Approved | Issues Found

    **Issues (if any):**
    - [Task X, Step Y]: [specific issue] — [why it blocks implementation]

    **Recommendations (advisory, do not block approval):**
    - [suggestions]
```

**Reviewer returns:** Status, Issues (if any), Recommendations.

If issues are found, fix the plan and re-review — do not start executing a plan with open issues.
