---
description: 'Names must reveal purpose — no data/temp/obj/manager/doStuff placeholders, booleans read as predicates, functions are verb phrases'
paths:
  - '**/*.{ts,tsx,js,jsx}'
---

# Clear Names — reveal purpose, not type or mechanism

## When

STOP before naming or renaming a variable, function, parameter, or type. If the name needs a comment to explain what it holds or does, the name has failed.

## Why

A generic name (`data`, `result`, `temp`, `flag`, `handleThing`, `utils`) costs nothing to produce and reads as plausible, so it survives review even when it hides the actual intent. The next reader — human or agent — has to re-derive purpose from usage every time instead of reading it off the name, and a wrong guess propagates into new code built on the misunderstanding.

## Implementation

**A name must let a reader state its purpose without opening the implementation.**

- **Variables/types are noun phrases naming WHAT they hold:** `activeUsers`, not `data`; `retryCount`, not `temp`; `OrderDraft`, not `Obj`.
- **Functions are verb phrases naming WHAT they do:** `fetchInvoice`, not `handleThing`; `normalizeEmail`, not `doStuff`.
- **Booleans read as predicates:** prefix `is`/`has`/`should`/`can` — `isActive`, `hasError`, `canSubmit` — never a bare adjective or `flag`.
- **Don't encode the type in the name** (`userArray`, `nameStr`); the type system already says that. Encode the *role* instead.

```text
❌ WRONG
function doStuff(d: any) {
  const temp = d.filter((x: any) => x.flag);
  return temp;
}

✅ CORRECT
function selectActiveUsers(users: User[]): User[] {
  return users.filter((user) => user.isActive);
}
```

## Edge Cases

- **When NOT to apply:** idiomatic loop indices (`i`, `j`), conventional short names (`id`, `err`, `e` for an event or caught error) in a small, obvious scope — these are established convention, not vagueness. Likewise `result` as a single return accumulator and `data` when it *is* the domain word (a `.data` field off a typed response) are acceptable — the rule targets a *chosen* name that hides a knowable role, not every occurrence of the token.
- **Export-floor policy rule.** On a strong agent this largely reproduces no RED (intent-revealing naming is default-good behavior — the canonical no-op of `scoping-rule-value`); its always-on load is earned in weaker / non-agentic consumer harnesses. The predicate-prefix (`is`/`has`) and no-type-suffix parts steer even a capable model; the generic-placeholder ban is the policy half.
- Function *name quality* is shared with `concise-functions`, which owns *splitting* a multi-task function; this rule owns whether a name reveals purpose — cross-link, not restate.
- A one-letter name is fine when its scope is a few lines and the type/context makes the role unambiguous (e.g. `(a, b) => a - b` in a sort comparator).
- Match the existing project or language convention (e.g. `_private`, `T`/`K` for generics) rather than overriding it project-wide.
- A name can be short AND clear — clarity is the bar, not length; don't pad `id` into `theUniqueIdentifierValue`.
- Renaming a name used across a large surface is a refactor, not a drive-by — scope it deliberately.

## Review Checklist

- [ ] No bare `data`/`temp`/`obj`/`thing`/`helper`/`manager` as a *declared* name outside a tiny scope (grep declarations only, to avoid flooding on `.data` member access: `grep -nE '(const|let|var|function|class)[[:space:]]+(data|temp|obj|thing|helper|manager)\b'`). `result`/`info`/`val` are judgment calls, not grep hits — flag only when they name a non-obvious value.
- [ ] No `doStuff`/`handleThing`/`process` used as a whole function name with no qualifying noun.
- [ ] Every `boolean`-typed variable/param reads as a predicate (`is`/`has`/`should`/`can` prefix).
- [ ] Functions are verb phrases; variables and types are noun phrases — no verb-named variable or noun-named function.
- [ ] No type-encoding suffix in a name (`*Array`, `*Str`, `*Obj`) where the type annotation already says it.
