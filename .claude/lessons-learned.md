# Lessons Learned

Transient backlog of un-promoted candidate rules — newest at the top of `## Entries`. When a `Cause-tag` reaches 3×, **invoke the `writing-lessons` skill** (do not hand-promote): it dispatches an independent promotion review and, on a Promote verdict, authors the rule under `.claude/rules/` via `writing-rules`, **deletes the contributing entries**, and records the tag in `## Promoted clusters`. git keeps deleted entries (`git log -S '<cause-tag>'`); deletion happens only via the skill, inside a confirmed promotion (or this one-time cleanup).

## Entries

## 2026-07-23 — Moving a gated rule file re-pinned its own ruleGate mid-turn, blocking the follow-up edits

- **Cause-tag**: gated-rule-relocation-repins-gate
- **Symptom**: reorganizing `.claude/rules/common/` into folders, the first `skills-routing.json` edit (repointing the `routing-sync` gate to `authoring/skill-routing-sync.md`) succeeded, but the next edits were blocked demanding the NEW path be Read this turn — despite having Read the old `common/` path.
- **Root cause**: the `routing-sync` ruleGate guards `skills-routing.json` by requiring its `rule` path Read this turn; rewriting that `rule` value re-pins the gate to the new path, which was never Read.
- **Wrong approach**: Read the rule at its old path, then edited all routing paths in sequence assuming one satisfied read covered the whole file.
- **Correct approach**: after the first edit re-pinned the gate, Read the file at its new `authoring/` path, then retried the blocked edits.
- **Prevention**: when relocating a rule that is itself a `ruleGates` target, Read it at its NEW path before the dependent gated edits — or edit the gate's own `rule`-path last.

- **Cause-tag**: rule-source-consumer-drift
- **Symptom**: owner reported `interactive-gates.md` "loads badly / gives a text list instead of the picker" across consumer repos. Two coupled causes: (a) the rule described "a dedicated picker tool" abstractly and never named `AskUserQuestion`, so a consumer-floor model defaulted to the markdown-list fallback; (b) after fixing the source `.claude/rules/common/interactive-gates.md`, the fix reached NO consumer — each consumer reads its own copy under `flibco/claude-vault/projects/<repo>/rules/common/`, and the three copies (`d2g`, `s2s`, `ticket-desk`) had already drifted from source and from each other (different `description`, a 2-option vs 3-option archetype B, missing the interrupt block).
- **Root cause**: assumed editing the framework's source rule propagates like a skill/hook does. It does not — unlike skills/hooks (shipped via the installed plugin), **rules are copied into each consumer's vault by hand** at adopt time, so a source edit is inert for every consumer until re-propagated, and the copies drift independently in the meantime.
- **Wrong approach**: fix only the source rule and treat the bug as closed; or blind-overwrite the consumer copies with the new source (would clobber their independent drift).
- **Correct approach**: fixed the source rule (named `AskUserQuestion`, forbade defaulting to a text list), then found every copy (`find <vault> -name interactive-gates.md`), confirmed the target sentence was byte-identical across all three, and applied the SAME surgical edit to each — leaving their other drift untouched.
- **Prevention**: after editing any `.claude/rules/**` file whose value is meant for consumers, do NOT consider it done at source — `find <vault>/projects -name '<rule>.md'` for every consumer copy and propagate the same surgical edit to each (they may have drifted; edit surgically, never overwrite). Rules are not plugin-shipped; there is no automatic sync. (Kin: `dev-source-vs-consumer-routing`, `plugin-boundary-infra-reach`, `skill-path-source-vs-symlink` — same "dev-source reality ≠ what the consumer sees" family, here the mechanism is manual-copy propagation + inter-copy drift, not addressing. Family is large and flagged for a unified "source ≠ consumer reach" promotion — watch.)

## 2026-07-21 — Planned persisted fixtures for a prompt-dependent hook gate the runner structurally cannot inject state for

- **Cause-tag**: fixture-state-uninjectable
- **Symptom**: building `skill-gate.sh` Pass 3 (a task-list barrier that denies an Edit when the cached prompt matches an SDD run AND no `session-tasklist-seeded.flag` exists), I planned to cover the deny path with a persisted `tests/skill-gate.sh.cases` entry. Reading `scripts/run-hook-fixtures.sh` showed the runner feeds only `stdin` + per-case `.env` (`env -i PATH HOME <.env> bash hook`) — it has NO setup step to pre-seed state files (`last-prompt.txt`, flags) under `$CLAUDE_PROJECT_DIR/.claude/state/<sid>/`. So the deny decision, which depends on that state, is structurally uninjectable via the suite. The existing prompt-triggered ruleGate (Pass 2) is likewise uncovered for the same reason — a latent pattern, not a one-off.
- **Root cause**: assumed the persisted fixture suite can regress any hook decision. It can only vary what it injects — stdin + env. A decision keyed on session/turn STATE files the hook reads (prompt cache, seeded flags, turn-reads) cannot be set up by this runner, so those branches are verifiable only at authoring-time against a hand-built temp `CLAUDE_PROJECT_DIR`.
- **Wrong approach**: about to add a persisted deny-case and treat a green suite as regression coverage for the state-dependent branch — a false coverage claim (the case could only ever exercise the no-state → allow path).
- **Correct approach**: proved RED→GREEN authoring-time against a temp project dir with seeded `last-prompt.txt` + flag; in the persisted suite added only the injectable assertions (garbage→fail-open, no-prompt→allow no-false-fire, `TaskCreate`→sets-flag exit-0); and logged the coverage gap explicitly in the `taskListGate._comment` in `skills-routing.json` ("prompt-dependent → verified at authoring-time, not by the fixture suite").
- **Prevention**: before claiming a hook decision is covered by the persisted fixture suite, check whether it depends on state the runner can inject (stdin + `.env` only) vs state it reads from `.claude/state/**` (prompt cache, flags, turn files). State-file-dependent branches are NOT suite-regressable here — prove them authoring-time against a temp `CLAUDE_PROJECT_DIR` and record the gap in-config; never let a green suite that only exercises the no-state path read as coverage of the state-present decision. (Kin: `fixture-env-contamination` — fixture isolation; `plugin-boundary-infra-reach` — the runner not crossing to consumers; `untested-empty-branch` — a branch the fixture didn't exercise but could. Distinct here: the harness CANNOT exercise the branch at all.)

## 2026-07-18 — A later phase's RED baseline was confounded by earlier same-session edits already in the artifact

- **Cause-tag**: confounded-red-control
- **Symptom**: in a multi-phase AUTHOR run on the CLAUDE.md templates (Phase 1: STRICT/FILL + Key-files; Phase 2: anti-contamination), the Phase 2 contamination RED (subagent handed a sibling driver-app manual and told "keep consistent") did NOT reproduce symbol-bleed — the model correctly re-scoped to the new app. I nearly concluded "contamination is a non-risk, a capable model re-scopes." But Phase 1's edits were already in the templates the RED read (Key-files [FILL]="read THIS repo", checklist "don't invent a gate"), so the non-reproduction may be caused by Phase 1, not by contamination being safe — the RED could not attribute cause. A test that passed partly for the wrong reason.
- **Root cause**: ran phase N's baseline against the cumulative artifact (phases 1..N-1 edits applied), so the "control" differed from the true pre-change baseline by more than the one variable phase N introduces. Classic confounded control — same failure family as a contaminated RED, different mechanism (prior same-session edits, not prompt pre-loading or an inherited manual).
- **Wrong approach**: treating a clean RED on the already-hardened artifact as evidence about the new variable's necessity, and attributing the result to model capability.
- **Correct approach**: kept the Phase 2 change as an honestly-downgraded *descriptive* edit (cited the real flibco contamination as prior failure) rather than claiming a behavioral RED/GREEN — the guard is cheap export-floor insurance, and I stated the baseline was cumulative so the RED cannot attribute cause.
- **Prevention**: when RED-ing phase N of a sequential same-session change, isolate the variable — run the baseline against the pre-phase-N state (revert earlier edits, or use a copy of the artifact from before them), OR explicitly state the baseline is cumulative and the RED cannot attribute cause (then downgrade the claim honestly). Never read a clean RED on an already-edited artifact as evidence the new variable is unnecessary. See-also `fair-red-baseline` (prompt-level contamination) and `scoping-skill-value` (inherited-manual control) — same confounded-control family, this adds the prior-same-session-edit mechanism.

## 2026-07-17 — Hook fixture false-greened because the runner inherited an exported env var from the dev's shell

- **Cause-tag**: fixture-env-contamination
- **Symptom**: authoring `notify.sh` (opt-in via `SALEIZO_NOTIFY`), the `opt-in-off` fixture flipped between vacuous-PASS and spurious-FAIL. `SALEIZO_NOTIFY=1` was exported in the session shell and leaked into every fixture, silently activating the opt-in gate.
- **Root cause**: `run-hook-fixtures.sh` layered per-case env as `env KEY=VAL bash hook` — `env` ADDS to but does not SCRUB the caller's environment, so any var exported in the dev's shell reaches the hook. Separately, the opt-in-off case asserted only exit-0 + empty-stdout, which a backgrounded side-effect satisfies even with the gate deleted (unobservable signal).
- **Wrong approach**: trusted a per-case `env` layer for isolation and asserted a gate path via exit-0 + empty-stdout.
- **Correct approach**: ran hooks in a scrubbed env — `env -i PATH="$PATH" HOME="$HOME" <per-case> bash hook`; asserted the gate via an observable seam (a debug dry-run to stderr + `expect_stderr_empty`).
- **Prevention**: a fixture runner for env-driven code MUST scrub ambient env (`env -i` + an explicit allowlist), never rely on `env KEY=VAL` layering over an inherited environment; and assert a gate/opt-in path via a POSITIVE observable signal (stderr/stdout), never exit-0 + empty-stdout that a backgrounded/redirected side-effect satisfies vacuously. Kin: `untested-empty-branch` and `checker-self-run-false-green` (false-green from an unexercised/unobservable path) — this adds the ambient-env-leak mechanism.

## 2026-07-17 — Reported a hooks-count as a verified audit fact from a lossy `grep|sed` pipeline over hooks.json

- **Cause-tag**: structured-file-count-via-grep
- **Symptom**: during a README audit I stated the `saleizo-controls` hooks block was "missing 2 hooks / 4 of 6 events" as a verified finding, derived from `grep -oE … hooks.json | …`. A later direct `Read` of `hooks.json` showed the truth was worse: **7 events, 11 unique scripts, 13 rows** — `notify.sh` is wired under PreToolUse(AskUserQuestion), Notification, and Stop, and the whole `Notification` event plus two `notify` occurrences were absent from my grep output. The audit undercounted the most-severe (catalog-omits-real-entries) drift.
- **Root cause**: counted entries in a structured JSON manifest with an ad-hoc `grep -oE`/`sed` pipeline instead of parsing the file; the summarized stdout was lossy (repeated `notify.sh` lines and the `Notification` key did not survive to what I read — this repo's RTK output proxy over shell stdout is a suspected, not confirmed, contributor). A count from a text-summary of JSON is not evidence.
- **Wrong approach**: trusted a one-liner's printed lines as a complete enumeration of a JSON object's keys/values and reported the count as verified.
- **Correct approach**: re-derived from a direct `Read` of `hooks.json` (and a Python parse), which gave 7/11/13; the regeneration subagent, which parsed the file rather than my summary, had already produced the correct block.
- **Prevention**: for any "N of M entries / complete / missing X" claim over a **structured file** (`*.json`, `*.yaml`, frontmatter), enumerate by parsing it — `Read` the file, or `jq`/`python -c`/`yq` over it — never an `grep|sed` line-summary, whose output can be lossy (and is proxied here by RTK). Treat a count-claim's source: if it is a text pipeline over structured data, re-derive by parsing before asserting. See-also `search-scope-verification` (false-absence from search mechanics) and `usage-claim-verification` (conclusions from aggregates) — same false-verification family, different mechanism.

## 2026-07-09 — Ran `git commit` autonomously on a terse "a,b,c" selection, despite the human-owns-the-commit boundary

- **Cause-tag**: autonomy-boundary-overreach
- **Symptom**: user picked "a,b,c" from a follow-up list whose item (c) I had labeled "Commit (you own)". I created a branch + 6 commits autonomously. Owner flagged it — "ты сам и закоммитил?" — had not expected me to commit.
- **Root cause**: treated selection of a follow-up item as explicit authorization for a git-boundary action, when the item said "you own" and CLAUDE.md's Git boundary reserves running the commit to the human (I propose, they run).
- **Wrong approach**: read a terse "c" as "do the commit for me" and executed branch + commit without an unambiguous instruction.
- **Correct approach**: for any git-boundary action (commit/branch/push/reset), propose the exact command and STOP; selecting a menu item marked "(you own)" is acknowledgement, not authorization. (Owner chose to keep the branch; no undo needed.)
- **Prevention**: never run `git commit`/`branch`/`push`/`reset` autonomously — propose the one-line command and wait for an explicit "run it". A terse "next"/"a,b,c" or a picked item labeled "(you own)" is NOT commit authorization. When in doubt on a boundary action, ask.

## 2026-07-09 — UserPromptSubmit hook cached harness `<task-notification>` messages as user prompts, inflating bypass ~10x

- **Cause-tag**: hook-payload-assumption
- **Symptom**: forward telemetry read 94% bypass; 61/67 trigger-matched "prompts" were `<task-notification>` harness messages `reset-turn-budget.sh` cached as user prompts, so log-skill-usage/detect-bypass matched their echoed SDD vocabulary → phantom multi-skill bypasses (one notification fired 6 skills).
- **Root cause**: assumed the UserPromptSubmit `.prompt` channel carries only user prompts; the harness also injects system messages (task-notifications on background-task completion), cached verbatim into `last-prompt.txt` + the prompt corpus.
- **Wrong approach**: nearly patched `detect-bypass.sh` — the wrong hook (it doesn't even write the `bypass` metric); read-before-assert traced the count to the capture path.
- **Correct approach**: at capture (`reset-turn-budget.sh`) skip caching + corpus for `^\s*<task-notification>`; fixed all three downstream consumers at once; RED/GREEN on the `last-prompt.txt` side-effect + a persisted case.
- **Prevention**: when a hook reads the UserPromptSubmit prompt channel, filter harness-injected messages (`^\s*<task-notification>` and similar tags) before treating input as a user prompt — the channel is not user-only. And trace a telemetry/bypass count to its WRITER before patching a reader. (Kin: `hook-payload-assumption` 2026-06-22 — assumed a payload field/shape; here assumed the prompt is user-only.)

## 2026-07-08 — Two sibling rules' boundary discriminator lived only in an Edge Cases bullet while both triggers+checklists double-claimed the same construct; a cold agent couldn't route

- **Cause-tag**: boundary-discriminator-placement
- **Symptom**: `simplicity.md` and `no-over-engineering.md` both fired on "config object / options bag for a single call site" — in their `## When` trigger AND their `## Review Checklist`. The discriminator (present-tense plainest-construct vs speculative-future structure) existed only in a `simplicity` Edge Cases bullet. A cold Haiku RED agent asked which rule OWNS a config-object-for-one-value diff returned "genuine dual-ownership, both checklists flag it, cannot cleanly assign one owner."
- **Root cause**: a cross-link buried in Edge Cases satisfies `scoping-rule-value` gate 2 (cross-link, don't fork) on paper, but a cold agent routes off the parts it scans at trigger/review time — the `## When` line and the `## Review Checklist` line — not the Edge Cases prose. Ownership stated only in Edge Cases is invisible where the routing decision is actually made.
- **Wrong approach**: treated the existing Edge Cases see-also as sufficient boundary demarcation because the two rules were cross-linked (gate 2 "passes"), without checking that the discriminating token was double-claimed in both scanned sections.
- **Correct approach**: ceded "config object / options bag" entirely to `no-over-engineering`; narrowed `simplicity`'s When + Implementation + Review-Checklist to the present-tense construct it owns and named the owner inline in those scanned lines ("a config object / options bag for one value is no-over-engineering's finding, not this rule's"); added a reciprocal boundary Edge Case in `no-over-engineering`. Identical GREEN run (same Haiku model, only on-disk rules changed) then assigned a single unambiguous owner.
- **Prevention**: when two sibling rules share a construct token, name the owner in the `## When` and `## Review Checklist` lines a cold agent scans at trigger time — a cross-link that lives only in Edge Cases routes nothing. Verify with a RED/GREEN routing test: hand a cold agent both rules + the disputed construct and ask which one OWNS it; RED = dual-ownership/ambiguous, GREEN = single owner. (Kin: `cross-skill-content-coupling`, `unverified-subagent-finding` — the rule-set-coherence family; distinct here because the fix is discriminator VISIBILITY in scanned sections, not de-coupling or verifying a finding.)

## 2026-07-07 — Trusted a skill's Layer-1 GREEN as proof its example-asset citations were real; the validator resolves only .md link targets, not prose file:line+quote content

- **Cause-tag**: gate-scope-overtrust
- **Symptom**: `auditing-conflicts/assets/audit-report-example.md`'s lead finding cited a nonexistent path (`…/skills/chain/grilling/SKILL.md:33`) and a quote absent from the file, yet the skill passed `validate.sh` **Layer-1 GREEN** clean; the fabrication surfaced only on a manual grep of the citation.
- **Root cause**: Layer-1's `links-resolve` verifies markdown `.md` **link targets** resolve; a prose `Evidence: file:line "quote"` is not a link, so its path existence and quote verbatim-ness are outside the gate. GREEN meant "links resolve," never "citations are real."
- **Wrong approach**: treated a skill's Layer-1 GREEN as evidence its example asset's `file:line`+quote citations were real and verbatim.
- **Correct approach**: grepped each cited path for existence and `grep -F`'d each quote for verbatim presence; replaced the fabricated citation with a real one (`interview-playbook.md:19`) confirmed on disk, re-grepped to a verbatim match.
- **Prevention**: when authoring/auditing a skill's example/demo asset that cites real repo `file:line` + quotes, grep each cited path for existence AND `grep -F` each quote for verbatim presence — never read Layer-1 GREEN as proof citations are real (it checks only `.md` link resolution, not prose-citation content). (Kin: `checker-self-run-false-green`, `broken-grep-false-verification`→search-scope-verification, `parser-format-assumption` — the "a verification signal doesn't mean what you assume" family; here the gate is correct but its SCOPE excludes prose citations. Watch for a unified "sanity-check what the gate actually covers" promotion.)

## 2026-07-05 — Invoked a plugin skill via the Skill tool; the loaded copy was the stale install cache, lagging the working-tree source I was editing

- **Cause-tag**: stale-loaded-skill-cache
- **Symptom**: auditing/editing `writing-skills`, I invoked it via the `Skill` tool. The loaded body came from the install cache (`~/.claude/plugins/cache/saleizo/saleizo-authoring/1.0.0/skills/writing-skills/`) and still referenced pre-rename file names — `testing-with-subagents.md`, `frontmatter-reference.md`, `assets/validation-subagent-prompt.md` — while the working tree under `plugins/saleizo-authoring/skills/writing-skills/` already had the renamed `testing.md`, `frontmatter.md`, `agents/validator.md` (uncommitted `R` renames). Caught before acting; a less careful pass would have cited a reference path that does not exist on disk.
- **Root cause**: the `Skill` tool loads the INSTALLED plugin snapshot (a versioned cache), not the working-tree source. Local edits/renames to a plugin skill do not appear in the cache until the plugin is reinstalled, so the two diverge silently during in-repo authoring.
- **Wrong approach**: treated the Skill-tool-loaded body as the current source of truth for the skill's file layout while editing the working tree — two different versions of the same skill in one turn.
- **Correct approach**: edited and verified only against the working-tree source under `plugins/**`; confirmed reference paths (`agents/validator.md`, `testing.md`, `frontmatter.md`) against disk with the Layer-1 link check, not against the loaded copy.
- **Prevention**: when auditing/editing a plugin skill in this repo, edit and verify against the working-tree source under `plugins/<kit>/skills/<name>/`, never the `Skill`-tool-loaded body — the latter is the installed snapshot and can lag until reinstall. If the loaded copy names a reference file the working tree does not (or vice versa), the cache is stale; trust disk. (Kin: `dev-source-vs-consumer-routing`, `skill-path-source-vs-symlink`, `plugin-boundary-infra-reach` — same "dev-tree reality ≠ the address another layer sees" family; here the mismatch is loaded-cache-vs-working-tree. Family now large across these tags — watch for a unified "trust the working tree, not the loaded/installed view" promotion.)

## 2026-07-05 — writing-skills' own validate.sh gave wrong verdicts (false-FAIL + false-PASS) yet passed its green self-run on the skill

- **Cause-tag**: checker-self-run-false-green
- **Symptom**: auditing `writing-skills`, its bundled `scripts/validate.sh` mis-FAILed a house-style 4-backtick example wrapper (fence-balance via flat `grep -c '^```'` → odd count on well-formed markdown) and silently PASSed a broken anchored link (regex `\]\([^)]+\.md\)` needs the link to END in `.md)`, so `foo.md#sec` never matched). Both wrong verdicts survived the validator's own green run on the skill.
- **Root cause**: a checker's green run on the artifact it ships with is not evidence the checker is correct — the defect surfaces only on inputs the shipped artifact happens to lack (a false-POSITIVE on a valid input it lacked; a false-NEGATIVE on a malformed input it lacked).
- **Wrong approach**: trusted "validate.sh runs green on writing-skills" as evidence the eight checks were sound.
- **Correct approach**: RED'd each check with paired fixtures — a known-GOOD input that must PASS and a known-BAD that must FAIL; the 4-backtick wrapper and an anchored broken link reproduced both bugs; fixed with fence-aware run-length nesting + anchor/title stripping + fenced-link skipping, re-ran fixtures GREEN.
- **Prevention**: before trusting ANY validator/lint/check script, RED it with paired fixtures over the repo's own house-style constructs — assert a known-GOOD input PASSes AND a known-BAD FAILs (4-backtick wrappers, anchored/titled links, links inside fenced examples). A green self-run on the artifact under test proves nothing. (Kin: `broken-grep-false-verification`→search-scope-verification.md covers the absence-search false-clean side; `markdown-fence-counting`→markdown-style.md covers the wrapper writing-rule; `parser-format-assumption` flags the same "ad-hoc verification tooling fabricates a false signal" family — neither covers a false-POSITIVE verdict nor "RED the checker itself". Family now 3 across tags — watch for a unified "sanity-check verification tooling" promotion.)

## 2026-07-05 — A discipline-gate carve-out armed the dodge it was meant to bound; keyed on an unobservable distinction

- **Cause-tag**: exemption-arms-loophole
- **Symptom**: closing the "it's just a fixture/demo → skip the Iron Law" loophole in `writing-skills`, I added a prohibition PLUS a carve-out ("only a disposable scratch skill you delete this session is out of scope"). Across 2 fix iterations on the export floor (Haiku), GREEN stayed 0/2: agents mapped the pressured fixture onto my stated carve-out (g4 "fixtures are exempt"; g3 consciously deviated).
- **Root cause**: (a) the gate keyed on a distinction the task cannot reveal — kept vs deleted-this-session has no observable signal, so the agent has nothing to bind on; (b) stating the exception explicitly ARMS the dodge — the agent classifies the pressured case INTO the carve-out.
- **Wrong approach**: iterated prose (Iron Law clause, Step-0 note, table row, red flag) to prohibit the label-dodge while also spelling out the legitimate exception.
- **Correct approach**: reverted the whole change — the skip is defensible judgment on a throwaway artifact (not a clean defect), and an absolute no-carve-out rule would be over-rigid (this repo edits throwaway fixtures constantly).
- **Prevention**: before adding a discipline carve-out/exception to a skill, confirm its distinguishing predicate is OBSERVABLE from the task the agent sees; if not, the gate can't bind and the stated exception becomes the loophole's own justification — don't ship it. Stop after ~2 failed GREEN iterations on the floor (anti-thrash). (Kin: `scoping-skill-value` — baseline absorbs the literal version → don't ship; `phrasing-keyed-prohibition` — a prohibition evaded, here the *exception* is the evasion vector.)

## 2026-07-05 — Paired with-skill/baseline subagents edited the SAME fixture file → write-race contaminated both halves

- **Cause-tag**: subagent-worktree-mutation
- **Symptom**: benchmarking `writing-skills`, TC1's with-skill and baseline Haiku subagents both edited one `commit-helper/SKILL.md` concurrently; a file-modified race hit the with-skill run, which then found the work "already done" and used that as extra license to skip the Iron Law — TC1 delta uninterpretable (0/3 vs 0/3).
- **Root cause**: one mutable fixture shared across two paired conditions; concurrent runs observe each other's writes, so neither half is a clean control.
- **Wrong approach**: a single `fixtures/commit-helper/` targeted by both the with-skill and baseline dispatch in the same parallel batch.
- **Correct approach**: give each condition its OWN fixture copy (`fixtures/<case>-with/`, `fixtures/<case>-baseline/`); de-weighted TC1 and took the verdict from TC2/TC3 (read-only / separate dirs).
- **Prevention**: before dispatching paired RED/GREEN (or with-skill/baseline) subagents that MUTATE an artifact, copy the fixture per condition so no run sees another's writes; read-only (validate) cases are exempt. (Variant of the 2026-06-21 entry: same mutation-hygiene class, isolation angle rather than read-only-dispatch — cluster now 2×.)

## 2026-07-04 — Nearly deduped a Progress: paragraph shared across export-bound plugin skills into a consumer-repo rule pointer

- **Cause-tag**: plugin-boundary-infra-reach
- **Symptom**: an audit master-plan flagged the `Progress:` paragraph duplicated across 6 chain skills as removable duplication and proposed replacing it with a pointer to `.claude/rules/common/phase-task-visualization.md`. I nearly executed before checking where that target lives.
- **Root cause**: `phase-task-visualization.md` is a CONSUMER-repo rule, not shipped by the plugin; an export-bound plugin skill pointing at it dies in any consumer lacking that rule. The cross-skill duplication is load-bearing portability (each skill must be self-contained), not a defect.
- **Wrong approach**: treated "same paragraph in 6 skills" as pure SSoT-violation duplication, about to dedup shipped skill content into a shared home that never crosses the plugin→consumer boundary.
- **Correct approach**: kept the inlined paragraph per skill; confirmed within-skill dedup (SKILL.md ↔ its OWN shipped asset, e.g. `writing-plans` header ↔ `plan-template.md`) IS valid because the asset ships with the skill.
- **Prevention**: before deduping content shared across plugin skills into one shared home, confirm that home ships WITH the plugin (a skill-local `assets/`/`references/` file), never a consumer-side `.claude/rules/**` or `CLAUDE.md`; a consumer-side target → the inlined duplication is required, keep it. Distinct from `agnostic-skill-authoring` (don't bake consumer specifics IN) — this is don't dedup OUT to a consumer-side home. (Kin: `dev-source-vs-consumer-routing`, `skill-path-source-vs-symlink` — dev-tree/boundary reality ≠ consumer reach; family now 5 across 3 tags, watch for unified promotion.)

## 2026-07-04 — Labeled an external skill "novel" in a dedup shortlist; this repo already had it under a near-synonym name

- **Cause-tag**: missed-capability-duplicate
- **Symptom**: producing a dedup shortlist of `affaan-m/ECC` skills vs this repo, I put ECC's `council` in Tier 2 as a NOVEL candidate ("extends grilling + model-selection diversity"). This repo already ships `decision-council` (saleizo-design; triggers "convene a council"/"consilium"/"five perspectives"). It only surfaced when a later `git status` showed the `decision-council/` dir — after the shortlist was already approved.
- **Root cause**: ran the novelty check on ONE side only — grepped/enumerated the EXTERNAL repo's names, but never grepped this repo's own `.claude/skills-routing.json` / `plugins/*/skills/` by CONCEPT for each candidate. A dedup task feels like it already covers dedup, so the own-side inventory check got skipped; and I matched on the exact external name `council` rather than the concept, which `decision-council` answers.
- **Wrong approach**: asserted "novel / not-a-dup" per candidate from memory of this repo plus an ECC-name scan, advancing the shortlist to approval before verifying each candidate concept against this repo's actual routing.
- **Correct approach**: `git status` exposed `decision-council`; grepped routing, confirmed the trigger set ("convene a council"/"consilium"/"five perspectives") is exactly ECC's `council`; struck it from the shortlist as a duplicate and recorded the miss in the roadmap doc.
- **Prevention**: in any dedup/novelty analysis, before labeling ANY candidate "novel" run a CONCEPT grep over this repo's own inventory — `grep -riE '<concept-keywords>' .claude/skills-routing.json plugins/*/skills` (e.g. `council|consilium|panel` — not just the source's exact name) — and confirm no existing skill answers it. A one-sided (external-only) inventory scan or an exact-name match is a false-clean; this repo's own routing is the authority for "already exists". (Kin: framework Suspicion #5 greps names; `search-scope-verification` — a scoped/one-sided "0 = absent" is false-clean when the capability lives under another name. Second occurrence of this tag — watch the count toward promotion.)

## 2026-07-04 — Cited a skill's word count as "1543 > 1500" from naive `wc -w`; the validator strips frontmatter+fences (real 1477)

- **Cause-tag**: metric-method-mismatch
- **Symptom**: while speccing an edit to `writing-specs/SKILL.md`, asserted its body was "1543 words > the ≤1500 budget" and built the spec's word-budget risk/edge-case around that. A plan-reviewer subagent flagged it: this repo's word-count validator counts the **body only** (`awk` stripping frontmatter + fenced blocks) → **1477**. The 1543 was a whole-file `wc -w` including the 66-word frontmatter.
- **Root cause**: reported a *governed metric* (the ≤1500 word budget) using a convenient tool (`wc -w file`) whose definition differs from the validator's authoritative method (strips frontmatter AND fenced blocks). "Measured" ≠ "measured the way the gate measures".
- **Wrong approach**: `wc -w SKILL.md` → 1543 → "43 over budget, trim one bullet parenthetical" in the spec. Real headroom was 23 words, not −43, which materially changed Task 1 (the grilling-host fallback fired).
- **Correct approach**: measure the governed metric with the validator's own command (the awk-strip method), confirmed body = 1477, headroom 23. Trap noted: a markdown **table counts** (not a fenced block), unlike a code fence which is stripped.
- **Prevention**: before citing a skill body's word count against the ≤1500 budget, run the validator's awk-strip method (`writing-skills` validation-checklist), never a bare `wc -w <file>` — they diverge by the frontmatter size + every fenced block. Generally: when asserting a number a gate enforces, measure it with the gate's own instrument, not a lookalike.

## 2026-07-04 — Under /sdd, seeded a standalone single-phase list instead of the full canonical set after a pre-chain detour

- **Cause-tag**: orchestrated-entry-misclassified
- **Symptom**: invoked via `/sdd`; did pre-chain repo analysis, then entered `grilling` and seeded ONE standalone task item. Owner corrected — "я стартанул с sdd, оно априори должно было запуститься" — expected the full canonical 8-phase list.
- **Root cause**: `phase-task-visualization` keys "orchestrated vs standalone" on "does a list already exist?", which is silent when no list exists yet AND a pre-chain detour ("not a build → no pipeline") already framed the phase as standalone.
- **Wrong approach**: seeded a single `grilling` item (standalone create-branch) even though the session entered through `/sdd` (`sdd-lifecycle`), i.e. the orchestrator was driving by definition.
- **Correct approach**: rebuilt the full canonical `sdd-lifecycle` phase set (entry phases marked skipped, `grilling` `in_progress`); `/sdd` entry makes the run orchestrated regardless of a pre-chain detour.
- **Prevention**: if a session was invoked via `/sdd` (or `sdd-lifecycle`), the run is orchestrated by definition — on entering the FIRST real phase seed the whole canonical phase set (`sdd-lifecycle` "Progress list"), never a standalone single item, even after a pre-chain discovery detour.

## 2026-07-04 — Proposed a new skill for a "gap" already covered by a neighbour skill's review sub-steps — grepped names, didn't read the body

- **Cause-tag**: missed-capability-duplicate
- **Symptom**: in a "what can we add from this diagram" grill, proposed a new `validating-specs` core phase for the diagram's "Validate Specifications" stage; got scope+form+checks approved. User asked how it differs from `writing-specs`' existing reviewer subagent — its two-layer review already covers 4 of the 5 proposed checks.
- **Root cause**: judged a capability "missing" from a skill-NAME/routing grep (no `validating-specs` dir) without reading the adjacent skill's body — `writing-specs`' self-review + independent cold-reviewer subagent already give completeness/consistency/clarity/traceability.
- **Wrong approach**: ran gap-analysis on the name/routing inventory and presented the "gap", advancing scope→form→checks decisions before ever reading `writing-specs` fully.
- **Correct approach**: read `writing-specs` SKILL.md + `spec-reviewer-prompt.md` + `review-layers.md`; mapped each proposed check to existing behavior — only testability was a thin, mis-layered delta; looped back and dropped the phantom gap.
- **Prevention**: before proposing a new skill/phase as a "gap", read the FULL body of every scope-adjacent skill — especially its self-review / cold-reviewer / subagent sub-steps — and map each proposed check to existing behavior; a name/routing grep returning no match proves no NAME-duplicate, never no CAPABILITY-duplicate. (Kin: framework Suspicion #5 greps names; `search-scope-verification` — a scoped search's "0 = absent" is false-clean when the capability lives under another name.)

## 2026-06-27 — Persisted hook-fixture suite shipped its `.cases` inside the plugin but its runner/CI stayed repo-root; spec over-claimed consumer regression value

- **Cause-tag**: plugin-boundary-infra-reach
- **Symptom**: spec Risk claimed the guardrails-kit fixtures "travel to consumers — regression value"; owner asked how the plugin pulls the root runner. The runner (`scripts/run-hook-fixtures.sh`) + CI are repo-root and never ship with the plugin, so a consumer gets inert `.cases`.
- **Root cause**: conflated "the data ships" with "the gate ships" across the plugin boundary — assumed a repo-root runner/CI reaches the consumer because the `.cases` it consumes are co-located inside the shipped plugin.
- **Wrong approach**: wrote a spec Risk asserting consumer regression value without tracing whether the runner/workflow (not just the data) crosses the plugin boundary.
- **Correct approach**: amended spec Risk + ADR-0002 to scope the suite repo-only (correct — this repo authors/edits these hooks; consumers install read-only and never edit them).
- **Prevention**: when a persisted test/CI artifact is tied to plugin-shipped code, trace EACH piece across the boundary (does `plugin.json`/the plugin dir carry the runner + workflow, not only the data?) before claiming a consumer benefits; else scope it repo-only explicitly. Kin: `dev-source-vs-consumer-routing`, `skill-path-source-vs-symlink` (dev-tree reality ≠ consumer reach) — watch for a unified promotion if the family recurs.

## 2026-06-26 — Rules-audit synth agent's dedup recommendations conflicted with rule-self-containment; one validity flag was a false positive

- **Cause-tag**: unverified-subagent-finding
- **Symptom**: a 25-agent rules-audit (sonnet finders + opus synth) recommended single-sourcing `scoping-rule-value`↔`scoping-skill-value`, cross-linking `flibco`→`agnostic-skill-authoring`, and flagged `skill-routing-sync`'s `.claude/skills/**` path as a HIGH "stale glob". I nearly applied all three.
- **Root cause**: treated the synth's recommendations as actionable without checking them against invariants it didn't weigh — these rules load on DISJOINT `paths` (never co-load), so `rule-self-containment` forbids the proposed "see X" as a load-bearing link; and the framework↔CLAUDE overlap is an INTENDED two-altitude split encoded in the bootstrap templates.
- **Wrong approach**: about to "dedup" rules whose duplication is REQUIRED (disjoint-paths self-containment) and trim a framework.md the generator template deliberately keeps; `.claude/skills/**` is the intentional local-skill path, not dead.
- **Correct approach**: verified each — read `rule-self-containment` (disjoint → keep both self-contained), the bootstrap templates (altitude split by design), the empty `.claude/skills/` (intentional). Shipped only the genuine fixes (model-selection example, markdown-style dup, coverage-gaming snippet).
- **Prevention**: before acting on a cross-file dedup/cross-link recommendation, check (1) do the two files co-load? disjoint `paths` → `rule-self-containment` makes any "see X" load-bearing-forbidden, so the duplication is REQUIRED not a defect; (2) is the overlap intended design owned by a `bootstrapping-*` template? never dedup a generated instance without reconciling its generator. A synth agent's recommendation is a lead, not a verdict.

## 2026-06-26 — Nearly applied fan-out audit findings that were false positives — subagents misread the runtime matcher and hallucinated a check

- **Cause-tag**: unverified-subagent-finding
- **Symptom**: a 25-agent fan-out audit (sonnet) of sdd-kit returned MED findings I was about to apply wholesale; on read-before-assert ~40% were false — declension-prefix triggers (`приступить к реализаци`) flagged as "truncated bugs that break detect-bypass", a stale `name===symlink` check claimed present in validation-checklist.md (it is not), and "routing ⊋ description" called a sync defect.
- **Root cause**: treated dispatched audit findings as verified evidence because they cite `file:line`, skipping independent verification of each claim against the actual runtime and files.
- **Wrong approach**: planned to "fix" the MED truncated-trigger findings directly — which would have broken the intentional declension-agnostic prefix matching.
- **Correct approach**: read `detect-bypass.sh` (matcher is `grep -iE` over the whole prompt → prefixes are correct), read `validation-checklist.md` (no symlink check), re-read `skill-routing-sync.md` (routing need only reflect declared triggers); applied only the genuine defects.
- **Prevention**: before acting on any fan-out audit finding, re-verify its claim THIS session — read the runtime that defines the behavior (the hook's matcher) and grep the cited file; a finding that cites `file:line` is still a claim, not proof. Expect a real false-positive rate from sonnet audits. (Kin to `incomplete-schema-verification`: a subagent's verification output is a lead to confirm, not ground truth.)

## 2026-06-24 — Happy-path-only hook fixtures false-greened a corpus-finalize branch that crashed on every real Stop

- **Cause-tag**: untested-empty-branch
- **Symptom**: `log-skill-usage.sh` Stop hook errored live ("Failed with non-blocking status code"); the prompt corpus (`prompts/YYYY-MM-DD.jsonl`) had NEVER been written since 3a and `pending-prompt.json` was never cleared — yet every 3a/3b fixture passed GREEN.
- **Root cause**: `TRIGGERS_MATCHED=$(jq ... | while read skill trig; do ...; echo "$P" | grep -qiE "$trig" && printf '%s\n' "$skill"; done | jq ...)` — under `set -euo pipefail` the loop's last command is the `grep -q` for the LAST routing entry; on no-match it exits 1, the while inherits 1, pipefail raises it to the `$()`, and set -e kills the hook right after the assignment. Fires for almost any prompt (the last routing skill rarely matches).
- **Wrong approach**: fixtured only the happy path — 3b's GREEN runs omitted `pending-prompt.json` entirely (so the corpus block never executed), and 3a's matched cases never hit a non-matching LAST entry. Both false-greened the broken branch.
- **Correct approach**: `if echo "$P" | grep -qiE "$trig"; then printf '%s\n' "$skill"; fi` so the loop's last command is always exit 0; added a fixture with `pending-prompt.json` present AND a prompt whose LAST routing trigger does not match.
- **Prevention**: fixture a hook's NON-happy path, not just the populated/matching case — for a per-entry loop, a prompt where the LAST entry's trigger misses; and never end a loop body (inside `$()` under set -e+pipefail) with a bare `cmd && action` whose left side can exit non-zero — use `if/then/fi` so the loop's last command is exit 0. (Same class as the grep -c "0\n0" entry: a path the happy-path fixture never exercises ships broken.)

## 2026-06-24 — `nullglob` does NOT drop an explicit absent path listed in a bash array

- **Cause-tag**: shell-glob-assumption
- **Symptom**: build 3b consumer `metrics-report.sh` built `METRICS_FILES=("$DIR"/metrics/*.jsonl "$DIR"/_metrics.jsonl)` under `shopt -s nullglob`; the cold-reviewer (plan gate) showed that on empty-state / post-rotation the array keeps the literal non-existent `_metrics.jsonl`, so `(( ${#arr[@]} > 0 ))` is true and `jq -rs "${arr[@]}"` crashes `No such file or directory` — the very empty-state the spec must handle.
- **Root cause**: assumed `nullglob` suppresses any absent entry. It only removes a GLOB that matches nothing; an EXPLICIT literal path (no wildcard) is never expanded, so it stays in the array verbatim whether or not the file exists.
- **Wrong approach**: listed the optional legacy file as a literal element inside the nullglob array, trusting nullglob to drop it when missing — and put the same wrong contract in both spec and plan.
- **Correct approach**: glob-only array `("$DIR"/metrics/*.jsonl)`, then append the optional explicit file conditionally: `[[ -f "$DIR/_metrics.jsonl" ]] && arr+=("$DIR/_metrics.jsonl")`.
- **Prevention**: never list an OPTIONAL explicit path inside a nullglob array — nullglob only suppresses wildcard patterns, not literals; append optional files via `[[ -f ]] && arr+=(...)`. Always execute the empty-state path (zero files) and confirm no non-existent literal reaches the downstream consumer. (Reviewer-diversity caught this — see model-selection.md: a different-model cold reviewer found the author's own wrong assumption.)

## 2026-06-24 — `. lib || exit 0` fails CLOSED under set -e (`.` is a POSIX special builtin)

- **Cause-tag**: errexit-failopen-idiom
- **Symptom**: extracting a shared `hooks/lib/common.sh`, the 4 hooks under `set -euo pipefail` exited **1** (not 0) when the lib was absent — a fail-open violation — while the 3 `set -uo` hooks exited 0. The missing-lib fixture (Task 5) caught it; the design, spec, plan, and an independent readiness review had all blessed the wrong idiom.
- **Root cause**: `.`/`source` is a POSIX **special builtin**; under `set -e` its open-failure (missing/unreadable file) terminates the shell with status 1 BEFORE the trailing `|| exit 0` — even `if ! . lib` — can run. So `. lib 2>/dev/null || exit 0` fails CLOSED under errexit.
- **Wrong approach**: used `. lib 2>/dev/null || exit 0` as the uniform "fail-open" source idiom; it reads as obviously-fail-open and survived four reasoning passes (design/spec/plan/readiness) because none of them executed the missing-lib case.
- **Correct approach**: guard readability with an ordinary builtin first — `L="${BASH_SOURCE[0]%/*}/lib/common.sh"; [ -r "$L" ] || exit 0; . "$L"`. `[ -r ]`'s `|| exit 0` runs normally; the unconditional `.` then only runs on a readable file.
- **Prevention**: never rely on `<special-builtin> || exit 0` for fail-open under `set -e` (`.`/`source`, `eval`, `exec`, `:`); guard the precondition with an ordinary `test`/`[ ]` first. And ALWAYS prove fail-open by EXECUTING the failure (run the hook with the file missing → assert exit 0), never by eyeballing the `||` — a missing-input fixture per fail-open path is mandatory.

## 2026-06-24 — Placed a new writing-* skill in a kit by topical surface, not its naming-family

- **Cause-tag**: skill-kit-placement
- **Symptom**: authored `writing-adrs` under `craft-kit/skills/design/` (next to `codebase-design`/`improve-codebase-architecture`) because ADRs are "architectural"; owner corrected — "why craft-kit if it should be sdd-kit?".
- **Root cause**: chose the kit by topical resemblance instead of the established naming-family. Every `writing-*` artifact-authoring skill (writing-specs/plans/rules/lessons/hooks/skills) lives in sdd-kit; a new `writing-<artifact>` is their sibling and belongs in `sdd-kit/skills/authoring`.
- **Wrong approach**: matched on the word "architecture" → craft-kit (vocabulary/review/prose), ignoring that the `writing-*` family is the load-bearing placement signal.
- **Correct approach**: moved to `sdd-kit/skills/authoring/writing-adrs`; updated both plugin.json manifests + the routing `plugin` field.
- **Prevention**: before choosing a kit/dir for a new skill, grep the existing skill names for a naming-family the new name joins (`find plugins/*/skills -name SKILL.md`); place by that family first, fall back to topical/register grouping only when no family applies.

## 2026-06-23 — Classified discipline skills as "technical docs" and assumed their prose punch was load-bearing

- **Cause-tag**: discipline-binding-is-structural
- **Symptom**: asked to run `humanizing-prose` over the learning-kit skills, I classified the SKILL.md bodies as "technical docs", nearly refused the edit, and warned that cutting the punchy rhetoric (dramatic fragments "Kill it."/"Suppress it.", binary-contrast openers) would break binding. Owner corrected: "те скиллы не должны быть техническими".
- **Root cause**: conflated a discipline skill's *voice* (punchy imperative prose) with its *binding mechanism*. Assumed the dramatic fragments and contrast openers were load-bearing, when the binding actually lives in the structural prohibitions + rationalization table + red flags. Treated a register question as settled by taste rather than by test.
- **Wrong approach**: argued from the `humanizing-prose` "technical doc → use tightening-prose" carve-out that the skills were off-limits, without testing whether a humanized version still binds.
- **Correct approach**: ran it test-first — per-skill pressure RED + Layer-2 inversion across all 9 skills. Every humanized version still complied under pressure while the no-skill control failed; the loud fragments were removable with no regression, so all 9 were kept.
- **Prevention**: a voice/register/de-slop edit to a `SKILL.md` is still a skill edit → Iron Law, RED-first. Decide whether a stylistic element is load-bearing with a binding pressure-test (RED + would-comply-WITHOUT inversion), never by assertion; expect the structural prohibition set (prohibitions + rationalization table + red flags), not the prose punch, to carry the discipline.

## 2026-06-23 — Linked a skill from a rule via a deep in-tree plugin path instead of its canonical name

- **Cause-tag**: dev-source-vs-consumer-routing
- **Symptom**: authored `.claude/rules/flibco/resolving-requirements-flibco-source.md` with a markdown link `[…](../../../plugins/sdd-kit/skills/chain/resolving-requirements/SKILL.md)`; owner flagged it — "вот такого не должно существовать, на крайняк референс просто на скилл без путей".
- **Root cause**: same conflation as the routing variant — treated the dev repo's in-tree plugin source path as a stable address. A plugin skill's body ships in the install cache, not under `plugins/` for a consumer; a deep relative path to `plugins/*/skills/**/SKILL.md` resolves only in THIS dev tree and is a dead reference everywhere else. The canonical address of a skill is its NAME (the routing key), not a filesystem path.
- **Wrong approach**: reached for the habitual markdown file-link to "let the reader open the skill", deep-linking into the plugin tree.
- **Correct approach**: cite the skill by bare backtick name (`resolving-requirements`); dropped the link and the `../../../plugins/...` path entirely — the rule reads fine without it.
- **Prevention**: in any rule/doc, reference a skill by its canonical name, never via a path into `plugins/*/skills/**` (or `SKILL.md`). Grep the body: `grep -nE '\]\([^)]*plugins/[^)]*skills|\.\./\.\./' <file>` must be empty. (Same class as the routing variant: dev source tree vs the address another layer/consumer expects.)

## 2026-06-23 — Modeled plugin-provided skills as kind:local with in-repo files paths in a consumer routing file

- **Cause-tag**: dev-source-vs-consumer-routing
- **Symptom**: in the consumer-side `.claude/skills-routing.json` (read by hooks from `$CLAUDE_PROJECT_DIR`) all 25 plugin skills were set `kind:"local"` with `files: ["plugins/<kit>/skills/.../SKILL.md"]`; owner flagged it — that path won't exist when the file is a real consumer's config.
- **Root cause**: conflated "this dev repo contains the plugin source in-tree" with "the consumer routing should point at it." A plugin skill's body lives in the install cache, not under `plugins/` in a consumer; an in-repo `files` path is a dead reference and mis-models a plugin skill as locally-authored.
- **Wrong approach**: approved design D4 as "local with real plugin paths" and wrote spec+plan on it; the in-repo paths even resolved in THIS dev repo, masking the error until the concrete file made it visible.
- **Correct approach**: plugin-provided ⇒ `kind:"ref"` (`plugin`+`name`+`triggers`, NO `files`); `local` only for skills authored in the consumer's own `.claude/skills/<name>/`. Reverted via a spec+plan loop-back and a redone task.
- **Prevention**: for each routing entry ask "does the body ship in an installed plugin, or is it authored in THIS repo?" Plugin ⇒ `ref`, no `files`. Local ⇒ `files` must resolve from the CONSUMER root, never a dev-tree-only path. (Kin to `skill-path-source-vs-symlink`: dev source tree vs the addressing another layer expects.)

## 2026-06-23 — Catalog re-derivation reported false drift: parser assumed all descriptions were folded scalars, missed quoted ones

- **Cause-tag**: parser-format-assumption
- **Symptom**: re-deriving the README catalog to verify the marketplace `bootstrapping-readme` run, a hand-rolled Python parser emitted every learning-kit description with a leading `"` (`— "Make confusing material click…`), implying the on-disk READMEs had drifted. They had not.
- **Root cause**: the parser captured the raw `description:` line and only handled `>-` folded block scalars (sdd-kit/craft-kit); learning-kit skills use a double-quoted YAML scalar (`description: "..."`), so the opening quote leaked into the "derived" string. The catalog-derivation DESCRIPTION algorithm operates on the PARSED YAML value (quotes are syntax, not content) — the parser, not the catalog, was wrong.
- **Wrong approach**: nearly read the leading-quote mismatch as catalog drift, since the deterministic re-derivation is supposed to be the source of truth.
- **Correct approach**: stripped matching surrounding quotes before the Triggers-strip + 120-truncate; the re-derived blocks then matched disk byte-for-byte (4/7/26 rows). Suspected the parser once the artifact (a leading quote) was itself implausible output.
- **Prevention**: when a hand-rolled check parses frontmatter, handle ALL YAML scalar forms a repo mixes (`>-`/`>`/`|` folded AND single/double-quoted) — parse YAML properly or strip matching surrounding quotes before deriving; and treat an implausible-looking derived artifact (a stray leading quote, doubled punctuation) as a parser bug to rule out before believing it is real drift. (Kin to `broken-grep-false-verification`: a hand-rolled verification mechanism fabricating a false signal — if a third such case lands, cluster them under one "sanity-check ad-hoc verification tooling" rule.)

## 2026-06-23 — Manifest passed jq but failed the real loader; verified-facts listed a field floor, not the full schema

- **Cause-tag**: incomplete-schema-verification
- **Symptom**: authored `.claude-plugin/marketplace.json` from a pre-implementation schema check (dispatched to `claude-code-guide`) that reported "each plugin entry needs `name` + `source`". The file passed `jq empty` and a `jq -e` field check, but `/plugin marketplace add ./` rejected it: `owner: Invalid input: expected object, received undefined` — the top-level required `owner` object was never mentioned by the verification and never added.
- **Root cause**: treated an enumerated "verified facts" field list as the COMPLETE schema (a ceiling) when it was only a floor — the fields it named are required, but it did not claim to be exhaustive, and other required fields (`owner`) went unlisted. Compounded by treating `jq`-valid JSON as schema-valid; structural validity says nothing about required-field conformance.
- **Wrong approach**: ran the real-loader (`/plugin marketplace add`) check as the LAST step (Task 10 GREEN) after building everything on it, and let jq validity stand in for it through all prior tasks.
- **Correct approach**: added `"owner": {"name": "..."}`; re-validated; the real `/plugin marketplace add ./` parse is the GREEN signal, not jq.
- **Prevention**: for any manifest consumed by a real loader (plugin.json, marketplace.json, package manifests, CI config), the GREEN signal is the actual loader/installer parsing it — run it early, not as a final gate; `jq`/structural validity is necessary, not sufficient. And when a verification subagent returns an enumerated required-field set, treat it as a floor (what's named is needed), never a ceiling (other required fields may be unnamed) — confirm against the loader before calling the manifest done.

## 2026-06-23 — Negative/guard validation case proved only the guard's existence, not that it discriminates

- **Cause-tag**: guard-case-inversion-design
- **Symptom**: Layer-2 validating a new opt-in drift class in `auditing-claude-md`, the negative case ("guard must NOT inject a baseline into a repo that declared none") was built as a one-sided inversion — "skill WITH the new guarded class" vs "skill WITHOUT the class at all". On an opt-out repo both refrain (no applicable class either way), so the validator rightly returned FAIL: the case proved nothing.
- **Root cause**: for a guard/opt-in clause, comparing feature-present vs feature-absent makes both negative paths observationally identical; the test confirms the guard text EXISTS but not that the guard predicate is load-bearing.
- **Wrong approach**: assumed the standard inversion ("would it comply WITHOUT the skill?") transfers unchanged to a negative case; it collapses when the expected behavior is *refraining*.
- **Correct approach**: re-ran a two-sided inversion that TOGGLES the predicate — SIDE A = the class as written (with the opt-in predicate) refrains; SIDE B = the same class with the predicate REMOVED would inject. PASS iff A refrains and B injects → the predicate is the discriminating difference.
- **Prevention**: when validating a guard/opt-in/conditional clause whose correct behavior is to NOT act, build the inversion by toggling the guard predicate itself (predicate-present vs predicate-removed variant of the same feature), never feature-present vs feature-absent; if both inversion arms produce the same output on the negative input, the case is untestable — rebuild it before accepting PASS.

## 2026-06-23 — Shaping prohibition keyed to a phrasing, evaded by a synonym

- **Cause-tag**: phrasing-keyed-prohibition
- **Symptom**: Layer-2 re-validation of `learning-curve-destroyer` produced the hedge "valuable eventually" in the "Ignore entirely (for now)" slot — a move the skill red-flags — yet it passed the skill's own prohibition. `confusion-translator` showed the same shape (source jargon echoed as a slot-2 "callback").
- **Root cause**: the prohibition was keyed to one wording ("but eventually you'll want…") instead of the underlying MOVE (acknowledging future value), so a semantic near-synonym slipped past the closed phrase list.
- **Wrong approach**: wrote the banned phrasing AS the prohibition, treating the enumerated wording as the exhaustive set the rule is matched against.
- **Correct approach**: (pending REFACTOR, not yet applied) forbid the move in any wording — "no acknowledgement of future value, however phrased" — and demote concrete phrasings to non-exhaustive examples.
- **Prevention**: when authoring/reviewing a shaping prohibition, check it bans the MOVE, not a wording; a prohibition that reads as a closed list of phrases is a red flag — RED it with a near-synonym NOT in the list and confirm the skill still rejects it.

## 2026-06-22 — Hook shipped a zero-match branch the fixture never exercised (grep -c "0\n0")

- **Cause-tag**: untested-empty-branch
- **Symptom**: `friction-log.sh` errored on every real Stop — `line 50: 0\n0: syntax error in expression` then `cur_error: unbound variable`. It had passed its GREEN fixtures.
- **Root cause**: `grep -c` PRINTS "0" AND EXITS 1 on no match, so `cur=$(printf … | grep -c PATTERN || echo 0)` evaluated to `"0\n0"`, which broke `cur_error=$(( cur_total - … ))` and (under `set -u`) left `cur_error` unbound. The GREEN fixtures only fed transcripts that HAD matches (nonzero counts), so the zero-match branch shipped untested and failed the moment a real turn had no `is_error` entries.
- **Wrong approach**: treated "GREEN on the populated fixture" as proof the hook works; the populated path never hit the `|| echo 0` double-print.
- **Correct approach**: dropped `|| echo 0`, sanitized each count to a clean integer (`${n//[^0-9]/}`, default 0); added fixtures for zero-match, partial (only one class), and no-tool_results transcripts.
- **Prevention**: when fixturing a counting/aggregating/branching hook, ALWAYS include the empty / zero-match input (no matches, empty transcript) alongside the populated case — the happy-path fixture is a false green for the empty branch. And never wrap `grep -c` in `|| echo 0`: on no match it already prints "0" and exits 1, so the `||` double-prints "0\n0".

## 2026-06-22 — Keyed hook accounting on a payload field that does not exist for that event+tool

- **Cause-tag**: hook-payload-assumption
- **Symptom**: `token-guard.sh`'s by-model accounting (#2) keys on `.tool_input.model`, but verification against 59 real `crewing-mobile` transcripts showed Task/Agent `tool_input` is only `{description, prompt, subagent_type}` — no `model`. So every subagent dispatch buckets as `"inherited"` and the per-model signal is dead.
- **Root cause**: assumed the dispatched model is echoed in the PostToolUse payload. It is not — the model comes from the subagent's `.claude/agents/<type>.md` frontmatter, applied by the harness and never surfaced in `tool_input`. Separately, a parent PostToolUse only sees the subagent's final-output bytes, never its internal token consumption, so any parent-side token accounting is a coarse proxy at best.
- **Wrong approach**: wrote the accounting against an imagined payload shape, fixture-tested it with a synthetic `{tool_input:{model:"opus"}}` I invented — so the fixture passed while the real dispatch payload never carries that field (a test that passed for the wrong reason).
- **Correct approach**: key by the field that actually exists — `.tool_input.subagent_type` — and resolve its tier via the agent's frontmatter when a tier label is needed; treat parent-side byte counts as a proxy, not true cost.
- **Prevention**: before keying hook logic on a payload field, confirm the field exists for THAT event+tool in a real transcript/payload (`grep`/inspect `~/.claude/projects/<proj>/*.jsonl`), and build the fixture from a real captured payload, not an invented one — an invented fixture validates the assumption instead of the runtime.

## 2026-06-22 — Security guard matched short tokens as substrings → false-blocked benign commands

- **Cause-tag**: guard-substring-false-positive
- **Symptom**: `security-guard.sh` blocked legitimate read-only hook-test commands three times in one session ("Environment dump combined with network tool", "combines credential file access with network tool"). The commands contained no exfil — only words like "re**set**-turn-budget.sh", "sy**nc**ing", "**enc**oding", "meth**od**".
- **Root cause**: guard regexes matched short tokens as unanchored substrings. `EXFIL_TOOLS` "nc" matched "sync"/"encoding"; Rule 12's `set\b` had a word boundary only on the RIGHT, so it matched the "set" inside "re**set**"; `od` (ENCODE) matched "method"/"code". Combined with a `.claude/(settings|hooks)` path mention or another stray substring, two unrelated fragments on different lines satisfied an AND-rule.
- **Wrong approach**: assumed `(nc|set\b|od|...)` in `grep -E` matches those as commands; it matches them anywhere in the command string, across all lines (`grep -q` scans every line).
- **Correct approach**: word-anchor short tokens on BOTH sides — `(^|[^[:alnum:]_])(curl|nc|scp|…)([^[:alnum:]_]|$)` for EXFIL/ENCODE, same for `env|set|printenv`. Real exfil still matches because the tool appears as a whole command word (`nc evil 443`, `/usr/bin/nc …`); benign substrings no longer do.
- **Prevention**: when authoring or reviewing a guard regex containing short tokens (`nc`, `od`, `set`, `env`, `host`, `ssh`), word-anchor both sides and RED it against benign words that CONTAIN the token as a substring ("reset", "syncing", "method", "settings"), AND regression-test that real exfil (`nc host`, `/usr/bin/nc`, `set | curl`) still blocks. A one-sided `\b` is a red flag — `set\b` still matches "reset".

## 2026-06-22 — Added accounting state to a hook that shares one global state dir across sessions

- **Cause-tag**: hook-state-not-session-keyed
- **Symptom**: extended `token-guard.sh` with `by-model-budget.json` keyed only by model, into the shared `.claude/state` dir alongside `turn-budget`/`session-budget`/`last-prompt` — none keyed by session. Owner asked "what if I run several sessions in parallel"; under concurrent Claude Code sessions these files race and co-mingle.
- **Root cause**: hook state uses fixed global filenames in one `.claude/state` dir. Concurrent sessions interleave read-modify-write (lost increments), one session's `UserPromptSubmit` turn-reset clobbers another mid-turn, `last-prompt.txt` is overwritten so the Stop-hook bypass analysis misattributes the prompt, and session/by-model ceilings sum all sessions at once.
- **Wrong approach**: assumed a single active session when adding accounting state — the same assumption every existing repo hook makes.
- **Correct approach**: (tracked as task #11, not yet applied) key state by `session_id` from the hook stdin — `.claude/state/<session_id>/…` — so turn/session/by-model/last-prompt isolate per session and a new session gets a fresh dir (which also gives session-boundary reset for free).
- **Prevention**: when adding or reviewing any hook that writes to `.claude/state`, confirm the file path is namespaced by `session_id` from the hook input; a fixed global filename is a red flag — it corrupts under parallel sessions. Confirm `session_id` is actually present in that event's payload before keying on it (this repo's `hook-events.md` does not enumerate it).

## 2026-06-22 — Wrote a skill file to a fabricated `.claude/skills/<category>/` path

- **Cause-tag**: skill-path-source-vs-symlink
- **Symptom**: created `test-cases.md` at `.claude/skills/apply-chain/subagent-driven-development/references/…` — a non-existent nested path under the flat-symlink dir; the Layer-2 validation subagent's `find` could not locate it and returned INCONCLUSIVE.
- **Root cause**: spliced the source-tree category segment (`apply-chain/`) onto the symlink prefix (`.claude/skills/`). The two addressing schemes are distinct: source lives at `skills/<category>/<name>/…`; `.claude/skills/` holds only flat per-skill symlinks `.claude/skills/<name>` with NO `<category>/` level.
- **Wrong approach**: assumed `.claude/skills/<name>` generalizes to `.claude/skills/<category>/<name>`, and wrote without checking the symlink target.
- **Correct approach**: relocated the file to the source `skills/apply-chain/subagent-driven-development/references/test-cases.md` (reachable via the `.claude/skills/<name>` symlink) and removed the bogus `.claude/skills/apply-chain` tree.
- **Prevention**: author skill files in the SOURCE tree `skills/<category>/<name>/…`, never under `.claude/skills/<anything-but-the-flat-name>`. Before writing into a skill, run `ls -la .claude/skills/<name>` to read the symlink target and write into that resolved source dir; treat any path of shape `.claude/skills/<seg>/<name>/…` as a red flag.

## 2026-06-22 — Coupled skills by referencing another skill's internal content

- **Cause-tag**: cross-skill-content-coupling
- **Symptom**: owner rejected edits where one skill referenced another skill's internals — `writing-rules`/`writing-hooks` citing `writing-skills`' `test-cases.md` mandate (F11), and grilling/writing-specs/pre-implementation asserting "the same threshold as skill X" (F6).
- **Root cause**: treated cross-skill references as helpful consistency/DRY; they actually couple skills so one rots when another changes, breaking self-containment.
- **Wrong approach**: made grilling's "same threshold" claim true by naming the other skills; justified an absent `test-cases.md` by pointing at `writing-skills`' requirement.
- **Correct approach**: reverted both; each skill states its own contract/predicate independently, so consistency holds by construction (identical text), never by one skill naming another's.
- **Prevention**: before writing another skill's name in a SKILL.md, classify the reference — a HAND-OFF / data-flow ref ("next use writing-specs", "hand the bundle to grilling") is legitimate; a CONTENT/INTERNAL ref ("same threshold X uses", "X requires Y so this is N/A") is coupling — inline the standalone statement instead. Grep the edit for skill names; confirm each hit is a hand-off, not a content dependency.

## 2026-06-21 — RED baseline subagent wrote README.md (default agent type carries Write/Edit)

- **Cause-tag**: subagent-worktree-mutation
- **Symptom**: a RED baseline `claude` subagent (dispatched read-only in intent) wrote `README.md` — the exact artifact `bootstrapping-readme` produces — leaving an unrequested working-tree change.
- **Root cause**: the default `claude`/general-purpose agent type carries Write/Edit; a baseline prompt that says "generate a README" gets taken literally and the file is written.
- **Wrong approach**: trusted that a "baseline" framing keeps the subagent read-only; it did not.
- **Correct approach**: `git checkout -- README.md` to restore; re-dispatched the Layer-2 run with an explicit "do NOT write files, output as text" instruction.
- **Prevention**: dispatch baseline/RED & Layer-2 subagents read-only (`Explore` agent, or forbid writes in the prompt + "output as text"); assert `git status --short` is clean after a baseline run.

## Promoted clusters

- relative-link-read-location → rules/verification/link-resolution-verification.md (2026-07-18, owner-directed on 1 reproduced incident — verification family, distinct mechanism from search-scope/usage-claim)
- unverified-usage-assumption → rules/verification/usage-claim-verification.md (2026-07-09)
- export-baseline-mismatch → KEPT in lessons, not promoted (independent review 2026-06-27): real, generalizable class but already covered by `rules/authoring/fair-red-baseline.md` §"Context inheritance" + `rules/authoring/scoping-skill-value.md` §Caveat + `rules/authoring/scoping-rule-value.md` Edge Case; a new rule would duplicate them (too thin a delta). Entry bodies deleted 2026-07-17 (covered — git keeps them via `git log -S 'export-baseline-mismatch'`).
- dedup-drops-required-element → rules/verification/dedup-drops-required-element.md (2026-06-26)
- contaminated-red-baseline → rules/authoring/fair-red-baseline.md (2026-06-24)
- broken-grep-false-verification → rules/verification/search-scope-verification.md (2026-06-23)
- skill-value-vs-noop → rules/authoring/scoping-skill-value.md (2026-06-19)
- markdown-fence-counting → rules/conduct/markdown-style.md (2026-06-19)
