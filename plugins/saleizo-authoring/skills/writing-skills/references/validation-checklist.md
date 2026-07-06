# Validation Checklist — Layer 1 (static pre-flight)

The cheap, fast checks the `validate` gate runs FIRST, before dispatching the validation subagent.
All of it is defined here, inside the skill — the gate depends on no external hook. The validation
subagent (Layer 2) also applies this list as its structural pass. Fail fast: a Layer-1 failure
stops the gate before the expensive subagent run.

This list is self-contained and agnostic — it names no repo-specific path or command. Run the checks
with whatever the host environment provides (illustrative shell shown; adapt to the runtime).

## Checks

1. **Frontmatter size** — the `---`…`---` block is ≤ 1024 bytes.
2. **`name` regex** — matches `^[a-z0-9-]+$` (lowercase, digits, hyphens only).
3. **`name === dir`** — `name:` equals the skill's directory name. A mismatch is a hard fail (invocation breaks).
4. **Code fences balanced** — every opened fence closes. A fence opens on a run of ≥3 backticks (info string allowed) and closes only on a bare run of ≥ the opening length, so a 4-backtick example wrapper quoting inner ` ``` ` blocks nests correctly instead of counting as unbalanced (a flat line count is wrong — it mis-flags the house-style wrapper).
5. **Reference links resolve** — every `references/*.md`, `assets/*.md`, and `agents/*.md` (and other relative `.md`) link in `SKILL.md` and in each reference file points at a file that exists. Strip a trailing `#anchor` and any `"title"` before resolving the file part, and ignore links that sit inside a fenced code example (they are illustrative, not real references).
6. **Frontmatter keys legal** — every key is in the authoritative set (`frontmatter.md`); an unknown key is a likely typo. When present, `allowed-tools`/`disallowed-tools` is a space/comma string or YAML list; `model` is `inherit`, a known alias, or a `claude-*` id.
7. **Routing invariant** — if `disable-model-invocation: true`, the skill has NO entry in the routing registry (`skills-routing.json`) and declares no triggers; otherwise it MUST have a routing entry whose key equals `name`. **This check applies only to a skill governed by a routing registry** (one that lives in the repo owning that `skills-routing.json`). For a **foreign, fixture, or standalone** skill that belongs to no registry, #7 is **N/A** — supply no registry path so the runner prints `SKIP`, and never judge it against an unrelated repo's registry (a false FAIL).
8. **Word count** — measured on the `SKILL.md` body (excluding frontmatter and fenced code blocks). Key the bound off the skill's **role**, not its invocation mode — the per-turn cost is the one-line `description` in the routing index, not the body (the body loads only when the skill is invoked, model- or user-invoked alike):
   - a **routine skill** (does one job): target ≤ **500 words** — lean skills route and load best;
   - a **methodology / reference skill** (large, read-for-guidance — e.g. `writing-skills`, `improve-codebase-architecture` — whether model- or user-invoked): ≤ **~1500 words**.
   Pass the role via the runner's third arg (`routine`|`methodology`, default `methodology`); the count is fence-aware (fenced code excluded). Past the bound the runner prints **WARN** (a sprawl smell, see `vocabulary.md`) — not a hard fail. Under the bound is always fine.

## Runner

Run all eight checks with the bundled reference runner rather than re-deriving shell each time:

```bash
bash scripts/validate.sh <skill-dir> [skills-routing.json] [role]
# role = routine|methodology (default methodology) — sets the check-8 word bound
# exit 0 = every hard check passed (word-count/routing only WARN/SKIP); exit 1 = a hard FAIL
```

- It executes checks 1–8 in one pass and prints a `PASS`/`FAIL`/`SKIP`/`WARN` line each — so two
  runs on the same skill converge instead of each agent hand-rolling checks 5–7 with its own commands.
- **Check 7 needs the routing registry**: pass its path as the second arg, or the runner prints
  `SKIP (no registry path given)` — a deterministic, single verdict, never a run-to-run guess.
- **Word count (8) WARNs past the role bound, never hard-fails**; only 1, 3, 4, 5, 6 (and 7 when a
  registry is supplied) can set the failing exit code.

The runner is **illustrative — it assumes `bash`/`awk`/`grep`.** If the host runtime lacks them,
reimplement the same eight checks however it allows; the check *definitions* above are authoritative,
the script is one convenient implementation of them.

A green Layer 1 means the skill is structurally sound; it does NOT mean the skill *works* — that is
Layer 2 (`agents/validator.md`).

## Why these checks earn their place (do not cut them on a strong-agent no-op)

A strong, tool-equipped agent catches most of Layer 1 unaided — in practice a no-skill baseline will
flag `name`≠dir or a broken reference link on its own. That is **expected, not a signal to delete the
checklist or the runner.** The value is *export-bound*: these checks bind for the weaker or
non-agentic harnesses that do NOT verify structure by default. A check being a no-op for a capable
agent *here* says nothing about its worth *there* — keep the full set, and let the runner make it
free.
