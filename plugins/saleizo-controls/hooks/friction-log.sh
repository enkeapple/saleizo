#!/usr/bin/env bash
# Fail-open: any error / missing transcript / no jq exits 0 with no output.
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
command -v jq >/dev/null 2>&1 || exit 0
SID=$(hook_sid "$INPUT")
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
STATE_DIR="$PROJECT_DIR/.claude/state/$SID"
METRICS="$PROJECT_DIR/.claude/state/metrics/$(date -u +%F).jsonl"
SEEN_FILE="$STATE_DIR/friction-seen.json"

TRANSCRIPT=$(hook_field "$INPUT" '.transcript_path // empty')
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || exit 0

mkdir -p "$STATE_DIR" "$(dirname "$METRICS")" 2>/dev/null || exit 0
[ -f "$SEEN_FILE" ] || echo '{"denied":0,"blocked":0,"error":0}' > "$SEEN_FILE"

TEXTS=$(jq -rc '
  select((.message.content // empty) | type == "array")
  | .message.content[]
  | select((type == "object") and (.type == "tool_result") and (.is_error == true))
  | (if (.content | type) == "array" then (.content | map(.text? // "") | join(" ")) else (.content | tostring) end)
  | gsub("[\r\n]+"; " ")
' "$TRANSCRIPT" 2>/dev/null) || exit 0

clean_int() { local n="${1//[^0-9]/}"; printf '%s' "${n:-0}"; }
cur_denied=$(clean_int "$(printf '%s\n' "$TEXTS" | grep -ciE "user (doesn'?t|does not|did ?n'?t) want|user rejected|user declined|don'?t want to proceed" 2>/dev/null)")
cur_blocked=$(clean_int "$(printf '%s\n' "$TEXTS" | grep -ciE 'hook error|BLOCKED:' 2>/dev/null)")
cur_total=$(clean_int "$(printf '%s\n' "$TEXTS" | grep -c . 2>/dev/null)")
cur_error=$(( cur_total - cur_denied - cur_blocked ))
(( cur_error < 0 )) && cur_error=0

s_denied=$(jq -r '.denied // 0' "$SEEN_FILE" 2>/dev/null || echo 0)
s_blocked=$(jq -r '.blocked // 0' "$SEEN_FILE" 2>/dev/null || echo 0)
s_error=$(jq -r '.error // 0' "$SEEN_FILE" 2>/dev/null || echo 0)

emit() {
  local cls="$1" d="$2"
  (( d > 0 )) || return 0
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg c "$cls" --argjson n "$d" \
    '{v:1, type:"friction", ts:$ts, session:$sid, class:$c, count:$n}' >> "$METRICS" 2>/dev/null || true
}
emit denied  $(( cur_denied  - s_denied ))
emit blocked $(( cur_blocked - s_blocked ))
emit error   $(( cur_error   - s_error ))

jq -cn --argjson d "$cur_denied" --argjson b "$cur_blocked" --argjson e "$cur_error" \
  '{denied:$d, blocked:$b, error:$e}' > "$SEEN_FILE.tmp" 2>/dev/null && mv "$SEEN_FILE.tmp" "$SEEN_FILE"

exit 0
