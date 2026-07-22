#!/usr/bin/env bash
# Fail-open: missing lib / absent jq / non-JSON stdin / missing routing -> exit 0, no output.
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib → fail open (`.` is special: guard readability first)
. "$GUARDRAILS_LIB"
command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
hook_require_json "$INPUT"

TRIGGER=$(hook_field "$INPUT" '.trigger // ""')
[ "$TRIGGER" = "auto" ] || exit 0

ROUTING="${CLAUDE_PROJECT_DIR:-.}/.claude/skills-routing.json"
jq -e '.skills.handoff' "$ROUTING" >/dev/null 2>&1 || exit 0

CONTEXT="Context is about to be auto-compacted. If you have unfinished work whose plan or state lives only in this context (not yet on disk), invoke the handoff skill now to persist a resumable plan before the compaction, and re-read that file afterwards."
MSG="PreCompact: unfinished work? consider the handoff skill before context is compacted."

jq -cn --arg c "$CONTEXT" --arg m "$MSG" \
  '{systemMessage:$m, hookSpecificOutput:{hookEventName:"PreCompact", additionalContext:$c}}' \
  2>/dev/null || exit 0
exit 0
