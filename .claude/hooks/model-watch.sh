#!/usr/bin/env bash
# SessionStart hook: every session, compare the LIVE model against the EXPECTED model
# pinned in .claude/CLAUDE.md, and surface a banner + recalibration instruction on mismatch.
#
# Why this exists: rules/skills/memory are model-agnostic and always load, but a new model
# is calibrated differently -- the same prompts can yield weaker rule-following. The owner
# must KNOW the model differs from the pinned expectation (predictability of quality over
# time is the core value) and Claude must offer to self-recalibrate, not let the owner
# discover degradation postfactum.
#
# Source of truth = the line in .claude/CLAUDE.md: "Expected model: `claude-opus-4-8`".
# The owner updates that line BY HAND when deliberately moving to a new model. The hook never
# edits rules -- it only reads. This keeps the version in git, visible, owner-controlled.
#
# Contract (verified against official Claude Code hook docs):
#   stdin JSON: source ("startup"|"resume"|"clear"|"compact"), model (id), session_id.
#   stdout JSON: {"systemMessage": <user-visible>, "hookSpecificOutput":
#       {"hookEventName":"SessionStart","additionalContext": <model-visible>}}
#   $CLAUDE_PROJECT_DIR available. No hook fires on mid-session /model switch --
#   that case is handled manually via /recalibrate (documented limitation).
#
# Fail-open: any error exits 0 with no output, never disrupting session start.
set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="$PROJECT_DIR/.claude/state"
RULES_FILE="$PROJECT_DIR/.claude/CLAUDE.md"
LAST_MODEL_FILE="$STATE_DIR/last-model.txt"
CHANGED_FLAG="$STATE_DIR/model-changed.flag"

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0
command -v jq >/dev/null 2>&1 || exit 0
[[ -f "$RULES_FILE" ]] || exit 0

INPUT=$(cat 2>/dev/null) || exit 0
SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // ""' 2>/dev/null) || exit 0
MODEL=$(printf '%s' "$INPUT" | jq -r '.model // ""' 2>/dev/null) || exit 0

# Only react to real new/resumed sessions, not /clear or compaction.
case "$SOURCE" in
  startup|resume) ;;
  *) exit 0 ;;
esac
[[ -n "$MODEL" ]] || exit 0

# Record the live model for diagnostics (not the source of truth -- CLAUDE.md is).
printf '%s' "$MODEL" > "$LAST_MODEL_FILE" 2>/dev/null || true

# Read the EXPECTED model from CLAUDE.md: the first `...` after "Expected model:".
EXPECTED=$(grep -m1 -oE 'Expected model: *`[^`]+`' "$RULES_FILE" 2>/dev/null | grep -oE '`[^`]+`' | tr -d '`')
# No pin found -> fail open (nothing to compare against).
[[ -n "$EXPECTED" ]] || exit 0

# Match -> clear any stale flag, exit quietly.
if [[ "$MODEL" == "$EXPECTED" ]]; then
  rm -f "$CHANGED_FLAG" 2>/dev/null || true
  exit 0
fi

# Mismatch: drop a flag and emit banner + context.
printf 'expected=%s live=%s' "$EXPECTED" "$MODEL" > "$CHANGED_FLAG" 2>/dev/null || true

BANNER="Model mismatch: live=${MODEL}, expected=${EXPECTED} (pinned in .claude/CLAUDE.md). Rule-following can drift between model versions. Claude will offer recalibration in its first reply; run /recalibrate to confirm rules, skills and project conventions hold under the live model. If this switch is intentional, update the 'Expected model:' line in .claude/CLAUDE.md."

CONTEXT="MODEL MISMATCH this session: live=${MODEL}, expected(pinned in .claude/CLAUDE.md)=${EXPECTED}. Per the project's model-change non-negotiable: in your FIRST reply, tell the owner the live model differs from the pinned expectation (one line) and offer to run /recalibrate. Do NOT silently proceed. The marker file .claude/state/model-changed.flag is set; /recalibrate clears it and reminds the owner to update the pin if the switch is intentional."

jq -cn --arg sm "$BANNER" --arg ac "$CONTEXT" \
  '{systemMessage:$sm, hookSpecificOutput:{hookEventName:"SessionStart", additionalContext:$ac}}' \
  2>/dev/null || exit 0

exit 0
