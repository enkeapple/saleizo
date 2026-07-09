#!/usr/bin/env bash
# Metrics report — skill-routing health + token spend by model, from the hook-emitted state.
# Read-only and side-effect-free; safe to run anytime.
#
# Sources (all produced by the framework's hooks; absent → that section says "no data yet"):
#   - .claude/state/metrics/YYYY-MM-DD.jsonl   dated day-files (+ pre-3b legacy _metrics.jsonl while
#                                    it survives the 14-day window). v1 records {v,type,ts,session,…}:
#                                    type=="skill_event" (event: bypass / used_correctly /
#                                    read_instead_of_skill / direct_edit_lessons_log) and type=="friction"
#   - .claude/state/<session_id>/by-model-budget.json   per-session token accounting (token-guard.sh)
#
# Usage: bash scripts/metrics-report.sh [PROJECT_DIR]   (defaults to $CLAUDE_PROJECT_DIR or .)
set -uo pipefail

PROJECT_DIR="${1:-${CLAUDE_PROJECT_DIR:-.}}"
STATE_DIR="$PROJECT_DIR/.claude/state"

# Telemetry now lives in dated day-files under metrics/ (build 3b). nullglob suppresses the glob
# when no day-file exists; the pre-3b legacy single file is appended only if it still exists (an
# explicit absent path is NOT dropped by nullglob and would crash jq on the empty-state case).
shopt -s nullglob
METRICS_FILES=("$STATE_DIR"/metrics/*.jsonl)
[[ -f "$STATE_DIR/_metrics.jsonl" ]] && METRICS_FILES+=("$STATE_DIR/_metrics.jsonl")

command -v jq >/dev/null 2>&1 || { echo "metrics-report: jq is required" >&2; exit 1; }

echo "# Metrics report"
echo
echo "_Fixture/test sessions (session id matching \`fixture\`) are excluded from the routing + friction counts below._"
echo

echo "## Skill routing"
if (( ${#METRICS_FILES[@]} > 0 )); then
  jq -rs '
    map(select(.type == "skill_event" and ((.session // "" | tostring | test("fixture")) | not)))
    | group_by(.event)
    | map({event: (.[0].event // "unknown"), count: length})
    | sort_by(-.count)[]
    | "- \(.event): \(.count)"
  ' "${METRICS_FILES[@]}" 2>/dev/null || echo "- (could not parse metrics day-files)"
  jq -rs '
    map(select((.session // "" | tostring | test("fixture")) | not))
    | (map(select(.event=="bypass")) | length) as $b
    | (map(select(.event=="used_correctly")) | length) as $u
    | if ($b + $u) > 0
      then "\nBypass rate: \($b)/\($b + $u) = \((100 * $b / ($b + $u)) | floor)%"
      else "\nBypass rate: n/a (no triggered events yet)" end
  ' "${METRICS_FILES[@]}" 2>/dev/null
else
  echo "- no metrics data yet"
fi
echo

echo "## Friction (deterministic is_error, by class)"
if (( ${#METRICS_FILES[@]} > 0 )); then
  jq -rs '
    (map(select(.type == "friction" and ((.session // "" | tostring | test("fixture")) | not)))) as $f
    | if ($f | length) == 0 then "- none logged yet"
      else ($f | group_by(.class) | map("- \(.[0].class // "?"): \(map(.count // 0) | add)") | .[]) end
  ' "${METRICS_FILES[@]}" 2>/dev/null || echo "- (could not parse friction events)"
else
  echo "- no metrics data yet"
fi
echo

echo "## Token spend by model (≈ bytes / 4)"
shopt -s nullglob
files=("$STATE_DIR"/*/by-model-budget.json)
if (( ${#files[@]} > 0 )); then
  jq -rs '
    reduce .[] as $f ({};
      reduce ($f | to_entries[]) as $kv (.; .[$kv.key] = ((.[$kv.key] // 0) + $kv.value)))
    | to_entries | sort_by(-.value)[]
    | "- \(.key): \((.value / 4) | floor) tokens"
  ' "${files[@]}" 2>/dev/null || echo "- (could not parse by-model files)"
  echo
  echo "Sessions tracked: ${#files[@]}"
else
  echo "- no by-model-budget data yet (run some tool calls first)"
fi
