---
description: 'Consumer config for resolving-requirements in this repo — fills the four slots the agnostic skill leaves to the consumer: the ticket-ID prefix set (FLIBCO-, NIN-, …, extensible), the remote spec source (Azure DevOps flibco-specs — one repo for every prefix), how to sync it into /tmp/flibco-specs fresh, and where provenance is recorded. Task-scoped to a resolving-requirements run; no file paths.'
---

# Resolving Requirements — flibco-specs source

## When

The `resolving-requirements` skill is resolving a ticket-ID input in this repo. The skill is agnostic and reads its source specifics from consumer config ("never baked into this skill"). This file IS that config — it does not modify the skill.

## Implementation

Fill the skill's "the configured …" slots with these values:

- **Prefix set / resolve mode** — resolve **iff** the input matches `^(FLIBCO|NIN|RON|SAMI)-\d+$` (a configured prefix + `-` + digits). Anything else (free-text, a pasted URL body) stays **direct**: pass to `grilling` unchanged, no fetch. Add a tracker by extending the alternation (`…|ACME`) and nothing else — every prefix resolves from the one repo below.
- **Remote (single source, every prefix)** — `https://flibco-ci@dev.azure.com/flibco-ci/Flibco%20AI%20Tooling/_git/flibco-specs`. No per-prefix repo, no local-path lookup.
- **Sync fresh into `/tmp/flibco-specs`** (no env vars, no cache): if `/tmp/flibco-specs/.git` exists → `git -C /tmp/flibco-specs pull --rebase --quiet`; else → `git clone --depth=1 '<remote above>' /tmp/flibco-specs`.
- **Locate by the FULL matched ID**, never the bare prefix — `find /tmp/flibco-specs -iname "*<TICKET>*" -print` with the concrete ID (e.g. `*NIN-77*`, `*FLIBCO-1234*`). A match may be a file OR a directory (the "story folder"): read every file of the match verbatim, prefer the fullest match, never let filesystem order choose.
- **Provenance** — record in the SPEC frontmatter so audits trace to the bundle: `source` (absolute path in `/tmp/flibco-specs`), `revision` (HEAD sha), `ticket` (full matched ID), `files` (every file read).

```text
✅ input "NIN-77": sync fresh (pull if /tmp/flibco-specs/.git exists, else clone) →
   find /tmp/flibco-specs -iname "*NIN-77*" -print → hand grilling the verbatim bundle + provenance
❌ inventing/paraphrasing requirements on failure · a local or per-prefix path instead of the one remote
   · searching the bare prefix "*NIN*" instead of "*NIN-77*" · recording no provenance (non-reproducible)
```

On clone/pull failure (auth, network, missing/expired Azure DevOps PAT) or an ID matching nothing, follow the skill's **Failure path**: surface the error verbatim, offer paste-as-text (→ `direct` mode recording `source: free-text fallback (<TICKET>, original error: …)`) or abort; never auto-retry, never invent content.

## Edge Cases

- **Keep it out of the skill.** These values live here in repo-local config, NOT in the agnostic `resolving-requirements` skill (shipped via `saleizo-core`). Hard-coding them — or the prefix list — into the skill is the project-leakage defect this rule prevents.
- **A new prefix that needs a *different* repo** breaks the single-source assumption — then introduce a prefix→source table; never silently point one prefix at a second remote here.

## Review Checklist

- [ ] An `^(FLIBCO|NIN|RON|SAMI)-\d+$` input triggers a fresh clone/pull of the one Azure remote into `/tmp/flibco-specs` (no per-prefix repo, no local path, no cache); a non-matching input stays `direct` — no fetch.
- [ ] `find` uses the full matched ID (`*NIN-77*`), the whole match is read verbatim (every file of a directory bundle), and provenance (`source`/`revision`/`ticket`/`files`) is in the SPEC frontmatter.
- [ ] Clone/find failure surfaces the error verbatim and offers paste-or-abort — no auto-retry, no invented requirements.
- [ ] The agnostic `resolving-requirements` skill was NOT modified; the prefix set lives only here.
