# Telemetry Daily-Rotation + 14-day GC (3b) — Implementation Plan

**Goal:** Roll the telemetry stream into dated `metrics/YYYY-MM-DD.jsonl` day-files and replace the 7-day session-dir GC in `reset-turn-budget` with a single 14-day GC over day-files (+ legacy + session dirs), updating the consumer to read the new layout.
**Architecture:** Three Stop/PostToolUse writers get a one-line `METRICS` path change; `reset-turn-budget` (UserPromptSubmit) gets its GC block swapped; `metrics-report.sh` globs the day-files. Each hook is verified by fixture-execution (crafted stdin → run → assert decision + fail-open).
**Tech stack:** Bash + `jq` + `find`; verification = fixture-execution + `bash -n` + `jq` (no pnpm/build/test pipeline).

## Global constraints

- **Test-first (writing-hooks):** craft the fixture, run RED/baseline, edit, run GREEN. Every edited hook keeps its fail-open behavior (the `common.sh` readability guard + `hook_require_json` paths are untouched).
- **`grep`/`rg` are unavailable in THIS shell for DIRECT calls** — fixture ASSERTIONS use `jq -e`, `test`, `[[ ]]`, `case`. (A hook's own internal `grep` runs fine when the hook executes as a child process.)
- **Record shapes do not change** — only the *file location* of telemetry records moves. `v`/`type`/`session`/`ts` and every field stay as-is.
- **Fresh `SB=$(mktemp -d)` per fixture.** Hooks run under `set -euo pipefail` (except `friction-log` = `set -uo pipefail`, intentional per H2); new GC code stays fail-open (`2>/dev/null || true`).
- **Retention = 14 days, pruning by file mtime** (the existing idiom; no filename-date parsing). `.claude/state` is gitignored.
- **macOS default bash is 3.2:** an empty array expanded as `"${arr[@]}"` under `set -u` errors — so the consumer guards the array reference behind `(( ${#arr[@]} > 0 ))` (the expansion only runs when non-empty).
- **Git boundary:** the human owns the commit; each task proposes a one-line Conventional Commit.
- Spec: [docs/specs/2026-06-24-telemetry-retention-gc.md](../specs/2026-06-24-telemetry-retention-gc.md).

---

## Task 1 — Rotate the three telemetry writers to dated day-files

> **Status: DONE** — RED→GREEN verified (all 3 writers → dated `metrics/<today>.jsonl`, no legacy, fail-open exit 0, `bash -n` clean). Awaiting human commit.

**Files:**
- Modify: `plugins/guardrails-kit/hooks/log-skill-usage.sh:15`
- Modify: `plugins/guardrails-kit/hooks/friction-log.sh:29`
- Modify: `plugins/guardrails-kit/hooks/detect-bypass.sh:18`

**Interfaces:**
- Consumes: `hook_sid` / `hook_state_dir` (lib `common.sh`); `.claude/skills-routing.json`.
- Produces: telemetry records now land in `.claude/state/metrics/<UTC-date>.jsonl` (was `.claude/state/_metrics.jsonl`). No `_metrics.jsonl` is created by any writer.

- [ ] **1.1 Failing fixture — `log-skill-usage` (Stop, emits a `skill_event`).**

```bash
HOOK=plugins/guardrails-kit/hooks/log-skill-usage.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/s1"
printf 'brainstorm this' > "$SB/.claude/state/s1/last-prompt.txt"
echo '{"skills":{"grilling":{"kind":"ref","plugin":"sdd-kit","name":"grilling","triggers":["brainstorm"]}}}' > "$SB/.claude/skills-routing.json"
echo '{"session_id":"s1","transcript_path":"/nonexistent"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
TODAY=$(date -u +%F)
test -f "$SB/.claude/state/_metrics.jsonl" && echo "RED: landed in legacy _metrics.jsonl"
```

- [ ] **1.2 Confirm RED:** prints `RED: landed in legacy _metrics.jsonl`; `test -d "$SB/.claude/state/metrics"` is false (no dated dir yet).

- [ ] **1.3 Apply fix — `log-skill-usage.sh` line 15.**

```bash
# BEFORE
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/_metrics.jsonl"
# AFTER
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/metrics/$(date -u +%F).jsonl"
```

- [ ] **1.4 Apply fix — `friction-log.sh` line 29.**

```bash
# BEFORE
METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"
# AFTER
METRICS="$PROJECT_DIR/.claude/state/metrics/$(date -u +%F).jsonl"
```

- [ ] **1.5 Apply fix — `detect-bypass.sh` line 18.**

```bash
# BEFORE
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/_metrics.jsonl"
# AFTER
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/metrics/$(date -u +%F).jsonl"
```

- [ ] **1.6 Confirm GREEN — `log-skill-usage` (re-run 1.1 in a fresh sandbox).**

```bash
HOOK=plugins/guardrails-kit/hooks/log-skill-usage.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/s1"
printf 'brainstorm this' > "$SB/.claude/state/s1/last-prompt.txt"
echo '{"skills":{"grilling":{"kind":"ref","plugin":"sdd-kit","name":"grilling","triggers":["brainstorm"]}}}' > "$SB/.claude/skills-routing.json"
echo '{"session_id":"s1","transcript_path":"/nonexistent"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
TODAY=$(date -u +%F)
test -f "$SB/.claude/state/metrics/$TODAY.jsonl" && echo "DATED OK"
test ! -f "$SB/.claude/state/_metrics.jsonl" && echo "NO LEGACY"
jq -e 'select(.type=="skill_event" and .event=="bypass" and .skill=="grilling")' "$SB/.claude/state/metrics/$TODAY.jsonl" >/dev/null && echo "RECORD OK"
```

Expected: `DATED OK` + `NO LEGACY` + `RECORD OK`.

- [ ] **1.7 Confirm GREEN — `friction-log` (transcript with one is_error result → `friction` error line).**

```bash
HOOK=plugins/guardrails-kit/hooks/friction-log.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state"
TR="$SB/t.jsonl"
printf '%s\n' '{"message":{"content":[{"type":"tool_result","is_error":true,"content":"boom failure"}]}}' > "$TR"
echo "{\"session_id\":\"s1\",\"transcript_path\":\"$TR\"}" | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
TODAY=$(date -u +%F)
test -f "$SB/.claude/state/metrics/$TODAY.jsonl" && echo "DATED OK"
test ! -f "$SB/.claude/state/_metrics.jsonl" && echo "NO LEGACY"
jq -e 'select(.type=="friction" and .class=="error")' "$SB/.claude/state/metrics/$TODAY.jsonl" >/dev/null && echo "RECORD OK"
```

Expected: `DATED OK` + `NO LEGACY` + `RECORD OK`.

- [ ] **1.8 Confirm GREEN — `detect-bypass` (Edit on lessons-learned.md without writing-lessons → `direct_edit_lessons_log`).**

```bash
HOOK=plugins/guardrails-kit/hooks/detect-bypass.sh
SB=$(mktemp -d); mkdir -p "$SB/.claude/state/s1"
echo '{}' > "$SB/.claude/skills-routing.json"
echo '[]' > "$SB/.claude/state/s1/turn-skills-invoked.json"
echo '{"session_id":"s1","tool_name":"Edit","tool_input":{"file_path":"/x/lessons-learned.md"}}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK" 2>/dev/null
TODAY=$(date -u +%F)
test -f "$SB/.claude/state/metrics/$TODAY.jsonl" && echo "DATED OK"
test ! -f "$SB/.claude/state/_metrics.jsonl" && echo "NO LEGACY"
jq -e 'select(.event=="direct_edit_lessons_log")' "$SB/.claude/state/metrics/$TODAY.jsonl" >/dev/null && echo "RECORD OK"
```

Expected: `DATED OK` + `NO LEGACY` + `RECORD OK`.

- [ ] **1.9 Fail-open + syntax check.**

```bash
for H in log-skill-usage friction-log detect-bypass; do
  HOOK="plugins/guardrails-kit/hooks/$H.sh"
  bash -n "$HOOK" && echo "$H: SYNTAX OK"
  SB=$(mktemp -d)
  printf 'not json' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "$H: exit=$?"
done
```

Expected: each `SYNTAX OK` and `exit=0` (fail-open on garbage stdin).

- [ ] **1.10 Commit.** Propose `feat(hooks): rotate telemetry writers to dated metrics/ day-files`.

---

## Task 2 — `reset-turn-budget`: single 14-day GC over day-files + legacy + session dirs

> **Status: DONE** — RED→GREEN verified (stale day-files/legacy/dir pruned; fresh day-file + live session dir + turn-reset kept; fail-open + first-run-without-metrics/ clean; `bash -n` clean). Awaiting human commit.

**Files:**
- Modify: `plugins/guardrails-kit/hooks/reset-turn-budget.sh:19-21` (the `GC_DAYS=7` session-dir block)

**Interfaces:**
- Consumes: `hook_sid` / `hook_state_dir`; runs *after* the `touch "$STATE_DIR"` on line 12 (load-bearing — keeps the live session dir's mtime fresh).
- Produces: prunes, by mtime > 14 days: `metrics/*.jsonl` + `prompts/*.jsonl` day-files, the legacy root `_metrics.jsonl`, and per-session scratch dirs. Fail-open.

- [ ] **2.1 Failing fixture — seed stale + fresh state, run the hook.**

```bash
HOOK=plugins/guardrails-kit/hooks/reset-turn-budget.sh
SB=$(mktemp -d); ST="$SB/.claude/state"
mkdir -p "$ST/metrics" "$ST/prompts" "$ST/oldsess" "$ST/s1"
TODAY=$(date -u +%F)
: > "$ST/metrics/2026-05-01.jsonl"; touch -t 202605010000 "$ST/metrics/2026-05-01.jsonl"
: > "$ST/prompts/2026-05-01.jsonl"; touch -t 202605010000 "$ST/prompts/2026-05-01.jsonl"
: > "$ST/_metrics.jsonl";          touch -t 202605010000 "$ST/_metrics.jsonl"
touch -t 202605010000 "$ST/oldsess"
: > "$ST/metrics/$TODAY.jsonl"
echo '{"session_id":"s1","prompt":"hello"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
test -f "$ST/metrics/2026-05-01.jsonl" && echo "RED: stale day-file NOT pruned"
test -f "$ST/_metrics.jsonl" && echo "RED: legacy NOT pruned"
```

- [ ] **2.2 Confirm RED:** prints `RED: stale day-file NOT pruned` and `RED: legacy NOT pruned` (the current 7-day GC only sweeps *dirs*, so `oldsess` is gone but the stale `.jsonl` files survive).

- [ ] **2.3 Apply fix — replace lines 19–21.**

```bash
# BEFORE (lines 19-21)
GC_DAYS=7
STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
find "$STATE_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +"$GC_DAYS" -exec rm -rf {} + 2>/dev/null || true
```

```bash
# AFTER
GC_DAYS=14
STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
# (1) Dated telemetry + corpus day-files, and the pre-3b legacy single file, older than GC_DAYS.
#     Three -maxdepth-1 roots: STATE_BASE (legacy _metrics.jsonl) + metrics/ + prompts/.
find "$STATE_BASE" "$STATE_BASE/metrics" "$STATE_BASE/prompts" \
  -maxdepth 1 -type f -name '*.jsonl' -mtime +"$GC_DAYS" -delete 2>/dev/null || true
# (2) Per-session scratch dirs older than GC_DAYS (kept until build 3c moves scratch to ${TMPDIR}).
find "$STATE_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +"$GC_DAYS" -exec rm -rf {} + 2>/dev/null || true
```

Also update the comment above the block (lines 15–18) so it says `GC_DAYS` (14) and that it now prunes dated day-files + legacy + session dirs.

- [ ] **2.4 Confirm GREEN — re-run 2.1's seed in a fresh sandbox, then assert.**

```bash
HOOK=plugins/guardrails-kit/hooks/reset-turn-budget.sh
SB=$(mktemp -d); ST="$SB/.claude/state"
mkdir -p "$ST/metrics" "$ST/prompts" "$ST/oldsess" "$ST/s1"
TODAY=$(date -u +%F)
: > "$ST/metrics/2026-05-01.jsonl"; touch -t 202605010000 "$ST/metrics/2026-05-01.jsonl"
: > "$ST/prompts/2026-05-01.jsonl"; touch -t 202605010000 "$ST/prompts/2026-05-01.jsonl"
: > "$ST/_metrics.jsonl";          touch -t 202605010000 "$ST/_metrics.jsonl"
touch -t 202605010000 "$ST/oldsess"
: > "$ST/metrics/$TODAY.jsonl"
echo '{"session_id":"s1","prompt":"hello"}' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"
test ! -f "$ST/metrics/2026-05-01.jsonl" && echo "STALE METRIC PRUNED"
test ! -f "$ST/prompts/2026-05-01.jsonl" && echo "STALE PROMPT PRUNED"
test ! -f "$ST/_metrics.jsonl"           && echo "LEGACY PRUNED"
test ! -e "$ST/oldsess"                   && echo "STALE DIR PRUNED"
test -f "$ST/metrics/$TODAY.jsonl"        && echo "FRESH DAYFILE KEPT"
test -d "$ST/s1"                          && echo "LIVE SESSION DIR KEPT"
test -f "$ST/s1/turn-budget.json"         && echo "TURN RESET RAN"
```

Expected: all seven lines print (`STALE METRIC PRUNED`, `STALE PROMPT PRUNED`, `LEGACY PRUNED`, `STALE DIR PRUNED`, `FRESH DAYFILE KEPT`, `LIVE SESSION DIR KEPT`, `TURN RESET RAN`).

- [ ] **2.5 Fail-open + first-run (no metrics/prompts dir) + syntax.**

```bash
HOOK=plugins/guardrails-kit/hooks/reset-turn-budget.sh
bash -n "$HOOK" && echo "SYNTAX OK"
# garbage stdin → still exit 0, turn state still reset
SB=$(mktemp -d); printf 'not json' | CLAUDE_PROJECT_DIR="$SB" bash "$HOOK"; echo "garbage exit=$?"
test -f "$SB/.claude/state/default/turn-budget.json" && echo "RESET ON GARBAGE OK"
# first run: no metrics/ or prompts/ dir exists yet → GC must not error out
SB2=$(mktemp -d); echo '{"session_id":"s2","prompt":"hi"}' | CLAUDE_PROJECT_DIR="$SB2" bash "$HOOK"; echo "firstrun exit=$?"
```

Expected: `SYNTAX OK`, `garbage exit=0`, `RESET ON GARBAGE OK`, `firstrun exit=0`.

- [ ] **2.6 Commit.** Propose `feat(hooks): replace 7-day session GC with single 14-day day-file GC`.

---

## Task 3 — `metrics-report.sh`: read all `metrics/*.jsonl` day-files (+ legacy)

> **Status: DONE** — RED→GREEN verified (aggregates across day-files + legacy, bypass rate 50%; empty-state → "no metrics data yet" with no crash; `bash -n` clean). Awaiting human commit.

**Files:**
- Modify: `scripts/metrics-report.sh:15` and the two `[[ -s "$METRICS" ]]` / `jq -rs … "$METRICS"` uses (lines 24–25, 32, 45–46)

**Interfaces:**
- Consumes: telemetry records produced by Task 1 in `.claude/state/metrics/*.jsonl` (+ a legacy `_metrics.jsonl` while it survives the 14-day window).
- Produces: the same report, aggregated across all day-files.

- [ ] **3.1 Failing fixture — multi-day metrics + a legacy file.**

```bash
SCRIPT=scripts/metrics-report.sh
SB=$(mktemp -d); ST="$SB/.claude/state"; mkdir -p "$ST/metrics"
printf '%s\n' '{"v":1,"type":"skill_event","event":"bypass","skill":"grilling"}'         > "$ST/metrics/2026-06-10.jsonl"
printf '%s\n' '{"v":1,"type":"skill_event","event":"used_correctly","skill":"grilling"}' > "$ST/metrics/2026-06-20.jsonl"
printf '%s\n' '{"v":1,"type":"friction","class":"error","count":2}'                       > "$ST/_metrics.jsonl"
OUT=$(bash "$SCRIPT" "$SB")
[[ "$OUT" == *"bypass: 1"* ]] && echo "GREEN-already?" || echo "RED: day-files ignored"
```

- [ ] **3.2 Confirm RED:** prints `RED: day-files ignored` (the script reads only `_metrics.jsonl`, so the two `metrics/*.jsonl` skill_events are invisible — no `bypass: 1` in the output).

- [ ] **3.3 Apply fix — replace line 15 (and reuse `STATE_DIR` from line 16).**

```bash
# BEFORE (line 15)
METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"
# AFTER (delete line 15; after the existing `STATE_DIR="$PROJECT_DIR/.claude/state"` add:)
shopt -s nullglob
METRICS_FILES=("$STATE_DIR"/metrics/*.jsonl)                               # nullglob drops the glob when empty
[[ -f "$STATE_DIR/_metrics.jsonl" ]] && METRICS_FILES+=("$STATE_DIR/_metrics.jsonl")   # legacy, only if it still exists
# NOTE: nullglob suppresses only an empty GLOB — an explicit path like _metrics.jsonl is NOT dropped when
# absent, so it MUST be appended conditionally, else jq -rs gets a non-existent path and crashes the
# empty-state + post-14d-transition cases.
```

- [ ] **3.4 Apply fix — the two guards + two jq reads.**

```bash
# Skill-routing section (was line 24): [[ -s "$METRICS" ]]  ->  (( ${#METRICS_FILES[@]} > 0 ))
# Friction section    (was line 45): [[ -s "$METRICS" ]]  ->  (( ${#METRICS_FILES[@]} > 0 ))
# Both `jq -rs '...' "$METRICS"`     ->  jq -rs '...' "${METRICS_FILES[@]}"
```

- [ ] **3.5 Confirm GREEN — re-run 3.1's seed, assert aggregation.**

```bash
SCRIPT=scripts/metrics-report.sh
SB=$(mktemp -d); ST="$SB/.claude/state"; mkdir -p "$ST/metrics"
printf '%s\n' '{"v":1,"type":"skill_event","event":"bypass","skill":"grilling"}'         > "$ST/metrics/2026-06-10.jsonl"
printf '%s\n' '{"v":1,"type":"skill_event","event":"used_correctly","skill":"grilling"}' > "$ST/metrics/2026-06-20.jsonl"
printf '%s\n' '{"v":1,"type":"friction","class":"error","count":2}'                       > "$ST/_metrics.jsonl"
OUT=$(bash "$SCRIPT" "$SB")
[[ "$OUT" == *"bypass: 1"* ]]          && echo "BYPASS OK"
[[ "$OUT" == *"used_correctly: 1"* ]]  && echo "UC OK"
[[ "$OUT" == *"error: 2"* ]]           && echo "FRICTION OK"
[[ "$OUT" == *"= 50%"* ]]              && echo "RATE OK"
```

Expected: `BYPASS OK` + `UC OK` + `FRICTION OK` + `RATE OK`.

- [ ] **3.6 Empty-state + syntax check.**

```bash
SCRIPT=scripts/metrics-report.sh
bash -n "$SCRIPT" && echo "SYNTAX OK"
SB2=$(mktemp -d); mkdir -p "$SB2/.claude/state"
OUT2=$(bash "$SCRIPT" "$SB2")
[[ "$OUT2" == *"no"* ]] && echo "EMPTY OK"   # "no _metrics.jsonl data yet" / "no ... data yet"
```

Expected: `SYNTAX OK` + `EMPTY OK` (no crash on an empty `.claude/state`, no `unbound variable` from the array under `set -u`).

- [ ] **3.7 Commit.** Propose `feat(scripts): read dated metrics/*.jsonl day-files in metrics-report`.

---

## Notes for the executor

- **Tasks are independent** (each touches different files; Task 3's GREEN reads only files it seeds, not Task 1's writers). Suitable for `subagent-driven-development` (a fresh subagent per task with review gates) — but Tasks 1 and 3 share the `metrics/` path contract, so the reviewer should confirm both use `.claude/state/metrics/<UTC>.jsonl` identically.
- **Do NOT touch** `reset-turn-budget`'s line 12 `touch "$STATE_DIR"` or the prompt-corpus block (lines 36–45) — only the GC block (19–21) changes.
- After all three tasks, `hooks.json` is unchanged (no event wiring changes in 3b).
