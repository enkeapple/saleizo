# Lessons Learned

Append-only. New entries go at the top of `## Entries`. When a `Cause-tag` recurs 3×, promote it to a rule under `.claude/rules/` and record it in `## Promoted clusters`. Mechanics: the `lessons-learned-protocol` skill.

## Entries

### 2026-06-19 — Fixed the CLAUDE.md instance but not the template that generates it (bootstrapping kept reproducing the bug)

- **Cause-tag:** `fix-instance-not-generator`
- **What happened:** After fixing the vault's own `.claude/CLAUDE.md` to route lesson capture through the `lessons-learned-protocol` skill, the `bootstrapping-claude-md` operating-manual **template** still said "append it to lessons-learned.md the SAME turn" (Non-negotiable #5) with the skill only as an optional angle-bracket placeholder. Every CLAUDE.md generated from it would have shipped the just-fixed bypass. The instance was fixed; the generator was not.
- **Fix / rule:** When you fix a defect in an artifact that is produced from a template/generator (a CLAUDE.md, a scaffolded file, a rule), the SAME turn check the generator for the same defect and fix it there — otherwise the fix is local and the bug regenerates. Propagated the routing rule into `bootstrapping-claude-md` (template #5 + Lessons path + a third "overrides the templates' defaults" rule) and added the inverse-drift check to `auditing-claude-md`. Kept it agnostic/conditional ("if the repo has a lessons-capture skill"), matching the template's existing `handoff` precedent.
- **Prevention:** On any fix to a file that has a generator/template in `.claude/skills/**` (grep the skill set for the artifact name or a template producing it), apply the fix to the template too, and add/confirm an audit check that catches the drift; a RED/GREEN on the *generated* output, not just the hand-fixed instance.

### 2026-06-19 — `lessons-learned-protocol`'s own promotion-debt scan silently matched nothing (format drift)

- **Cause-tag:** `self-check-format-drift`
- **What happened:** The scan command documented in `lessons-learned-protocol/SKILL.md` was `grep -oE 'Cause-tag\*\*:…'` — it matches `Cause-tag**:` (template format), but the real entries are written `**Cause-tag:**` with the tag in backticks, and the file's intro prose says `` `Cause-tag` ``. Run literally on the live log it returned **empty** → a false "no promotion debt", so a cluster could cross the threshold of 3 unnoticed. Three cosmetic formats of one field had drifted apart and the self-check matched none of the actual entries.
- **Fix / rule:** A field-scraping regex in a skill's own verification step must be anchored to the field's stable structural marker and tolerant of cosmetic markdown variance — not pinned to one punctuation layout. Fixed to anchor on the **list-item line start** (`^[[:space:]]*-[[:space:]]+\*\*Cause-tag[^[:alnum:]]+[a-z0-9-]+`): absorbs colon-inside/outside and optional backticks, and the line anchor excludes prose that merely quotes the field (a body-only anchor still matched a lesson that discussed `Cause-tag` in its Fix text — a real false positive caught only because the log itself now contains such prose).
- **Prevention:** Author/verify any "run this to self-check" command against the REAL artifact at write time, never assume it matches the template; for markdown field scrapes, anchor on the field's **line-start list marker** (not just the bold span, which prose can quote) and allow `[^[:alnum:]]+` between marker and value.

### 2026-06-19 — A RED scenario that foregrounds tool choice contaminates the test and yields a false GREEN

- **Cause-tag:** `red-scenario-contamination`
- **What happened:** Diagnosing the `lessons-learned-protocol` bypass, the first RED prompt asked the subagent to "state the exact first tool call you would make". It complied via `Skill` — a false GREEN. The premise (the agent writes the lesson via direct `Edit`) only reproduced when the scenario was naturalistic: a real task with the capture incidental and **no tool named**, where the agent ran `Read→Read→Edit`, bypassing the skill. Same agent, same manual — only the prompt's framing differed.
- **Fix / rule:** A RED/baseline subagent prompt must never name, or ask the agent to reason about, the tool/skill under test — that cue is the thing you are trying to observe emerge (or not) on its own. Give a realistic task, let the behaviour happen, and read it from a post-hoc tool list or `git diff`, not from a "which tool would you use" question. This is `writing-great-skills`' inversion test applied to the *scenario*: if foregrounding the choice flips the result, the scenario, not the skill, decided it.
- **Prevention:** Before running a baseline, grep your own scenario prompt for the tool/skill name under test (`Skill`, `Edit`, the skill's name) — any hit in the instruction is contamination; strip it and re-run.

### 2026-06-19 — `detect-bypass.sh` has three distinct warning conditions, not just "Read a skill body"

- **Cause-tag:** `wrong-assumption`
- **What happened:** A question asserted the bypass hook "only ever warns when you Read a skill's SKILL.md body". Reading [hooks/detect-bypass.sh](hooks/detect-bypass.sh) showed three separate `SKILL-BYPASS warn:` paths: **(1)** `Read` of a path registered as a skill's `files` body without the matching `Skill` invoked this turn (lines 56–77); **(1b)** `Edit`/`Write`/`MultiEdit` to `lessons-learned.md` without invoking `lessons-learned-protocol` first (lines 79–91); **(2)** a once-per-turn threshold warning — after `TRIGGER_BYPASS_THRESHOLD=3` non-Skill tool calls, if the stored user prompt matches a skill's `triggers` regex and that skill was never invoked (lines 93–121). Conditions (1)/(1b) fire per matching tool call; (2) is gated by a counter + a one-shot `turn-bypass-warned.flag`.
- **Fix / rule:** Don't characterize a hook's behavior from its name or a single code path — read every `echo … >&2` / warn branch before stating "it only does X". Confirmed by reading all three branches this turn.
- **Prevention:** When asked "does hook X only do Y?", grep the hook for every warn/exit branch (`grep -nE 'warn|>&2|exit' hook.sh`) and enumerate each condition before answering.

### 2026-06-19 — "Add a verify/review phase" defaults to a no-op; the binding value is the efficacy test, not another correctness pass

- **Cause-tag:** `skill-value-vs-noop` (2nd instance)
- **What happened:** Asked to add a "Review phase" to `writing-rules` that tests a freshly-written rule "meets all conditions". The literal reading is a *correctness* review. RED first: 3 escalating baseline scenarios (swapped ✅/❌, `paths`-glob miss, dead-path reference) were ALL caught by a cold agent on the current skill — the strong model + the repo's read-before-assert discipline already cover reading-detectable defects. A correctness phase would have been a `writing-great-skills` no-op (same root cause as the entry below: principle/correctness content a strong model already obeys).
- **Fix / rule:** When asked to add a "verify/review/validate" phase, RED-test the *literal* version against the baseline before building. If the baseline catches it, the non-no-op addition is the **efficacy** test, not another correctness pass — for a rule, a cold-agent RED/GREEN ("does the rule actually steer behaviour?"). Built that instead; GREEN-confirmed by catching a well-formed `const`-vs-`var` rule a cold agent complies with by default (a no-op rule static review approves). Landed as `writing-rules` → "Test the rule on a cold agent" + `references/rule-efficacy-test-prompt.md`.
- **Watch:** this is the 2nd `skill-value-vs-noop` instance — one more → promote to a rule on scoping skill/phase value to reproduced failures.

### 2026-06-19 — A skill's "principles" are a no-op for a strong model; the binding value is lexicon + deliverable shape + skipped process steps

- **Cause-tag:** `skill-value-vs-noop`
- **What happened:** RED baseline for migrating `codebase-design` / `improve-codebase-architecture` — 4 cold subagents on well-framed design prompts reached the skills' *principles* unaided (deletion-test reasoning, deep/shallow detection, inject-don't-create, fakes>mocks, "no seam until two adapters", domain-shaped narrow ports). A skill teaching those to a strong model proves little (inversion test: it complies WITHOUT the skill). What it reliably FAILED, 4/4: vocabulary drift (every agent wrote the explicitly-forbidden "boundary", plus "layers/wrappers/shell/core" — no fixed lexicon), no structured visual deliverable when asked to "present findings", skipped the explore→present→grill process, and produced ONE interface design instead of design-it-twice.
- **Fix / rule:** Calibrate GREEN to the *reproduced* failure, not the source's stated purpose. For these skills the defensible value = enforced shared vocabulary + the structured deliverable + the process steps a model skips — keep those load-bearing, treat principle-prose as light scaffolding. Vocabulary drift is a *shaping* failure → fixed-lexicon recipe ("use exactly X; never substitute Y"), not prohibitions (per `writing-great-skills` "Match the Form to the Failure").
- **Watch:** if this recurs (a third skill whose principle-content is no-op for strong models) → promote to a rule on scoping skill value to reproduced failures.

### 2026-06-19 — Naive fence-toggle corrupts markdown-in-markdown when auto-fixing

- **Cause-tag:** `markdown-fence-counting`
- **What happened:** A bulk fixer that added a language to "bare opening fences" treated every ` ``` ` as a toggle. In template files that wrap example fenced blocks in a four-backtick fence (` ````markdown ` … ` ```` `), the inner three-backtick fences are literal content; naive toggling desynced and appended `text` to *closing* fences.
- **Fix / rule:** Parse fences per CommonMark — a fence opened with N backticks closes only on a line of ≥N backticks with no info string; inner shorter fences are content. Same rule for skipping tables inside example blocks. Codified in [rules/common/markdown-style.md](rules/common/markdown-style.md) (Fenced-code bullet + Edge Cases).
- **Also:** Python `glob('**/*.md')` skips dot-directories (`.claude/`) — use `os.walk` for repo-wide markdown sweeps.

## Promoted clusters

(none yet — promote a cause-tag here once it reaches 3 entries)
