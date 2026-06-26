#!/bin/bash
set -e

# Bump the version of a single marketplace plugin.
#   bump-version.sh [major|minor|patch] [plugin-name]
# No plugin-name → interactive picker; only the chosen plugin is bumped.
# Version scheme matches the customer-mobile convention: minor/patch roll
# over at 9 (e.g. patch 0.3.9 → 0.4.0).

TYPE=${1:-patch}
[[ "$TYPE" =~ ^(major|minor|patch)$ ]] || { echo "Usage: $0 [major|minor|patch] [plugin-name]"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGINS_DIR="$ROOT/plugins"
TARGET="$2"

bump() {
  local file="$1" name="$2"
  local current
  current=$(grep -o '"version": "[^"]*"' "$file" | cut -d'"' -f4)
  [[ -n "$current" ]] || { echo "  $name: no version field, skipped"; return; }

  local M m p
  IFS='.' read -r M m p <<< "$current"

  case $TYPE in
    major) ((M++)); m=0; p=0 ;;
    minor)
      ((m++))
      if ((m > 9)); then m=0; ((M++)); fi
      p=0
      ;;
    patch)
      ((p++))
      if ((p > 9)); then
        p=0; ((m++))
        if ((m > 9)); then m=0; ((M++)); fi
      fi
      ;;
  esac

  local new="$M.$m.$p"
  sed -i '' "s/\"version\": \"$current\"/\"version\": \"$new\"/" "$file"
  echo "  $name: $current → $new"
}

# Collect available plugins (those with a plugin.json).
names=()
for dir in "$PLUGINS_DIR"/*/; do
  [[ -f "$dir.claude-plugin/plugin.json" ]] && names+=("$(basename "$dir")")
done
[[ ${#names[@]} -gt 0 ]] || { echo "No plugins found under $PLUGINS_DIR"; exit 1; }

# Pick the target: from arg, or interactively.
if [[ -z "$TARGET" ]]; then
  echo "Select a plugin to bump ($TYPE):"
  select TARGET in "${names[@]}"; do
    [[ -n "$TARGET" ]] && break
    echo "Invalid choice, try again."
  done
fi

# Validate the target exists.
match=""
for name in "${names[@]}"; do
  [[ "$name" == "$TARGET" ]] && match="$name"
done
[[ -n "$match" ]] || { echo "Unknown plugin: $TARGET"; echo "Available: ${names[*]}"; exit 1; }

echo "Bumping ($TYPE):"
bump "$PLUGINS_DIR/$match/.claude-plugin/plugin.json" "$match"
