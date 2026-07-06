#!/usr/bin/env bash
# Layer-1 static pre-flight for a skill — the runnable reference implementation of every
# check in references/validation-checklist.md. ILLUSTRATIVE: it assumes bash/awk/grep; if
# your runtime lacks them, reimplement the same eight checks however the host allows.
#
# Usage: validate.sh <skill-dir> [skills-routing.json] [role]
#   <skill-dir>          the skill folder holding SKILL.md
#   [skills-routing.json] optional routing registry; without it, check 7 prints SKIP
#   [role]               routine|methodology (default methodology) — sets the check-8 word bound
# Exit 0 = every HARD check passed (word-count and routing may WARN/SKIP); 1 = a hard FAIL.
set -u
DIR="${1:?usage: validate.sh <skill-dir> [skills-routing.json] [role]}"
DIR="${DIR%/}"
# resolve to an absolute path so `basename` reads the real dir name (not "." for a cwd arg)
DIR=$(cd "$DIR" 2>/dev/null && pwd) || { echo "no such dir: $1"; exit 1; }
SKILL="$DIR/SKILL.md"
ROUTING="${2:-}"
ROLE="${3:-methodology}"
fail=0
say() { printf '%-22s %s\n' "$1" "$2"; }

[ -f "$SKILL" ] || { echo "no SKILL.md in $DIR"; exit 1; }

# Fence-aware line classifier, shared by checks 4/5/8. A fence opens on a run of >=3
# backticks (info string allowed) and closes only on a bare run of >= the opening length —
# so the house-style 4-backtick example wrapper (````…````) that quotes inner ``` blocks
# nests correctly instead of being miscounted line-by-line. Emits, per input line:
#   OPEN <n> | CLOSE | INSIDE | TEXT <line>
# where TEXT lines are the prose outside any fence (fence lines themselves are OPEN/CLOSE).
fence_scan='
function classify(l,   run,n,rest,info){
  if (match(l, /^ {0,3}`{3,}/)) {
    run=substr(l,1,RLENGTH); sub(/^ +/,"",run); n=length(run)
    rest=substr(l,RLENGTH+1); sub(/[ \t]+$/,"",rest); info=(rest!="")
    if (openn==0){ openn=n; return "OPEN" }
    if (!info && n>=openn){ openn=0; return "CLOSE" }
    return "INSIDE"
  }
  return (openn>0) ? "INSIDE" : "TEXT"
}
'

# 1. frontmatter size <= 1024 bytes
fb=$(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f{print}' "$SKILL" | wc -c | tr -d ' ')
if [ "$fb" -le 1024 ]; then say "1 frontmatter-size" "PASS (${fb}B)"; else say "1 frontmatter-size" "FAIL (${fb}B > 1024)"; fail=1; fi

# 2. name regex + 3. name == dir
nm=$(grep -m1 '^name:' "$SKILL" | sed 's/name:[[:space:]]*//' | tr -d "\"' ")
if printf '%s' "$nm" | grep -qE '^[a-z0-9-]+$'; then say "2 name-regex" "PASS ($nm)"; else say "2 name-regex" "FAIL ($nm)"; fail=1; fi
base=$(basename "$DIR")
if [ "$nm" = "$base" ]; then say "3 name==dir" "PASS"; else say "3 name==dir" "FAIL (name=$nm dir=$base)"; fail=1; fi

# 4. code fences balanced across SKILL.md and every bundled .md (fence-aware: a 4-backtick
#    wrapper quoting inner ``` blocks nests and does not count as unbalanced)
odd=""
for f in "$SKILL" "$DIR"/references/*.md "$DIR"/assets/*.md "$DIR"/agents/*.md; do
  [ -f "$f" ] || continue
  awk "$fence_scan"'{ classify($0) } END{ exit (openn==0)?0:1 }' "$f" || odd="$odd $(basename "$f")"
done
if [ -z "$odd" ]; then say "4 fences-balanced" "PASS"; else say "4 fences-balanced" "FAIL (odd:$odd)"; fail=1; fi

# 5. relative .md links resolve — only links OUTSIDE fenced examples; anchors (#sec) and
#    titles ("t") stripped before resolving the file part (from SKILL.md and each bundled .md)
missing=""
for f in "$SKILL" "$DIR"/references/*.md "$DIR"/assets/*.md "$DIR"/agents/*.md; do
  [ -f "$f" ] || continue
  for tgt in $(awk "$fence_scan"'{ if (classify($0)=="TEXT"){ s=$0; while (match(s,/\]\([^)]*\)/)){ print substr(s,RSTART+2,RLENGTH-3); s=substr(s,RSTART+RLENGTH) } } }' "$f"); do
    lnk="${tgt%%#*}"          # drop #anchor
    lnk="${lnk%% *}"          # drop optional "title" (everything after a space)
    lnk="${lnk#<}"; lnk="${lnk%>}"
    case "$lnk" in http*|"") continue ;; esac
    case "$lnk" in *.md) ;; *) continue ;; esac
    [ -f "$(dirname "$f")/$lnk" ] || missing="$missing $lnk"
  done
done
if [ -z "$missing" ]; then say "5 links-resolve" "PASS"; else say "5 links-resolve" "FAIL (missing:$missing)"; fail=1; fi

# 6. frontmatter keys legal — derived from the authoritative set in references/frontmatter.md
#    (single source of truth) when reachable next to this script; embedded mirror as fallback.
FMREF="$(cd "$(dirname "$0")/../references" 2>/dev/null && pwd 2>/dev/null)/frontmatter.md"
legal=""
if [ -f "$FMREF" ]; then
  legal=" $(grep -oE '^\| `[a-z0-9_-]+`' "$FMREF" | sed 's/^| `//; s/`$//' | tr '\n' ' ')"
fi
# fallback mirror (used only if frontmatter.md is unreachable or unparseable)
case "$legal" in *" name "*) ;; *) legal=" name description when_to_use argument-hint arguments disable-model-invocation user-invocable allowed-tools disallowed-tools model effort context agent hooks paths shell " ;; esac
bad=""
for k in $(awk 'NR==1&&/^---/{f=1;next} f&&/^---/{exit} f{print}' "$SKILL" | grep -oE '^[a-zA-Z_-]+:' | sed 's/:$//'); do
  case "$legal" in *" $k "*) ;; *) bad="$bad $k" ;; esac
done
if [ -z "$bad" ]; then say "6 keys-legal" "PASS"; else say "6 keys-legal" "FAIL (unknown:$bad)"; fail=1; fi

# 7. routing invariant — needs the registry; deterministic SKIP when not provided.
#    Prefer structural jq lookup on .skills keys; fall back to a line grep if jq is absent.
dmi=$(grep -Em1 '^disable-model-invocation:[[:space:]]*true' "$SKILL" || true)
if [ -z "$ROUTING" ] || [ ! -f "$ROUTING" ]; then
  say "7 routing-invariant" "SKIP (no registry path given)"
else
  if command -v jq >/dev/null 2>&1; then
    [ "$(jq --arg n "$nm" '.skills | has($n)' "$ROUTING" 2>/dev/null)" = "true" ] && has=1 || has=0
  else
    has=$(grep -c "\"$nm\"[[:space:]]*:" "$ROUTING"); [ "$has" -ge 1 ] && has=1 || has=0
  fi
  if [ -n "$dmi" ]; then
    if [ "$has" -eq 0 ]; then say "7 routing-invariant" "PASS (dmi: no entry)"; else say "7 routing-invariant" "FAIL (dmi but routed)"; fail=1; fi
  else
    if [ "$has" -eq 1 ]; then say "7 routing-invariant" "PASS (routed)"; else say "7 routing-invariant" "FAIL (no entry)"; fail=1; fi
  fi
fi

# 8. body word count (fence-aware, frontmatter excluded) — WARN past the role bound, never a hard fail
w=$(awk "$fence_scan"'NR==1&&/^---/{fm=1;next} fm&&/^---/{fm=0;next} fm{next} { if (classify($0)=="TEXT") print }' "$SKILL" | wc -w | tr -d ' ')
case "$ROLE" in routine) bound=500 ;; *) bound=1500 ;; esac
if [ "$w" -le "$bound" ]; then say "8 word-count" "PASS (${w} words, ${ROLE} <=${bound})"; else say "8 word-count" "WARN (${w} words > ${bound} ${ROLE} bound — sprawl smell, not a fail)"; fi

echo "----"
if [ "$fail" -eq 0 ]; then echo "LAYER-1: GREEN (hard checks pass)"; else echo "LAYER-1: RED (hard fail above)"; fi
exit "$fail"
