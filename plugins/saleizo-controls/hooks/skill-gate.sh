#!/usr/bin/env bash
set -uo pipefail

# Fail open if prerequisites missing.
GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is a special builtin: under set -e its open-failure exits the shell before `|| exit 0` can run, so guard readability first)
. "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
SID=$(hook_sid "$INPUT")
STATE_DIR=$(hook_state_dir "$SID")
ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
TURN_SKILLS_FILE="$STATE_DIR/turn-skills-invoked.json"
TURN_READS_FILE="$STATE_DIR/turn-reads.json"
LAST_PROMPT_FILE="$STATE_DIR/last-prompt.txt"
mkdir -p "$STATE_DIR" 2>/dev/null || true
[[ -f "$ROUTING" ]] || exit 0
TOOL=$(hook_field "$INPUT" '.tool_name // ""')
case "$TOOL" in
  Edit|Write|MultiEdit) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(hook_field "$INPUT" '.tool_input.file_path // ""')
[[ -n "$FILE_PATH" ]] || exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
REL_PATH="${FILE_PATH#$PROJECT_DIR/}"

case "$FILE_PATH" in
  */.claude/projects/*/memory/*|*/.claude/projects/*/MEMORY.md)
    MREASON="Write blocked: local Claude memory is forbidden in this project. The memory dir is per-user and not in git, so several teammates never see it. Persist the fact where the team can: an incident/learned fact -> append to .claude/lessons-learned.md; a recurring rule -> .claude/rules/<area>/<topic>.md. This barrier is intentional and model-agnostic."
    jq -cn --arg r "$MREASON" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
      2>/dev/null || exit 0
    exit 0
    ;;
esac

[[ -f "$TURN_SKILLS_FILE" ]] || echo '[]' > "$TURN_SKILLS_FILE"

MISSED_SKILL=""
MISSED_GLOB=""
while IFS=$'\t' read -r skill glob; do
  [[ -n "$skill" && -n "$glob" ]] || continue
  if [[ "$REL_PATH" == "$glob"* ]]; then
    INVOKED=$(jq -r --arg s "$skill" 'index($s) // "null"' "$TURN_SKILLS_FILE" 2>/dev/null || echo "null")
    if [[ "$INVOKED" == "null" ]]; then
      MISSED_SKILL="$skill"
      MISSED_GLOB="$glob"
      break
    fi
  fi
done < <(jq -r '.skills | to_entries[] | .key as $k | (.value.editGlobs // [])[] | "\($k)\t\(.)"' "$ROUTING" 2>/dev/null)

if [[ -n "$MISSED_SKILL" ]]; then
  REASON="Edit blocked by skill-gate: '${REL_PATH}' is in the '${MISSED_GLOB}' domain owned by Skill '${MISSED_SKILL}', which carries that domain's rules. Invoke Skill('${MISSED_SKILL}') first to load those rules, then retry this edit. This barrier is intentional and model-agnostic — it keeps rule-following stable across model versions."
  jq -cn --arg r "$REASON" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
    2>/dev/null || exit 0
  exit 0
fi

[[ -f "$TURN_READS_FILE" ]] || echo '[]' > "$TURN_READS_FILE"
PROMPT=""
[[ -f "$LAST_PROMPT_FILE" ]] && PROMPT=$(cat "$LAST_PROMPT_FILE" 2>/dev/null || echo "")

GATE_RULE=""
GATE_WHY=""
while IFS=$'\t' read -r gate rule; do
  [[ -n "$gate" && -n "$rule" ]] || continue

  LOADED=$(jq -r --arg r "$rule" 'index($r) // "null"' "$TURN_READS_FILE" 2>/dev/null || echo "null")
  [[ "$LOADED" == "null" ]] || continue

  FIRED=""
  while IFS= read -r glob; do
    [[ -n "$glob" ]] || continue
    if [[ "$REL_PATH" == "$glob"* ]]; then FIRED="path"; break; fi
  done < <(jq -r --arg g "$gate" '.ruleGates[$g].editGlobs // [] | .[]' "$ROUTING" 2>/dev/null)

  if [[ -z "$FIRED" && -n "$PROMPT" ]]; then
    TRIG=$(jq -r --arg g "$gate" '.ruleGates[$g].promptTriggers // [] | join("|")' "$ROUTING" 2>/dev/null)
    if [[ -n "$TRIG" ]] && printf '%s' "$PROMPT" | grep -qiE "$TRIG"; then FIRED="prompt"; fi
  fi

  if [[ -n "$FIRED" ]]; then
    GATE_RULE="$rule"
    GATE_WHY="$FIRED"
    break
  fi
done < <(jq -r '.ruleGates // {} | to_entries[] | select(.key != "_comment") | "\(.key)\t\(.value.rule)"' "$ROUTING" 2>/dev/null)

if [[ -n "$GATE_RULE" ]]; then
  if [[ "$GATE_WHY" == "path" ]]; then
    WHY="'${REL_PATH}' is in a gated domain"
  else
    WHY="your task matches a gated domain by keyword"
  fi
  REASON="Edit blocked by rule-gate: ${WHY}, which requires '${GATE_RULE}' to be loaded into context first. Read('${GATE_RULE}') this turn, then retry this edit. This file pins which rule owns this domain — editing without it is the recurring cross-domain bug this barrier exists to prevent. Intentional and model-agnostic."
  jq -cn --arg r "$REASON" \
    '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
    2>/dev/null || exit 0
  exit 0
fi

TASKLIST_FLAG="$STATE_DIR/session-tasklist-seeded.flag"
if [[ ! -f "$TASKLIST_FLAG" && -n "$PROMPT" ]]; then
  TLG=$(jq -r '.taskListGate.promptTriggers // [] | join("|")' "$ROUTING" 2>/dev/null)
  if [[ -n "$TLG" ]] && printf '%s' "$PROMPT" | grep -qiE "$TLG"; then
    REASON="Edit blocked by task-list gate: your task matches an SDD run but no harness task list has been seeded this session. Seed the canonical phase progress list first (create it with the task tool), per 'phase-task-visualization', so the list exists and mirrors the approval gate before the first artifact. This barrier is intentional and model-agnostic."
    jq -cn --arg r "$REASON" \
      '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$r}}' \
      2>/dev/null || exit 0
    exit 0
  fi
fi

exit 0
