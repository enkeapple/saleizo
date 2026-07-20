---
description: Before asserting a relative link or import "resolves", resolve it from the FILE'S READ LOCATION (for a symlinked doc that is the symlink's directory — not the CWD, not the symlink target's directory) and test THAT path; confirming the absolute target file exists does NOT prove the relative link resolves. Under symlink indirection a `./x` link and a real `/abs/x` file can both "check out" while the link is broken. Always-on; triggered by verifying/fixing a link or import, not by a file type.
---

# Link-Resolution Verification

## When

STOP and apply this whenever you assert that a **relative link or import resolves** — a markdown `[text](./path)`, a CLAUDE.md `@import`, a rule cross-link, a config `extends`/`include` — and especially when:

- you are fixing or auditing links in a file that is **consumed via a symlink** (e.g. a vault doc read in another repo as `.claude/CLAUDE.local.md`), where the read-location differs from where the file physically lives;
- you "confirmed the path exists" with `test -f`/`ls` on an **absolute** path;
- several agents/reviewers **concur** that "all links resolve" using the same existence check.

Do NOT skip because `test -f` passed — that check answers a different question than "does this relative link resolve".

## Why

A relative link resolves against the directory of the file **as it is read**, not against the CWD and not against the absolute location of its target. Confirming the absolute target exists proves the target is real; it says nothing about whether the *relative string in the link* points there from the reading file's location. Under a symlink the gap is invisible: the file lives in one tree but is read from another, so the same link can be simultaneously "target exists" and "broken from where it's read".

Reproduced incident: fixing rules links in vault `CLAUDE.local.md` files consumed in real repos as `.claude/CLAUDE.local.md` (symlink → vault). 3 of 4 parallel subagents wrote `./.claude/rules/local/…` and reported "all resolve — confirmed with `test -f`". They had tested the absolute target (`/repo/.claude/rules/local/…`, which exists); but the link resolves from the read-location `.claude/` to `.claude/.claude/rules/…` — a double prefix, broken. The one agent that left the link `./rules/local/…` was right. 14 broken links shipped across 2 files, each "verified". The tell that caught it: `test -e /repo/.claude/.claude/rules/local` MISSING while `/repo/.claude/rules/local` EXISTS.

## Implementation

Before reporting a relative link/import as resolving:

1. **Establish the file's READ location.** For a plain file it is the file's own directory. For a symlinked doc it is the **symlink's** directory (where the consuming tool opens it), not the symlink target's directory and not your shell CWD. When unsure which, find the symlink: `find <consumer-repo> -type l -name '<file>' | xargs ls -l`.
2. **Resolve the link string from that read-location, then test the resolved path** — not the absolute target in isolation. If the file is read from `<repo>/.claude/`, a `./rules/x` link tests as `<repo>/.claude/rules/x`; a `./.claude/rules/x` link tests as `<repo>/.claude/.claude/rules/x`.
3. **A surprising pair is the tell:** if `<readloc>/<double-prefixed>` is MISSING while `<readloc>/<single>` EXISTS, the link is over-prefixed — strip it.
4. **When N agents/reviewers concur, re-verify with a DIFFERENT check.** Concurrence via one shared flawed method is not correctness; resolve-from-read-location once yourself.

```text
# Two-file rule of thumb — the read DIRECTORY drives the prefix (both are plain files here):
✅ repo-root CLAUDE.md   (read from repo root) → link rules as `.claude/rules/…`   e.g. [x](./.claude/rules/<area>/x.md)
✅ .claude/CLAUDE.md     (read from .claude/)  → link rules as `./rules/…`          e.g. [x](./rules/<area>/x.md)   ← NO extra .claude/

# Illustrative INCIDENT (a separate CONSUMER repo, symlink indirection — NOT these two files):
# a vault doc consumed as `.claude/CLAUDE.local.md` (symlink → vault), "verified" by absolute existence:
❌ WRONG — link written in the consumer's `.claude/CLAUDE.local.md`:  [x](./.claude/rules/local/x.md)
   check run:  test -f /repo/.claude/rules/local/x.md   → exists → "resolves" ✗ (tested the wrong path)
   actual resolution from read-location /repo/.claude/:  /repo/.claude/.claude/rules/local/x.md → MISSING → broken
✅ CORRECT — resolve from the read-location:  ./rules/local/x.md → /repo/.claude/rules/local/x.md → exists ✓
```

## Edge Cases

- **When NOT to apply:** an absolute link, or a quick exploratory check you do not report as a verified "resolves". This governs only a relative link/import asserted as resolving.
- **Not the same as `search-scope-verification`** (see-also — a search-mechanics bug giving a false "0 results = absent") nor `usage-claim-verification` (see-also — a conclusion from an aggregate/theoretical proxy). All three are the "the check didn't establish what it claimed" family; this one is specifically **link-resolution-location under symlink/read-location indirection**. Apply each to its own claim.
- **Pure-policy rule** — a charter-class distillate promoted (owner-directed) from one reproduced incident; its evidence is that reproduction, so it carries no single cold RED/GREEN target case (the gate-4 skip in `scoping-rule-value`).

## Review Checklist

- [ ] Every relative link/import asserted to resolve was tested from the file's READ location (symlink's dir for a symlinked doc), not by an absolute-target existence check alone.
- [ ] For a symlinked doc, the symlink was located and its directory used as the read-location.
- [ ] A "missing double-prefixed vs existing single-prefixed" pair was treated as an over-prefix defect and stripped.
- [ ] Where multiple agents concurred "links resolve", the conclusion was re-verified with a different check before being trusted.
