#!/usr/bin/env bash
# Notification-sound hook: opt-in audible cue when Claude needs input or finishes a turn,
# so the user can switch to other work instead of watching the session.
#
# Why opt-in (default silent): every other saleizo-controls hook is always-on telemetry, but a
# sound is a personal preference -- shipping it on by default would make every consumer repo chime.
# So it no-ops unless the consumer sets SALEIZO_NOTIFY (in their own ~/.claude env, never committed
# to the shared plugin). This is the "don't put it in the shared settings" advice, encoded.
#
# Why agnostic player detection: afplay is macOS-only; hard-coding it would be project leakage
# (agnostic-by-default is a repo hard rule). We probe afplay -> paplay -> aplay -> powershell.exe
# and fail open (silent exit 0) when none is present, so a non-mac consumer is never broken.
#
# Wired to three events (hooks.json): PreToolUse[AskUserQuestion] + Notification -> INPUT sound,
# Stop -> DONE sound. The Notification "waiting for your input" idle notice is deduped so it does
# not chime a second time after AskUserQuestion already did.
#
# Contract: advisory, ALWAYS exit 0, sound played in the background (never blocks the tool call).
# Config (env, all optional): SALEIZO_NOTIFY (enable), SALEIZO_NOTIFY_INPUT / SALEIZO_NOTIFY_DONE
# (sound file paths; default to macOS system sounds), SALEIZO_NOTIFY_PLAYER (pin the player,
# skip autodetect -- makes a fixture host-independent), SALEIZO_NOTIFY_DEBUG (dry-run: print the
# chosen player command to stderr instead of playing -- the fixture test seam).
set -uo pipefail

GUARDRAILS_LIB="${BASH_SOURCE[0]%/*}/lib/common.sh"
[ -r "$GUARDRAILS_LIB" ] || exit 0   # missing/unreadable lib -> fail open (`.` is a special builtin under set -e)
. "$GUARDRAILS_LIB"

INPUT=$(cat 2>/dev/null) || INPUT=""

# Opt-in gate: silent unless explicitly enabled.
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
    # Dedupe the idle "waiting for your input" notice -- AskUserQuestion already chimed.
    MSG=$(hook_field "$INPUT" '.message // empty')
    if printf '%s' "$MSG" | grep -qiE 'waiting for your input'; then
      [ -n "$DEBUG" ] && printf 'notify-debug: skip dedupe\n' >&2
      exit 0
    fi
    SOUND="$INPUT_SOUND" ;;
  PreToolUse)
    # Defense-in-depth: only AskUserQuestion, even if the hooks.json matcher is ever broadened.
    [ "$(hook_field "$INPUT" '.tool_name // empty')" = "AskUserQuestion" ] || exit 0
    SOUND="$INPUT_SOUND" ;;
  *)
    exit 0 ;;
esac

# Detect an available sound player; none -> silent fail-open.
# SALEIZO_NOTIFY_PLAYER pins the player explicitly (skips autodetect) so a fixture is deterministic
# on any host -- a Linux CI runner has none of afplay/paplay/aplay, which would otherwise short-circuit.
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

# Dry-run test seam: print the chosen command, do not play.
if [ -n "$DEBUG" ]; then
  printf 'notify-debug: %s\n' "${CMD[*]}" >&2
  exit 0
fi

# No readable sound file -> nothing to play (silent).
[ -f "$SOUND" ] || exit 0

# Play in the background so the hook returns immediately (never blocks the tool call).
"${CMD[@]}" >/dev/null 2>&1 &
exit 0
