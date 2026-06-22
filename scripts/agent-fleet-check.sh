#!/usr/bin/env bash
# Agent-fleet model check — static, read-only adherence check for model-selection.md.
#
# The model each subagent uses is a STATIC fact in its .claude/agents/<name>.md frontmatter
# (`model:`), applied by the harness — it is NOT visible at runtime in the dispatch payload
# (see lessons-learned: hook-payload-assumption), so adherence belongs here, not in token-guard.
#
# Two flags:
#   MONOCULTURE         — every agent pins the same model: a reviewer then cannot differ from the
#                         implementer (the 3.3 gap). Deterministic.
#   REVIEWER-SHARES-IMPL — a review/guardian/audit-type agent uses a model an implement/engineer-
#                         type agent also uses. HEURISTIC (role inferred from name/description) —
#                         it prints which agents matched so a human can confirm.
#
# Usage: bash scripts/agent-fleet-check.sh [AGENTS_DIR]   (default $CLAUDE_PROJECT_DIR/.claude/agents)
# Exit: 1 if any flag fires (CI-usable), 0 if clean or no agents found.
set -uo pipefail

DIR="${1:-${CLAUDE_PROJECT_DIR:-.}/.claude/agents}"

if [ ! -d "$DIR" ]; then
  echo "agent-fleet-check: no agents dir at $DIR — nothing to check."
  exit 0
fi

shopt -s nullglob
files=("$DIR"/*.md)
if (( ${#files[@]} == 0 )); then
  echo "agent-fleet-check: no agent files in $DIR — nothing to check."
  exit 0
fi

# Extract name + model + role-class for each agent.
declare -a NAMES MODELS ROLES
field() { # file, key -> first frontmatter value, quotes/comment stripped
  grep -m1 -iE "^$2:" "$1" 2>/dev/null | sed -E "s/^$2:[[:space:]]*//I; s/[\"']//g; s/[[:space:]]*#.*//; s/[[:space:]]*$//"
}
classify_role() { # name+description (lowercased) -> implementer|reviewer|other
  # Implementer checked FIRST: a description that mentions "review"/"verify" in passing must not
  # mislabel the engineer/implementer. A dedicated reviewer agent rarely carries engineer/principal.
  case "$1" in
    *implement*|*engineer*|*principal*|*develop*|*build*) echo implementer ;;
    *guardian*|*review*|*audit*|*critic*|*verif*) echo reviewer ;;
    *) echo other ;;
  esac
}

echo "# Agent fleet model check"
echo
echo "## Agents (${#files[@]})"
distinct_models=""
impl_models=""
rev_models=""
rev_overlap=()
for f in "${files[@]}"; do
  name=$(field "$f" name); [ -n "$name" ] || name=$(basename "$f" .md)
  model=$(field "$f" model); [ -n "$model" ] || model="(inherit)"
  # Classify by NAME only — descriptions are prose that mention both "implement" and "review"
  # in passing, so the directory/agent name (architecture-guardian, principal-engineer, …) is the
  # stable role signal. Still a heuristic, but far less noisy than scanning the description.
  role=$(classify_role "$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')")
  printf -- "- %s → %s  [%s]\n" "$name" "$model" "$role"
  case " $distinct_models " in *" $model "*) :;; *) distinct_models="$distinct_models $model";; esac
  [ "$role" = implementer ] && impl_models="$impl_models $model"
  [ "$role" = reviewer ]   && rev_models="$rev_models $model"
done

fail=0
echo
echo "## Flags"

# MONOCULTURE: one distinct real model across >1 agent.
real_models=$(printf '%s' "$distinct_models" | tr ' ' '\n' | grep -v '^$' | grep -v '^(inherit)$' | sort -u)
n_real=$(printf '%s\n' "$real_models" | grep -c . )
if (( ${#files[@]} > 1 )) && (( n_real == 1 )); then
  echo "- MONOCULTURE: all agents pin the same model ($(printf '%s' "$real_models" | tr '\n' ' ')). A reviewer cannot be a different model than the implementer — the 3.3 gap."
  fail=1
fi

# REVIEWER-SHARES-IMPLEMENTER (heuristic).
for rm in $rev_models; do
  case " $impl_models " in
    *" $rm "*)
      echo "- REVIEWER-SHARES-IMPLEMENTER (heuristic): a reviewer-type agent uses '$rm', also used by an implementer-type agent. A same-model reviewer shares the implementer's blind spots."
      fail=1
      break ;;
  esac
done

(( fail == 0 )) && echo "- none — fleet uses ≥2 distinct models and no reviewer shares an implementer's model."
exit "$fail"
