#!/usr/bin/env bash
# Fail-open and non-blocking: every check warns to stderr; the hook always exits 0. In this repo
set -uo pipefail

command -v jq >/dev/null 2>&1 || exit 0
INPUT=$(cat 2>/dev/null) || exit 0
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || exit 0
[ -n "$FILE" ] || exit 0
[ -f "$FILE" ] || exit 0
base=$(basename "$FILE")

case "$FILE" in
  *.md)
    if [ "$base" = "SKILL.md" ] || printf '%s' "$FILE" | grep -q '/\.claude/rules/'; then

      if head -1 "$FILE" | grep -q '^---[[:space:]]*$'; then
        fm=$(awk 'NR==1&&/^---[[:space:]]*$/{f=1;next} f&&/^---[[:space:]]*$/{exit} f{print}' "$FILE")
        bytes=$(printf '%s' "$fm" | wc -c | tr -d ' ')
        [ "${bytes:-0}" -le 1024 ] || echo "QUALITY warn: $FILE frontmatter is ${bytes} bytes (>1024)." >&2
      fi

      fences=$(grep -c '^```' "$FILE" 2>/dev/null); fences=${fences:-0}
      if [ $(( fences % 2 )) -ne 0 ]; then
        echo "QUALITY warn: $FILE has an odd number of code fences (${fences}) -- unbalanced." >&2
      fi

      if [ "$base" = "SKILL.md" ]; then
        nm=$(grep -m1 '^name:' "$FILE" | sed 's/^name:[[:space:]]*//' | tr -d '"' | tr -d "'")
        dir=$(basename "$(dirname "$FILE")")
        if [ -n "$nm" ]; then
          printf '%s' "$nm" | grep -qE '^[a-z0-9-]+$' || echo "QUALITY warn: $FILE name '$nm' fails ^[a-z0-9-]+$." >&2
          [ "$nm" = "$dir" ] || echo "QUALITY warn: $FILE name '$nm' != dir '$dir'." >&2
        fi
      fi

      dirpath=$(dirname "$FILE")
      grep -nE '\]\([^)]+\.md[^)]*\)' "$FILE" 2>/dev/null | while IFS= read -r line; do
        cleaned=$(printf '%s' "$line" | sed 's/`[^`]*`//g')
        printf '%s' "$cleaned" | grep -qE '\]\([^)]+\.md[^)]*\)' || continue
        target=$(printf '%s' "$cleaned" | sed -E 's/.*\]\(([^)#]+\.md)[^)]*\).*/\1/')
        case "$target" in
          http*|/*) continue ;;
        esac
        [ -e "$dirpath/$target" ] || echo "QUALITY warn: $FILE references missing path '$target'." >&2
      done
    fi
    ;;

  *.ts|*.tsx|*.js|*.jsx)
    command -v npx >/dev/null 2>&1 || exit 0
    npx eslint --fix "$FILE" 2>/dev/null || true
    case "$base" in
      *.test.*|*.spec.*) npx jest "$FILE" --passWithNoTests 2>/dev/null || true ;;
      *)                 npx jest --findRelatedTests "$FILE" --passWithNoTests 2>/dev/null || true ;;
    esac
    ;;
esac

exit 0
