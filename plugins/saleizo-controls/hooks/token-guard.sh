#!/usr/bin/env bash

set -euo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
TURN_FILE="$STATE_DIR/turn-budget.json"
SESSION_FILE="$STATE_DIR/session-budget.json"
BY_MODEL_FILE="$STATE_DIR/by-model-budget.json"

WARN_PER_TOOL=60000
WARN_PER_TURN=80000
HARD_STOP_PER_TURN=450000
WARN_PER_SESSION=3000000

mkdir -p "$STATE_DIR"
[[ -f "$TURN_FILE" ]] || echo '{"bytes":0,"tools":[]}' > "$TURN_FILE"
[[ -f "$SESSION_FILE" ]] || echo "{\"bytes\":0,\"started_at\":\"$(date -u +%FT%TZ)\"}" > "$SESSION_FILE"
[[ -f "$BY_MODEL_FILE" ]] || echo '{}' > "$BY_MODEL_FILE"

TOOL_NAME=$(hook_field "$INPUT" '.tool_name // "unknown"')
RESP_BYTES=$(hook_field "$INPUT" '.tool_response | if type=="string" then . else tostring end' | wc -c | tr -d ' ')
RESP_TOKENS=$(( RESP_BYTES / 4 ))

TURN_BYTES=$(jq -r '.bytes' "$TURN_FILE")
NEW_TURN_BYTES=$(( TURN_BYTES + RESP_BYTES ))
hook_json_update "$TURN_FILE" --argjson b "$NEW_TURN_BYTES" --arg n "$TOOL_NAME" --argjson tb "$RESP_BYTES" --arg ts "$(date -u +%FT%TZ)" \
   '.bytes=$b | .tools += [{name:$n, bytes:$tb, ts:$ts}]'

SESS_BYTES=$(jq -r '.bytes' "$SESSION_FILE")
NEW_SESS_BYTES=$(( SESS_BYTES + RESP_BYTES ))
hook_json_update "$SESSION_FILE" --argjson b "$NEW_SESS_BYTES" '.bytes=$b'

KEY=$(hook_field "$INPUT" '.tool_input.model // .tool_input.subagent_type // "inherited"')
hook_json_update "$BY_MODEL_FILE" --arg m "$KEY" --argjson b "$RESP_BYTES" '.[$m] = ((.[$m] // 0) + $b)'

TURN_TOKENS=$(( NEW_TURN_BYTES / 4 ))
SESS_TOKENS=$(( NEW_SESS_BYTES / 4 ))

if (( RESP_TOKENS > WARN_PER_TOOL )); then
  echo "TOKEN-GUARD warn: tool '$TOOL_NAME' returned ~${RESP_TOKENS} tokens (threshold ${WARN_PER_TOOL}). Narrow next read." >&2
fi

if (( TURN_TOKENS > HARD_STOP_PER_TURN )); then
  echo "TOKEN-GUARD hard-stop: turn consumed ~${TURN_TOKENS} tokens (>${HARD_STOP_PER_TURN}). Stop. Summarize findings and ask user before continuing." >&2
  exit 2
fi

if (( TURN_TOKENS > WARN_PER_TURN )); then
  echo "TOKEN-GUARD warn: turn at ~${TURN_TOKENS} tokens (threshold ${WARN_PER_TURN}). Consider wrapping up." >&2
fi

if (( SESS_TOKENS > WARN_PER_SESSION )); then
  echo "TOKEN-GUARD warn: session at ~${SESS_TOKENS} tokens (>${WARN_PER_SESSION}). Consider switching to Sonnet subagent or /compact." >&2
fi

exit 0
