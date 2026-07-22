#!/usr/bin/env bash
set -euo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/metrics/$(date -u +%F).jsonl"
TURN_SKILLS_FILE="$STATE_DIR/turn-skills-invoked.json"
LAST_PROMPT_FILE="$STATE_DIR/last-prompt.txt"

mkdir -p "$STATE_DIR" "$(dirname "$METRICS")"
[[ -f "$ROUTING" ]] || exit 0

TRANSCRIPT=$(hook_field "$INPUT" '.transcript_path // ""')

USER_PROMPT=""
if [[ -f "$LAST_PROMPT_FILE" ]]; then
  USER_PROMPT=$(cat "$LAST_PROMPT_FILE")
elif [[ -f "$TRANSCRIPT" ]]; then
  USER_PROMPT=$(tail -r "$TRANSCRIPT" 2>/dev/null | grep -m1 '"role":"user"' | jq -r '.message.content // .content // ""' 2>/dev/null || echo "")
fi

[[ -n "$USER_PROMPT" ]] || exit 0

PROMPT_HASH=$(printf '%s' "$USER_PROMPT" | shasum -a 256 | cut -c1-16)

INVOKED_SKILLS=$([[ -f "$TURN_SKILLS_FILE" ]] && cat "$TURN_SKILLS_FILE" || echo '[]')

PENDING_FILE="$STATE_DIR/pending-triggers.json"
[[ -f "$PENDING_FILE" ]] || echo '[]' > "$PENDING_FILE"
PENDING=$(jq -c . "$PENDING_FILE" 2>/dev/null || echo '[]')

MATCHED=$(jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" \
  | while IFS=$'\t' read -r skill trig; do
      [[ -n "$trig" ]] || continue
      if echo "$USER_PROMPT" | grep -qiE "$trig"; then printf '%s\n' "$skill"; fi
    done | jq -R . | jq -cs 'map(select(length>0))')

PENDING=$(jq -cn --argjson a "$PENDING" --argjson b "$MATCHED" '($a + $b) | unique')

RESOLVED=$(jq -cn --argjson pend "$PENDING" --argjson inv "$INVOKED_SKILLS" \
  '$pend | map(select(. as $s | $inv | index($s)))')
printf '%s' "$RESOLVED" | jq -r '.[]' | while IFS= read -r skill; do
  [[ -n "$skill" ]] || continue
  jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg h "$PROMPT_HASH" --arg s "$skill" \
    '{v:1, type:"skill_event", ts:$ts, session:$sid, prompt_hash:$h, skill:$s, event:"used_correctly"}' >> "$METRICS"
done
PENDING=$(jq -cn --argjson pend "$PENDING" --argjson res "$RESOLVED" '$pend - $res')
printf '%s' "$PENDING" > "$PENDING_FILE"

PENDING="$STATE_DIR/pending-prompt.json"
if [[ -f "$PENDING" ]]; then
  PROMPTS_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/state/prompts"
  mkdir -p "$PROMPTS_DIR"
  TRIGGERS_MATCHED=$(jq -r '.skills // {} | to_entries[] | "\(.key)\t\(.value.triggers // [] | join("|"))"' "$ROUTING" \
    | while IFS=$'\t' read -r skill trig; do
        [[ -n "$trig" ]] || continue
        if echo "$USER_PROMPT" | grep -qiE "$trig"; then printf '%s\n' "$skill"; fi
      done | jq -R . | jq -cs .)
  TOOLS_USED=$(jq -r '.count // 0' "$STATE_DIR/turn-tool-count.json" 2>/dev/null || echo 0)
  FRICTION=$(cat "$STATE_DIR/friction-seen.json" 2>/dev/null || echo '{"denied":0,"blocked":0,"error":0}')
  BYPASS=$(printf '%s' "$TRIGGERS_MATCHED" | jq --argjson inv "$INVOKED_SKILLS" 'map(select(($inv | index(.)) | not)) | length > 0')
  jq -cn --slurpfile pend "$PENDING" \
        --argjson tm "$TRIGGERS_MATCHED" --argjson inv "$INVOKED_SKILLS" \
        --argjson tu "$TOOLS_USED" --argjson fr "$FRICTION" --argjson bp "$BYPASS" \
        '$pend[0] + {triggers_matched:$tm, skills_invoked:$inv,
                     lang:(if ($pend[0].prompt|test("[Ѐ-ӿ]")) then "ru" else "en" end),
                     outcome:{tools_used:$tu, friction:$fr, bypass:$bp}}' \
    >> "$PROMPTS_DIR/$(date -u +%F).jsonl" 2>/dev/null || true
  rm -f "$PENDING"
fi

echo '[]' > "$TURN_SKILLS_FILE"
exit 0
