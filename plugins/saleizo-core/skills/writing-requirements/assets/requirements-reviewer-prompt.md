# Requirements Reviewer — cold subagent prompt

Dispatch a fresh, zero-context subagent to review a requirements doc. Hand it BOTH the original feature request/ticket AND the finished doc — without the source it collapses into a second self-review and cannot judge conformance.

````markdown
Subagent (general-purpose):
  description: "Review a requirements doc against its source request"
  prompt: |
    You review a requirements document. You are given the ORIGINAL request and the
    produced requirements doc. Report defects; do not rewrite the doc.

    **Original request:** [paste the feature request / ticket verbatim]
    **Requirements doc:** [paste the doc, or its path]

    Check each and report every violation with the exact quoted line:

    1. **Implementation / technical leakage** — anything a business reader could not
       read, or any HOW that belongs in a later spec: a code block, a data format
       (JSON/XML/payload), an HTTP status code, transport/protocol jargon (webhook,
       endpoint, API, queue, worker, idempotency key, polling), a database
       schema/columns, hashing/crypto algorithm, library or SDK name, storage layout.
       Requirements are plain-business behaviour only.
    2. **Non-testable ACs** — any acceptance criterion containing "should", "etc.",
       a trailing "…", or phrased as open-ended prose rather than a verifiable statement.
    3. **Missing scope boundary** — In Scope or Out of Scope absent or empty.
    4. **Unflagged assumptions** — any concrete value (expiry, rate limit, threshold,
       size) the original request did NOT state, presented as settled fact instead of
       an Assumption + Open Questions row.
    5. **Conformance to source** — a requirement the source never asked for (scope
       drift), or an asked-for behaviour silently missing.
    6. **Structure** — user story present; ACs split into Success/Failure/Edge and
       numbered continuously; existing names italicised, new names in the Texts table.

    ## Output

    **Verdict:** PASS | FAIL

    **Findings:**
    - [category] — [quoted line] — [why it violates / what to do]

    **Missing from source (asked-for but absent):**
    - [behaviour the request wanted that no AC covers]
````

A FAIL, any implementation leakage, or a missing asked-for behaviour means the doc is not done — fix and re-review before hand-off.
