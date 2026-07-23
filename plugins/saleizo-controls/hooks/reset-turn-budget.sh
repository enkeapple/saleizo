#!/usr/bin/env bash
set -euo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || INPUT=""
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
mkdir -p "$STATE_DIR"
touch "$STATE_DIR"

# Fail-open: a GC error must not disrupt the turn reset.
GC_DAYS=14
STATE_BASE="${CLAUDE_PROJECT_DIR:-.}/.claude/state"
find "$STATE_BASE" "$STATE_BASE/metrics" "$STATE_BASE/prompts" \
  -maxdepth 1 -type f -name '*.jsonl' -mtime +"$GC_DAYS" -delete 2>/dev/null || true
find "$STATE_BASE" -mindepth 1 -maxdepth 1 -type d -mtime +"$GC_DAYS" -exec rm -rf {} + 2>/dev/null || true

echo '{"bytes":0,"tools":[]}' > "$STATE_DIR/turn-budget.json"
echo '[]' > "$STATE_DIR/turn-skills-invoked.json"
echo '[]' > "$STATE_DIR/turn-reads.json"
echo '{"count":0}' > "$STATE_DIR/turn-tool-count.json"
rm -f "$STATE_DIR/turn-bypass-warned.flag"
rm -f "$STATE_DIR/turn-lessons-nudged.flag"

# Fail open: per-turn state was already reset above; non-JSON stdin just skips caching.
printf '%s' "$INPUT" | jq -e . >/dev/null 2>&1 || exit 0
PROMPT=$(hook_field "$INPUT" '.prompt // .user_prompt // ""')

# A slash command is an EXPLICIT skill invocation, but a skill loaded that way emits no
# `Skill`-tool PostToolUse event — so without this it is never recorded as used, `used_correctly`
# is never emitted, and the bypass rate reads a structural 100%. Credit it here (metric denominator)
# and drop it from pending-triggers so an earlier keyword-match can't later flush as a false bypass.
# Alias facades map to their canonical routed skill.
if [[ "$PROMPT" =~ ^[[:space:]]*/ ]]; then
  CMD=$(printf '%s' "$PROMPT" | sed -E 's|^[[:space:]]*/([^[:space:]]+).*|\1|')
  CMD="${CMD##*:}"
  case "$CMD" in
    sdd) CMD=sdd-lifecycle;; grill) CMD=grilling;; spec) CMD=writing-specs;;
    audit) CMD=verifying-implementation;; adr) CMD=writing-adrs;;
  esac
  ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
  if [[ -n "$CMD" && -f "$ROUTING" ]] && jq -e --arg s "$CMD" '.skills | has($s)' "$ROUTING" >/dev/null 2>&1; then
    METRICS="${CLAUDE_PROJECT_DIR:-.}/.claude/state/metrics/$(date -u +%F).jsonl"
    mkdir -p "$(dirname "$METRICS")" 2>/dev/null || true
    jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --arg s "$CMD" \
      '{v:1, type:"skill_event", ts:$ts, session:$sid, skill:$s, event:"used_correctly"}' \
      >> "$METRICS" 2>/dev/null || true
    PEND="$STATE_DIR/pending-triggers.json"
    if [[ -f "$PEND" ]]; then hook_json_update "$PEND" --arg s "$CMD" 'map(select(. != $s))' || true; fi
    # Record it as invoked this turn too, so skill-gate's editGlobs gate and the
    # cross-turn resolution treat a slash invocation the same as a Skill-tool call.
    hook_json_update "$STATE_DIR/turn-skills-invoked.json" --arg s "$CMD" '. + [$s] | unique' || true
  fi
fi

if [[ "$PROMPT" =~ ^[[:space:]]*'<task-notification>' ]] || [[ "$PROMPT" =~ ^[[:space:]]*/ ]]; then
  : > "$STATE_DIR/last-prompt.txt"
  rm -f "$STATE_DIR/pending-prompt.json"
  exit 0
fi

printf '%s' "$PROMPT" > "$STATE_DIR/last-prompt.txt"

TURN_N_FILE="$STATE_DIR/session-turn.json"
[ -f "$TURN_N_FILE" ] || echo '{"n":0}' > "$TURN_N_FILE"
TURN_N=$(( $(jq -r '.n // 0' "$TURN_N_FILE" 2>/dev/null || echo 0) + 1 ))
jq -cn --argjson n "$TURN_N" '{n:$n}' > "$TURN_N_FILE.tmp" 2>/dev/null && mv "$TURN_N_FILE.tmp" "$TURN_N_FILE" || true
jq -cn --arg ts "$(date -u +%FT%TZ)" --arg sid "$SID" --argjson turn "$TURN_N" --arg p "$PROMPT" \
  '{v:1, type:"prompt", ts:$ts, session:$sid, turn:$turn, prompt:$p, chars:($p|length)}' \
  > "$STATE_DIR/pending-prompt.json.tmp" 2>/dev/null \
  && mv "$STATE_DIR/pending-prompt.json.tmp" "$STATE_DIR/pending-prompt.json" || true

exit 0
