# Spec — telemetry daily-rotation + 14-day GC (build 3b)

Source of requirements: the approved logging architecture in [docs/audits/2026-06-24-guardrails-kit-hooks.md](../audits/2026-06-24-guardrails-kit-hooks.md) ("Proposed logging architecture" → "Retention / rotation"; "Improvements" #5) and this session's `sdd-lifecycle` entry classification for build 3b (the next decomposed slice of handoff item #3, after 3a shipped the prompt corpus). No ticket, so the optional Source provenance block is omitted.

## Goal

Roll the telemetry stream into dated day-files (`.claude/state/metrics/YYYY-MM-DD.jsonl`) instead of one unbounded `_metrics.jsonl`, and replace the 7-day per-session-dir GC in `reset-turn-budget.sh` with a single 14-day GC that prunes both telemetry and prompt-corpus day-files (and, until build 3c lands, the per-session scratch dirs). The prompt corpus is already dated (build 3a); this build adds the matching telemetry rotation and the unified pruning.

## Scope

- **`log-skill-usage.sh`** (`Stop`): change the `METRICS` target from `.claude/state/_metrics.jsonl` to `.claude/state/metrics/$(date -u +%F).jsonl`. Record shapes (`skill_event`) are unchanged.
- **`friction-log.sh`** (`Stop`): same `METRICS` path change. `friction` record shape unchanged.
- **`detect-bypass.sh`** (`PostToolUse`): same `METRICS` path change. `skill_event` record shapes unchanged.
- **`reset-turn-budget.sh`** (`UserPromptSubmit`): replace the existing `GC_DAYS=7` session-dir `find` (lines 19–21) with `GC_DAYS=14` and a single GC block that prunes, by mtime: (1) `metrics/*.jsonl` + `prompts/*.jsonl` day-files older than 14 days, (2) the legacy root `_metrics.jsonl` once it ages out, (3) per-session scratch dirs older than 14 days (retained until build 3c relocates scratch to `${TMPDIR}`). The GC stays *after* the existing `touch "$STATE_DIR"` (line 12), so the live session dir's mtime is fresh and never collected (preserves the H1 fix).
- **`scripts/metrics-report.sh`** (consumer): read all `metrics/*.jsonl` day-files (plus the legacy `_metrics.jsonl` while it still exists) instead of the single file.

## Out of scope

- **`SessionEnd` teardown / `${TMPDIR}` scratch move** (build 3c — gated on first verifying a `SessionEnd` hook event exists). 3b keeps pruning session dirs by mtime as a stopgap.
- **State-contract doc** (build 3d).
- **Consolidated logging ADR-0002** — due once 3b + 3c land (handoff); not this build.
- **Prompt-corpus record/writer changes** (shipped in 3a) — `prompts/` is already dated; 3b only adds it to the GC sweep, it does not touch `log-skill-usage`'s corpus-finalize block beyond the shared `METRICS` path line.
- **Filename-date parsing for retention** — pruning is by file **mtime** (the existing idiom), not by parsing `YYYY-MM-DD` out of the name.
- **Migrating historical `_metrics.jsonl` content** into dated files — the legacy file is read in place until it ages out of the 14-day window, then GC removes it. No copy/rewrite.
- **Tightening trigger phrases / bypass-line volume** (M2 tail) — separate deferred item.
- **`token-guard` per-session `by-model-budget.json`** — read by the consumer's token section; not a day-file, not in this build's GC.

## Contracts

### Telemetry stream — record shapes UNCHANGED, file location CHANGED

Records keep their v1 shapes; only the path moves from a single file to a dated day-file.

```bash
# BEFORE (all 3 writers):
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/_metrics.jsonl"
# AFTER:
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/metrics/$(date -u +%F).jsonl"
# The existing `mkdir -p "$(dirname "$METRICS")"` in each hook now creates the metrics/ dir.
```

```json
{ "v": 1, "type": "skill_event", "ts": "...", "session": "0052fd0a", "prompt_hash": "...", "skill": "grilling", "event": "bypass" }
{ "v": 1, "type": "friction",    "ts": "...", "session": "0052fd0a", "class": "error", "count": 1 }
```

### GC block (replaces `reset-turn-budget.sh` lines 19–21)

```bash
# Single 14-day GC. Runs AFTER `touch "$STATE_DIR"` (line 12) so the live session dir is never
# collected. Fail-open: a GC error must not disrupt the turn reset.
GC_DAYS=14
STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
# (1) Dated telemetry + corpus day-files, and the pre-3b legacy single file, older than GC_DAYS.
#     Three -maxdepth-1 roots: STATE_BASE (legacy _metrics.jsonl) + metrics/ + prompts/.
find "$STATE_BASE" "$STATE_BASE/metrics" "$STATE_BASE/prompts" \
  -maxdepth 1 -type f -name '*.jsonl' -mtime +"$GC_DAYS" -delete 2>/dev/null || true
# (2) Per-session scratch dirs older than GC_DAYS (kept until build 3c moves scratch to ${TMPDIR}).
find "$STATE_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +"$GC_DAYS" -exec rm -rf {} + 2>/dev/null || true
```

### Consumer — `metrics-report.sh` file selection

```bash
# BEFORE: METRICS="$PROJECT_DIR/.claude/state/_metrics.jsonl"   (used at -s and `jq -rs ... "$METRICS"`)
# AFTER:
shopt -s nullglob
METRICS_FILES=("$STATE_DIR"/metrics/*.jsonl)                               # nullglob drops the glob when empty
[[ -f "$STATE_DIR/_metrics.jsonl" ]] && METRICS_FILES+=("$STATE_DIR/_metrics.jsonl")   # legacy, only if still present
# guard: (( ${#METRICS_FILES[@]} > 0 )) instead of [[ -s "$METRICS" ]]
# read:  jq -rs '...' "${METRICS_FILES[@]}"   (slurps all day-files into one array)
# NOTE: nullglob suppresses only an empty GLOB; an explicit absent path is NOT dropped, so the legacy
# file is appended conditionally — otherwise jq gets a non-existent path on empty-state / post-14d runs.
```

## Files touched

| File | Change | Why |
| --- | --- | --- |
| `plugins/guardrails-kit/hooks/log-skill-usage.sh` | EDIT | `METRICS` → `metrics/YYYY-MM-DD.jsonl` (line 15) |
| `plugins/guardrails-kit/hooks/friction-log.sh` | EDIT | `METRICS` → `metrics/YYYY-MM-DD.jsonl` (line 29) |
| `plugins/guardrails-kit/hooks/detect-bypass.sh` | EDIT | `METRICS` → `metrics/YYYY-MM-DD.jsonl` (line 18) |
| `plugins/guardrails-kit/hooks/reset-turn-budget.sh` | EDIT | replace 7-day session-dir GC (lines 19–21) with single 14-day day-file + session-dir + legacy GC |
| `scripts/metrics-report.sh` | EDIT | glob `metrics/*.jsonl` (+ legacy `_metrics.jsonl`) instead of single file (lines 15, 24–50) |

## Edge cases

- **Empty / first run (no `metrics/` or `prompts/` dir yet):** GC find over a missing start-path errors to stderr → suppressed by `2>/dev/null || true` (fail-open). Consumer's `nullglob` yields an array of just the legacy file (or empty) → "no data yet" branch when empty.
- **Live session dir:** `touch "$STATE_DIR"` (line 12) refreshes its mtime before the GC runs, so the active dir is never the >14d target — the H1 crash-and-state-loss fix is preserved (the GC ordering after `touch` is load-bearing).
- **Resumed >14d-idle session:** its old day-files are pruned (intended); its session scratch dir is pruned only if its mtime is >14d AND it is not the current dir (current dir touched fresh this turn).
- **Legacy `_metrics.jsonl` transition:** writers stop appending to it on this build, so its mtime freezes; the consumer keeps reading it until it ages past 14 days, then GC `-delete` removes it. No data loss, no manual migration.
- **Midnight rollover inside a Stop hook:** `date -u +%F` is evaluated once per hook invocation, so the record lands in the day-file for the day the hook started. Negligible, accepted.
- **Concurrent appends to the same day-file:** `>>` append of a single short JSON line is atomic (same guarantee as today's single-file append) — no new race.
- **Garbage / non-JSON stdin, `jq` absent:** unchanged fail-open `exit 0` in every hook (the lib readability guard + `hook_require_json` paths are untouched).

## Verification

No `pnpm`/build/unit-test pipeline — this is the vault. Each hook change is verified by `writing-hooks` fixture-execution (crafted stdin → run script → assert decision + fail-open on garbage), plus `bash -n` and `jq` on JSON:

- **`reset-turn-budget.sh`:** seed a sandbox `.claude/state` with a stale (`touch -t` >14d) `metrics/2026-05-01.jsonl`, a fresh `metrics/<today>.jsonl`, a stale `prompts/2026-05-01.jsonl`, a stale `_metrics.jsonl`, a stale session dir, and a fresh session dir; pipe a valid prompt → assert the stale day-files + stale legacy + stale dir are gone and the fresh files + a freshly-`touch`ed current session dir remain; garbage stdin → `exit 0`, state still reset.
- **`log-skill-usage.sh` / `friction-log.sh` / `detect-bypass.sh`:** crafted stdin that produces a metric → assert the line lands in `.claude/state/metrics/<today>.jsonl` and that no `_metrics.jsonl` is created; garbage stdin / missing lib → `exit 0`.
- **`scripts/metrics-report.sh`:** sandbox with two `metrics/*.jsonl` day-files (+ a legacy file) → assert the report aggregates across all of them; empty `.claude/state` → "no data yet".
- `bash -n` on all four hooks + the script; `jq -e .` on every emitted record.

## Risks

- **`find` with a non-existent start-path** (`metrics/`/`prompts/` before first write) emits a stderr error and could, on some `find` builds, set a non-zero exit — mitigation: `2>/dev/null || true` makes it fail-open, matching the existing GC idiom and the vault's hook conventions.
- **mtime-based retention drift** — a day-file's mtime is its last-write time, so a low-traffic day's file could be pruned up to ~1 day off its filename date — mitigation: accepted; mtime is the existing portable idiom and avoids non-portable filename-date parsing (the alternative was explicitly cut to Out-of-scope).
- **BSD vs GNU `find`** — `-mtime +N`, `-delete`, `-maxdepth`, and `-exec … +` are all supported on both macOS (BSD, the dev machine) and GNU find; no GNU-only flag is used.
- **Session-dir pruning is a stopgap** — until 3c relocates scratch to `${TMPDIR}`, ended sessions' dirs still linger up to 14 days; this is a known, intentional gap recorded here and closed by 3c.
