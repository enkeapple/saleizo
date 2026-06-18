#!/usr/bin/env bash
set -euo pipefail

# Regenerate flat discovery symlinks .claude/skills/<name> -> ../../skills/<category>/<name>
# for every skills/**/SKILL.md. Idempotent. Leaves _metrics.jsonl and non-skill entries alone.

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$REPO/skills"
DEST="$REPO/.claude/skills"

# Self-symlink guard: .claude/skills must be a real dir, not a symlink into this repo.
if [ -L "$DEST" ]; then
  echo "error: $DEST is a symlink; expected a real directory. Remove it and re-run." >&2
  exit 1
fi

mkdir -p "$DEST"

find "$SRC" -name SKILL.md -print0 |
while IFS= read -r -d '' skill_md; do
  src_dir="$(dirname "$skill_md")"          # $SRC/<category>/<name>
  name="$(basename "$src_dir")"
  rel="../../skills/${src_dir#"$SRC"/}"      # ../../skills/<category>/<name>
  target="$DEST/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "error: $target exists and is not a symlink; refusing to clobber." >&2
    exit 1
  fi
  ln -sfn "$rel" "$target"
  echo "linked $name -> $rel"
done
