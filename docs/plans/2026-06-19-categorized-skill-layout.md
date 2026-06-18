# Categorized Skill Layout — Implementation Plan

**Goal:** Move the vault's 15 skills into top-level `skills/<category>/<name>/` and expose them to Claude Code through committed flat symlinks in `.claude/skills/`, with no change to routing or hooks.

**Architecture:** Variant B (mattpocock-proven): real skill dirs live under `skills/<category>/`; `.claude/skills/` contains only flat relative symlinks (+ the gitignored `_metrics.jsonl`). Discovery sees only symlinks → no recursion/double-registration. Routing `.files` stay flat and resolve through the symlinks.

**Tech stack:** Bash, `git mv`, relative symlinks, `jq`. No build/test pipeline — "tests" here are shell verification commands (RED = check fails before the change, GREEN = passes after) + the vault validators + a subagent skill-invocation run.

## Global constraints

- macOS/Linux only; symlinks are repo-relative (`../../skills/...`), never absolute. (spec → Out of scope, Risks)
- Use `git mv` (never delete+create) so per-skill history follows the move. (spec → Risks)
- Routing (`skills-routing.json`) and hooks are NOT edited — `.files` stay flat. (spec → Out of scope)
- Do NOT add a routing entry for `improve-codebase-architecture` (pre-existing gap, deferred). (spec → Out of scope)
- The human owns commits; each task ends with a proposed Conventional Commit, not an executed one — unless the user has authorized commits this session. (CLAUDE.md → Git boundary)
- One logical change per commit. (git-conventions)

## Taxonomy (copied verbatim from spec → Contracts)

```text
apply-chain/  grilling writing-specs writing-plans tdd spec-drift-audit
foundation/   bootstrapping-claude-md auditing-claude-md bootstrapping-domain-rules auditing-domain-rules
authoring/    writing-great-skills writing-rules
design/       codebase-design improve-codebase-architecture
process/      lessons-learned-protocol handoff
```

---

## Task 1 — Relocate the 15 skill dirs into `skills/<category>/`

**Files:** `skills/{apply-chain,foundation,authoring,design,process}/<name>/` (NEW, via `git mv` of each `.claude/skills/<name>/`).

**Interfaces:**
- Consumes: the 15 existing `.claude/skills/<name>/` dirs.
- Produces: 15 dirs at `skills/<category>/<name>/`, each containing its original `SKILL.md` (+ `references/`/`*.md`). Discovery is intentionally broken at end of this task (symlinks come in Task 2).

Steps:

- [ ] **RED — confirm no source tree yet.** Run:
  ```bash
  find skills -name SKILL.md 2>/dev/null | wc -l | tr -d ' '
  ```
  Expected: `0` (or `find: skills: No such file or directory` → also proves absence).

- [ ] **Create category dirs.**
  ```bash
  mkdir -p skills/apply-chain skills/foundation skills/authoring skills/design skills/process
  ```

- [ ] **Move each skill with `git mv`** (preserves history):
  ```bash
  git mv .claude/skills/grilling                    skills/apply-chain/grilling
  git mv .claude/skills/writing-specs               skills/apply-chain/writing-specs
  git mv .claude/skills/writing-plans               skills/apply-chain/writing-plans
  git mv .claude/skills/tdd                         skills/apply-chain/tdd
  git mv .claude/skills/spec-drift-audit            skills/apply-chain/spec-drift-audit
  git mv .claude/skills/bootstrapping-claude-md     skills/foundation/bootstrapping-claude-md
  git mv .claude/skills/auditing-claude-md          skills/foundation/auditing-claude-md
  git mv .claude/skills/bootstrapping-domain-rules  skills/foundation/bootstrapping-domain-rules
  git mv .claude/skills/auditing-domain-rules       skills/foundation/auditing-domain-rules
  git mv .claude/skills/writing-great-skills        skills/authoring/writing-great-skills
  git mv .claude/skills/writing-rules               skills/authoring/writing-rules
  git mv .claude/skills/codebase-design             skills/design/codebase-design
  git mv .claude/skills/improve-codebase-architecture skills/design/improve-codebase-architecture
  git mv .claude/skills/lessons-learned-protocol    skills/process/lessons-learned-protocol
  git mv .claude/skills/handoff                     skills/process/handoff
  ```

- [ ] **GREEN — 15 SKILL.md under `skills/`, none left at the flat root.**
  ```bash
  find skills -name SKILL.md | wc -l | tr -d ' '            # expect: 15
  find .claude/skills -maxdepth 1 -type d ! -name skills    # expect: empty (only _metrics.jsonl file + nothing else)
  ```

- [ ] **GREEN — history preserved** (spec verification #6):
  ```bash
  git log --follow --oneline -1 -- skills/apply-chain/grilling/SKILL.md   # expect a pre-move commit line
  ```

- [ ] **Propose commit** (do not run unless authorized):
  ```text
  refactor(skills): relocate skills into skills/<category>/ source tree
  ```

---

## Task 2 — Add `scripts/link-skills.sh` and generate the 15 committed symlinks

**Files:** `scripts/link-skills.sh` (NEW); `.claude/skills/<name>` ×15 (NEW committed symlinks).

**Interfaces:**
- Consumes: `skills/<category>/<name>/SKILL.md` (×15) from Task 1.
- Produces: `scripts/link-skills.sh` (idempotent, no-arg regenerator); 15 symlinks `.claude/skills/<name>` → `../../skills/<category>/<name>`. Restores discovery.

Steps:

- [ ] **RED — discovery currently broken, zero symlinks.**
  ```bash
  find .claude/skills -maxdepth 1 -type l | wc -l | tr -d ' '   # expect: 0
  ```

- [ ] **Write `scripts/link-skills.sh`** (exact content):
  ```bash
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
  ```

- [ ] **Make executable and run it.**
  ```bash
  chmod +x scripts/link-skills.sh && ./scripts/link-skills.sh
  ```
  Expected: 15 `linked <name> -> ../../skills/<category>/<name>` lines.

- [ ] **GREEN — 15 resolving symlinks.**
  ```bash
  [ "$(find .claude/skills -maxdepth 1 -type l | wc -l | tr -d ' ')" = 15 ] && echo OK-15
  for l in .claude/skills/*/; do test -f "${l}SKILL.md" || echo "BROKEN: $l"; done   # expect: no BROKEN lines
  ```

- [ ] **GREEN — idempotency** (re-run is a no-op, no clobber error):
  ```bash
  ./scripts/link-skills.sh >/dev/null && echo OK-idempotent
  ```

- [ ] **GREEN — routing `.files` still resolve through symlinks** (spec verification #3):
  ```bash
  jq -r '.skills[].files[]' .claude/skills-routing.json | while read -r f; do test -f "$f" || echo "MISSING: $f"; done   # expect: no MISSING lines
  jq . .claude/skills-routing.json >/dev/null && echo OK-json
  ```

- [ ] **Propose commit** (do not run unless authorized):
  ```text
  feat(skills): add link-skills.sh and flat discovery symlinks
  ```

---

## Task 3 — Update the 5 docs that assert the flat layout

**Files (all EDIT):** `.claude/rules/common/domains-glossary.md` (L27), `.claude/rules/common/skill-routing-sync.md` (L62 + prose L22), `.claude/rules/common/framework.md` (L10), `CLAUDE.md` (L19), `.claude/CLAUDE.md` (L17 + L32).

**Interfaces:**
- Consumes: the new layout from Tasks 1–2.
- Produces: docs describing source-in-`skills/<category>/` + discovery-via-flat-symlink; the skill-routing-sync checklist enumerates `skills/**/SKILL.md` instead of `ls .claude/skills/`.

Steps:

- [ ] **RED — docs still assert the old flat layout.**
  ```bash
  grep -n 'ls .claude/skills/' .claude/rules/common/skill-routing-sync.md      # expect: L62 hit (old command)
  grep -n 'flat collection of agnostic skills under' CLAUDE.md                  # expect: L19 hit
  ```

- [ ] **Edit `domains-glossary.md` row #1 (L27)** — change the "Lives in" cell. New text:
  ```text
  | 1 | **skill** | source: `skills/<category>/<name>/SKILL.md`; discovered via flat symlink `.claude/skills/<name>` (+ `references/*.md`) | invoked via the `Skill` tool | a routable capability; `name:` MUST equal the directory name (and the symlink name) |
  ```

- [ ] **Edit `skill-routing-sync.md` checklist (L62)** — replace the enumeration command:
  ```text
  - [ ] Every invocable skill directory under `skills/<category>/` (excluding `disable-model-invocation` reference skills) has exactly one matching key in `skills-routing.json` (`find skills -name SKILL.md` vs `jq '.skills | keys' .claude/skills-routing.json`). Known carried-forward gap: `improve-codebase-architecture` has no key yet.
  ```
  And in the prose (~L22), append after the source-of-truth sentence:
  ```text
  Skills live under `skills/<category>/<name>/`; `.claude/skills/<name>` is a flat symlink into that tree, and routing `.files` point at the flat symlink path.
  ```

- [ ] **Edit `framework.md` (L10)** — update the layers path reference:
  ```text
  2. **Scan every layer the change touches** and classify each NONE / PARTIAL / FULL. The layers of a skill change are: `skills/<category>/<name>/SKILL.md` frontmatter → `SKILL.md` body → `references/*.md` → `skills-routing.json` (triggers) → `.claude/hooks/*.sh`. A new/renamed/deleted skill or a trigger change is NOT done until routing matches disk and the flat symlink exists (see [skill-routing-sync.md](./skill-routing-sync.md)).
  ```

- [ ] **Edit `CLAUDE.md` (L19)** — replace the layout sentence:
  ```text
  Skills are authored under `skills/<category>/` (apply-chain / foundation / authoring / design / process) and discovered by Claude Code through flat symlinks in `.claude/skills/`, plus the harness around them: `.claude/hooks/` (gates + logging), `.claude/rules/common/` (framework + domain glossary), `.claude/skills-routing.json`, `.claude/state/`. No application code, no `package.json`, no build.
  ```

- [ ] **Edit `.claude/CLAUDE.md`** — L17 (structural-claims) and L32 (AUTHOR edit location):
  ```text
  L17: 7. **Skill names are structural claims.** A reference to a skill must match its real dir and `name` under `skills/<category>/*` (and its flat symlink in `.claude/skills/*`) — verify, don't recall.
  L32: - **AUTHOR** (default) — create or change a skill via RED → GREEN → REFACTOR → VALIDATE. Edits under `skills/<category>/**` (discovered via the `.claude/skills/` symlinks); subagent pressure runs allowed.
  ```

- [ ] **GREEN — old assertions gone, new skill-routing-sync diff yields the 2-skill delta** (spec verification #4):
  ```bash
  grep -rn 'ls .claude/skills/' .claude/rules/common/skill-routing-sync.md     # expect: empty
  diff <(find skills -name SKILL.md | sed -E 's#skills/[^/]+/([^/]+)/SKILL.md#\1#' | sort) \
       <(jq -r '.skills | keys[]' .claude/skills-routing.json | sort)
  # expect: only '< writing-great-skills' and '< improve-codebase-architecture' (the two unrouted-by-design/gap skills)
  ```

- [ ] **Propose commit** (do not run unless authorized):
  ```text
  docs(rules): describe categorized skill source + symlink discovery
  ```

---

## Task 4 — Final acceptance (validators + GREEN subagent run)

**Files:** none changed — verification only.

**Interfaces:**
- Consumes: the complete state from Tasks 1–3.
- Produces: pasted evidence that all spec acceptance criteria hold.

Steps:

- [ ] **Run the vault validators on every moved `SKILL.md`** (frontmatter ≤1024, `name` regex == dir name, `references/*.md` links resolve, fences balanced, word count). Per root CLAUDE.md → "Common commands" these are applied per skill; paste results. Expect: all clean. Key cross-check — `name:` frontmatter still equals the leaf dir name (move did not change leaf names):
  ```bash
  for f in $(find skills -name SKILL.md); do
    n=$(awk -F': *' '/^name:/{print $2; exit}' "$f" | tr -d '"'"'"' ')
    d=$(basename "$(dirname "$f")")
    [ "$n" = "$d" ] || echo "NAME-MISMATCH: $f (name=$n dir=$d)"
  done   # expect: no NAME-MISMATCH lines
  ```

- [ ] **GREEN subagent run (spec acceptance).** Dispatch a subagent that invokes a moved skill via the `Skill` tool and confirms it loads from the symlinked path:
  ```text
  Subagent (general-purpose): "Invoke Skill('grilling') and report whether the skill body loaded (the grilling interview instructions appear). Do not perform the interview — just confirm the skill resolved and its SKILL.md content was returned."
  Expected: the skill loads; body content returned via the flat symlink.
  ```

- [ ] **Paste the full spec Verification block output** (commands #1–#6 from the spec) as the acceptance evidence in the status block.

- [ ] **No commit** — Task 4 is verification only.

---

## Out of scope (carried from spec — do NOT implement)

- `plugin.json` / marketplace distribution; any mandatory build step.
- Fixing the `improve-codebase-architecture` routing gap.
- Windows/WSL with `core.symlinks=false`.
- Taxonomy leaking into `skills-routing.json` (keys/`.files` stay flat).
