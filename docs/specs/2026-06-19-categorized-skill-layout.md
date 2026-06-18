# Spec: Categorized skill layout (top-level `skills/` + flat symlinks)

Status: approved-design → spec for review. Source: `grilling` + readiness-review, this session.

## Goal

Reorganize the vault's 15 skills into category subfolders for human navigation, while Claude Code keeps discovering them flatly. Real skill dirs move to a top-level `skills/<category>/<name>/`; `.claude/skills/` holds only committed flat symlinks pointing back into them. No behavior change for routing, hooks, or skill invocation.

## Scope

- Create top-level `skills/` with 5 category dirs and `git mv` each of the 15 skill dirs from `.claude/skills/<name>/` into `skills/<category>/<name>/`.
- Add 15 committed flat symlinks `.claude/skills/<name>` → `../../skills/<category>/<name>` (one per skill, including the `disable-model-invocation` reference skill `writing-great-skills`).
- Add `scripts/link-skills.sh` — optional helper that regenerates the flat symlinks from the `skills/` tree, with a guard against self-symlinking.
- Update the docs that assert the flat layout (glossary, skill-routing-sync, framework, both CLAUDE.md) to describe source-in-`skills/` + discovery-via-symlink.

## Out of scope

- `plugin.json` / marketplace distribution; any mandatory build step. The vault stays "no build pipeline".
- Taxonomy leaking into `skills-routing.json` — `.files` paths and keys stay flat; categories are organizational only.
- Editing the hooks (`detect-bypass.sh`, `skill-gate.sh`, `log-skill-usage.sh`) — they key on the flat `.files` paths, which still resolve.
- Fixing the pre-existing routing gap for `improve-codebase-architecture` (it has no `skills` entry today). It moves to `design/` and gets a flat symlink, but stays unrouted — a separate task ("one logical change").
- Windows / WSL with `core.symlinks=false`. Repo targets macOS/Linux; `link-skills.sh` is the recovery path if a clone materializes symlinks as text files.

## Contracts

**Taxonomy (15 skills → 5 categories):**

```text
skills/
  apply-chain/  grilling/ writing-specs/ writing-plans/ tdd/ spec-drift-audit/
  foundation/   bootstrapping-claude-md/ auditing-claude-md/ bootstrapping-domain-rules/ auditing-domain-rules/
  authoring/    writing-great-skills/ writing-rules/
  design/       codebase-design/ improve-codebase-architecture/
  process/      lessons-learned-protocol/ handoff/
```

**Symlink shape** — relative, so it survives clone and is location-independent:

```text
.claude/skills/grilling   -> ../../skills/apply-chain/grilling
.claude/skills/tdd        -> ../../skills/apply-chain/tdd
# ... 15 total. Resolving `.claude/skills/<name>/SKILL.md` reaches the real file.
.claude/skills/_metrics.jsonl   # stays — a real gitignored file, NOT a skill, no symlink
```

**Routing entry — UNCHANGED** (`files` stays flat, resolves through the symlink):

```json
"grilling": {
  "triggers": ["brainstorm", "..."],
  "files": [".claude/skills/grilling/SKILL.md"]
}
```

**`scripts/link-skills.sh` contract** — idempotent regeneration, no args:

```bash
#!/usr/bin/env bash
set -euo pipefail
# Recreate flat symlinks in .claude/skills/<name> -> ../../skills/<category>/<name>
# for every skills/**/SKILL.md. Refuse to run if .claude/skills is itself a
# symlink into this repo (self-symlink guard). Leaves _metrics.jsonl untouched.
```

## Files touched

| File(s) | Kind | Why |
| --- | --- | --- |
| `skills/<category>/<name>/` ×15 | NEW (via `git mv` from `.claude/skills/<name>/`) | real skill dirs relocate under category folders; preserves history |
| `.claude/skills/<name>` ×15 | NEW (committed symlink) | flat discovery surface → `../../skills/<category>/<name>` |
| `.claude/skills/_metrics.jsonl` | UNCHANGED | gitignored runtime state stays at flat root; `log-skill-usage.sh` path unchanged |
| `scripts/link-skills.sh` | NEW | optional symlink-regeneration helper with self-symlink guard |
| `.claude/rules/common/domains-glossary.md` | EDIT (row #1, line 27) | ownership: real dir `skills/<category>/<name>/SKILL.md`, discovered via flat symlink `.claude/skills/<name>`; invariant `symlink-name === SKILL.md name === routing key` holds |
| `.claude/rules/common/skill-routing-sync.md` | EDIT (line 62, and prose ~line 22) | checklist source-of-truth enumeration switches from `ls .claude/skills/` to `skills/**/SKILL.md`; still compares against `jq '.skills \| keys'` |
| `.claude/rules/common/framework.md` | EDIT (line 10) | "layers of a skill change" path references → source under `skills/<category>/` |
| `CLAUDE.md` | EDIT (line 19) | "flat collection under `.claude/skills/`" → "categorized under `skills/`, discovered via flat `.claude/skills/` symlinks" |
| `.claude/CLAUDE.md` | EDIT (lines 17, 32) | edit location is now `skills/**`; `.claude/skills/*` is the symlinked discovery surface |

## Edge cases

- **Empty / leftover:** after `git mv`, no real skill dir may remain directly under `.claude/skills/` — only symlinks + `_metrics.jsonl`. Verify: `find .claude/skills -maxdepth 1 -type d` returns nothing but `.claude/skills` itself.
- **Broken symlink:** every `.claude/skills/<name>` must resolve to an existing `SKILL.md`. A dangling symlink = build failure. Verify per-link with `test -f .../SKILL.md`.
- **detect-bypass path-keying:** the hook matches the *read path* against the flat `.files`. Reading a skill via its real source path `skills/<category>/<name>/SKILL.md` will NOT trip bypass detection (only the flat `.claude/skills/<name>/SKILL.md` does). Accepted: the flat path is canonical; document, don't fix.
- **`writing-great-skills`:** gets a flat symlink (so it's discoverable as a reference skill) but NO routing entry (it's `disable-model-invocation` by design). Symlink existence is independent of routing.
- **`improve-codebase-architecture`:** gets a flat symlink, moves to `design/`, remains unrouted (pre-existing gap, carried forward, noted in skill-routing-sync as the one known exception).
- **Count reconciliation:** 15 symlinks vs 13 routing keys is correct (15 − `writing-great-skills` exempt − `improve-codebase-architecture` gap = 13). The skill-routing-sync checklist must pass with this count, not newly fail.
- **`git config core.symlinks`** is unset → defaults to true on macOS/Linux, so committed symlinks recreate on clone. If false, clone yields text files; `scripts/link-skills.sh` is the recovery.

## Verification

Real commands whose output proves the spec (run from repo root):

```bash
# 1. Exactly 15 flat symlinks, no real skill dirs left at the flat root
[ "$(find .claude/skills -maxdepth 1 -type l | wc -l | tr -d ' ')" = 15 ] && echo OK-15-symlinks
find .claude/skills -maxdepth 1 -type d ! -name skills   # expect: empty

# 2. Every flat symlink resolves to a real SKILL.md
for l in .claude/skills/*/; do test -f "${l}SKILL.md" || echo "BROKEN: $l"; done

# 3. Every routing .files path still resolves (through the symlink)
jq -r '.skills[].files[]' .claude/skills-routing.json | while read -r f; do test -f "$f" || echo "MISSING: $f"; done

# 4. skill-routing-sync checklist: source skills vs routing keys
diff <(find skills -name SKILL.md | sed -E 's#skills/[^/]+/([^/]+)/SKILL.md#\1#' | sort) \
     <(jq -r '.skills | keys[]' .claude/skills-routing.json | sort)
#   expected delta: only writing-great-skills (exempt) + improve-codebase-architecture (known gap)

# 5. JSON still valid
jq . .claude/skills-routing.json >/dev/null && echo OK-json

# 6. git mv preserved per-skill history (proves the "preserves history" goal)
git log --follow --oneline -1 -- skills/apply-chain/grilling/SKILL.md   # expect a pre-move commit
```

Plus the vault validators (frontmatter ≤1024, `name` regex, `references/*.md` links resolve, fences balanced, word count) on every moved `SKILL.md`, and a **GREEN subagent run**: in a fresh session, invoke a moved skill (e.g. `Skill(grilling)`) and confirm it loads from the symlinked path.

## Risks

- **Undocumented symlink discovery:** Claude Code docs don't cover symlinked skill dirs. Mitigation: layout B mirrors mattpocock/skills' proven `ln -sfn <real> ~/.claude/skills/<name>` pattern, and `.claude/skills/` contains *only* symlinks (no category dirs) → no recursion/double-registration risk by construction. The GREEN subagent run is the final confirmation.
- **History loss on move:** use `git mv` (not delete+create) so per-skill history follows the relocation.
- **Stale absolute symlinks:** use repo-relative targets (`../../skills/...`), never absolute, so clones and worktrees resolve correctly.
