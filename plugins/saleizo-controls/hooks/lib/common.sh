# The readability guard is REQUIRED: `.` is a POSIX special builtin, so under `set -e` its
# open-failure exits the shell BEFORE a trailing `|| exit 0` can run — `. lib || exit 0` would
# fail CLOSED (exit 1). Guarding `[ -r ]` first is the only fail-open form under errexit.

hook_sid() {
  local sid
  sid=$(printf '%s' "${1:-}" | jq -r '.session_id // empty' 2>/dev/null | tr -cd 'A-Za-z0-9._-') || sid=""
  [ -z "$sid" ] && sid=default
  printf '%s' "$sid"
}

hook_state_dir() {
  printf '%s' "${CLAUDE_PROJECT_DIR:-.}/.claude/state/${1:-default}"
}

# hook_require_json <raw-stdin-json> -> EXITS the calling hook 0 (fail-open) if not valid JSON.
hook_require_json() {
  printf '%s' "${1:-}" | jq -e . >/dev/null 2>&1 || exit 0
}

hook_field() {
  printf '%s' "${1:-}" | jq -r "${2:-empty}" 2>/dev/null || printf ''
}

# Self-contained: does NOT rely on the caller's `set -e`. Callers wanting fail-open write `|| exit 0`.
hook_json_update() {
  local file="$1"; shift
  local filter="${*: -1}"
  set -- "${@:1:$(($#-1))}"
  jq "$@" "$filter" "$file" > "$file.tmp" 2>/dev/null && mv "$file.tmp" "$file"
}
