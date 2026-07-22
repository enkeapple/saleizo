#!/usr/bin/env bash
# Fail-open: missing lib / absent jq / non-JSON stdin / missing report script / no data → exit 0, no output.
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is special: guard readability first)
. "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"

# Stdout-silent and fully fail-open so a normal or resumed session is never disrupted.
CUR_SID=$(hook_sid "$INPUT")
STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
FIN_METRICS="$STATE_BASE/metrics/$(date -u +%F).jsonl"
mkdir -p "$(dirname "$FIN_METRICS")" 2>/dev/null || true
for pf in "$STATE_BASE"/*/pending-triggers.json; do
  [ -f "$pf" ] || continue
  sdir=$(basename "$(dirname "$pf")")
  [ "$sdir" = "$CUR_SID" ] && continue
  while IFS= read -r skill; do
    [ -n "$skill" ] || continue
    jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$sdir" --arg s "$skill" \
      '{v:1, type:"skill_event", ts:$ts, session:$sid, skill:$s, event:"bypass"}' >> "$FIN_METRICS" 2>/dev/null || true
  done < <(jq -r '.[]?' "$pf" 2>/dev/null || true)
  echo '[]' > "$pf" 2>/dev/null || true
done

SRC=$(hook_field "$INPUT" '.source // ""')
[ "$SRC" = "startup" ] || exit 0

# Reuse the repo's metrics-report script for canonical aggregates; absent → silent (fail-open).
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
REPORT="$PROJECT_DIR/scripts/metrics-report.sh"
[ -f "$REPORT" ] || exit 0
OUT=$(bash "$REPORT" "$PROJECT_DIR" 2>/dev/null) || exit 0

printf '%s' "$OUT" | grep -q '^- bypass:' || exit 0

DIGEST=$(printf '%s\n' "$OUT" | awk '/^## Skill routing/{p=1} /^## Token spend/{p=0} p{print}')
[ -n "$DIGEST" ] || exit 0
CONTEXT=$(printf '%s\n\n→ Run the reviewing-telemetry skill for the per-skill triage and recommended actions.' "$DIGEST")

jq -cn --arg c "$CONTEXT" \
  '{hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$c}}' \
  2>/dev/null || exit 0
exit 0
