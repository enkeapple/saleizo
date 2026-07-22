#!/usr/bin/env bash
# Fail open (silent exit 0) when no sound player is present, so a non-mac consumer is never broken.
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib -> fail open (`.` is a special builtin under set -e)
. "$GUARDRAILS_LIB"

INPUT=$(cat 2>/dev/null) || INPUT=""

case "${SALEIZO_NOTIFY:-}" in
  1|true|yes|on) ;;
  *) exit 0 ;;
esac

hook_require_json "$INPUT"   # garbage/empty stdin -> fail open (exit 0)

EVENT=$(hook_field "$INPUT" '.hook_event_name // empty')
INPUT_SOUND="${SALEIZO_NOTIFY_INPUT:-/System/Library/Sounds/Morse.aiff}"
DONE_SOUND="${SALEIZO_NOTIFY_DONE:-/System/Library/Sounds/Pop.aiff}"
DEBUG="${SALEIZO_NOTIFY_DEBUG:-}"

case "$EVENT" in
  Stop)
    SOUND="$DONE_SOUND" ;;
  Notification)
    MSG=$(hook_field "$INPUT" '.message // empty')
    if printf '%s' "$MSG" | grep -qiE 'waiting for your input'; then
      [ -n "$DEBUG" ] && printf 'notify-debug: skip dedupe\n' >&2
      exit 0
    fi
    SOUND="$INPUT_SOUND" ;;
  PreToolUse)
    [ "$(hook_field "$INPUT" '.tool_name // empty')" = "AskUserQuestion" ] || exit 0
    SOUND="$INPUT_SOUND" ;;
  *)
    exit 0 ;;
esac

# Detect an available sound player; none -> silent fail-open.
PLAYER="${SALEIZO_NOTIFY_PLAYER:-}"
if [ -z "$PLAYER" ]; then
  for p in afplay paplay aplay; do
    if command -v "$p" >/dev/null 2>&1; then PLAYER="$p"; break; fi
  done
  if [ -z "$PLAYER" ] && command -v powershell.exe >/dev/null 2>&1; then PLAYER="powershell.exe"; fi
fi
[ -n "$PLAYER" ] || exit 0

case "$PLAYER" in
  powershell.exe) CMD=(powershell.exe -c "(New-Object Media.SoundPlayer '$SOUND').PlaySync()") ;;
  *)              CMD=("$PLAYER" "$SOUND") ;;
esac

if [ -n "$DEBUG" ]; then
  printf 'notify-debug: %s\n' "${CMD[*]}" >&2
  exit 0
fi

[ -f "$SOUND" ] || exit 0

"${CMD[@]}" >/dev/null 2>&1 &
exit 0
