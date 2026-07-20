# Domain Glossary Template

A glossary resolves what a **word** means in this app and who owns the concept. It is the source of truth for domain vocabulary. Fill every part from the real codebase — entities, paths, routes, and types are discovered, never invented.

**This is a strict contract, not a loose shape.** The generated file MUST reproduce the frontmatter, the section set and order, and the ownership-table columns below, verbatim. `auditing-glossary` validates a live glossary against this same file — a deviation (missing frontmatter, a renamed/added/dropped section, a changed column set, a path written as a link or with a `:line` anchor) is drift it will flag and fix. The point of the strict shape: two glossaries generated a year apart look identical in structure, so the reader never re-learns the layout.

## Template

````markdown
---
description: '<the collision in one line + the domain→owner summary the reader needs before touching these terms>'
paths: ['**/*.md']
---

# <Area> Glossary — <the collision in one line, e.g. "Cart vs Order vs Checkout">

## When

Before touching any screen / route / API / model / store whose name contains
<term>, <term-in-other-languages>, …; anytime the user says "<term>" / "<native term>";
anytime you read or edit <owning-path-A>, <owning-path-B>, <owning-path-C>, … (the FULL list).
<!-- This section is the exhaustive path index AND the trigger that makes the agent stop and read.
     List EVERY ambiguous term in EVERY language the team uses, and EVERY owning path — be exhaustive.
     The ownership table below carries only ONE anchor path per concept; the complete file list lives HERE. -->

## Why

<The concrete confusion this prevents — ideally the real incident: "an edit button
pointed at domain B's screen", "per-trip state landed in the wrong slice". State the
source-of-truth principle: if a change contradicts this file, fix THIS file first,
then the code — never the other way around.>

## Implementation

Ownership table — memorise it, do not infer from filenames:

| # | Concept | Owns (anchor) | Kind | Represents |
| --- | --- | --- | --- | --- |
| 1 | <domain> | `<one owning dir/file>` | <slice / api / service / screen> | <one line> |
| 2 | … | … | … | … |

Term-disambiguation rules — what each word maps to, and how to resolve the ambiguous ones:

- **"<generic term>"** — defaults to domain #N unless <context signal>, then #M. Never #K.
- **"<other-language term>"** — always domain #N.
- **"<genuinely ambiguous term>"** — resolve by context: under <X> → #1; under <Y> → #2.

What is NOT in any of these domains (must not be conflated): <neighbours that share a folder/word but are separate>.

## Edge Cases

- <stale route / removed symbol that still appears in old branches — map it to the right domain, never reintroduce>.
- <a field/enum that means different things per domain — check which scheme defines it>.

## Review Checklist

- Named the domain explicitly before touching any <term>-related symbol.
- All touched routes/types/i18n keys live inside ONE domain, not crossing.
- No reference to a removed/stale symbol.
````

## Strict rules (what `auditing-glossary` enforces against this file)

1. **Frontmatter is required** — a leading `--- … ---` block with a non-empty `description` and `paths: ['**/*.md']`. A glossary that starts directly with `#` is non-conformant.
2. **Section set and order are fixed** — exactly `# <title>` → `## When` → `## Why` → `## Implementation` → `## Edge Cases` → `## Review Checklist`. No `=== SECTION ===` headings, no renamed/added/dropped section.
3. **Ownership-table columns are fixed** — exactly `| # | Concept | Owns (anchor) | Kind | Represents |`, in that order. Not "Owning module(s)", not a separate "Route(s) / screen(s)" or "Type / enum / slice name" column — those drift run-to-run; this set does not.
4. **`Owns (anchor)` holds ONE path** — the single owning directory or file, as a bare backtick code span. Not a list of every co-located file, not a method list, not a `:line` anchor, and **never** a `[text](../../../path)` markdown link. The exhaustive path list lives in `## When`; a co-owned path or method belongs in prose or `## Edge Cases`, not stuffed into the cell.
5. **Location** — the file lives in the always-on domains layer: `.claude/rules/domains/glossary.md`, or `.claude/rules/local/domains/glossary.md` when the repo hides its rules behind a `local/` layer (e.g. gitignored/private rules). Both are conformant. What fails: the repo `rules/` root (no `.claude/`), or anywhere outside a `domains/` directory.
6. **Fixed sub-blocks, verbatim — nothing else.** So every glossary reads identically regardless of repo:
   - `## Why` ends with the verbatim sentence: `**Source-of-truth principle:** if a change contradicts this file, fix THIS file first, then the code — never the other way around.`
   - `## Implementation` holds, in this order: the ownership table, then exactly two labeled blocks, each lead-in **verbatim** — `Term-disambiguation rules — what each word maps to, and how to resolve the ambiguous ones:` then `What is NOT in any of these domains (must not be conflated):`. No third block. A "Co-owned modules…" block, a "Cross-cutting state" second table, or any other invented sub-heading is a defect — a concept's co-owned/secondary modules go in its `Represents` cell or in `## Edge Cases`, never a new block.
7. **Prose & markup are uniform — bold is rationed.** So no two glossaries "read" differently:
   - `## When` is ONE flowing paragraph, never a bullet list: `Before touching any screen / route / API / … whose name contains <terms, comma-separated>; anytime the user says <"quoted terms">; anytime you read or edit <backtick paths, comma-separated>.` Trigger terms here are **not** bolded; native-language variants sit inline as `term (fr)`.
   - **Bold (`**…**`) appears in exactly two places, nowhere else:** the term key opening each disambiguation bullet (`- **"term"** — …`) and the `**Source-of-truth principle:**` lead-in. Not in `## When`, `## Edge Cases`, or `## Review Checklist`.
   - Every module / type / path / symbol name, everywhere, is a bare backtick code span (never bold, never a link).

```text
✅ Owns (anchor):  `src/store/cartSlice.ts`
❌ Owns (anchor):  `src/api/cart/CartApi.ts` (addItem, removeItem); `src/store/cartSlice.ts` (items)   # method list + multi-path
❌ Owns (anchor):  [src/store/cartSlice.ts](../../../src/store/cartSlice.ts)                           # relative-path link
❌ Owns (anchor):  `src/pages/SellScreen.tsx:55`                                                       # :line anchor
```

## Notes

- The `## When` section is the load-bearing part: if it doesn't name the trigger words and owning paths, the glossary never loads at the moment of confusion — and it is the one place the full path list belongs.
- Every cell in the ownership table is a structural claim — it must match the code you read this session. A glossary cell that greps to nothing is a hallucination; `auditing-glossary` exists to catch exactly that, alongside the conformance rules above.
- Discovered specifics (`<term>`, `<owning-path>`, `<domain>`) are the consumer repo's — this template is stack-agnostic; fill the slots, never bake one repo's nouns into the shape.
