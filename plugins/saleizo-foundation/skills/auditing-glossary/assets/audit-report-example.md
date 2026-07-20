# Domain-Rules Audit Report — Filled Example

A concrete reference for the report shape. Plain text, produced before editing. Every status is backed by a grep/read run this session — not from memory.

```text
# Domain-Rules Audit — glossary.md

## Template conformance
| Requirement (shared template's Strict rules) | Doc has | Status |
| --- | --- | --- |
| Frontmatter (description + paths) | starts directly with `#`, no frontmatter | Defect |
| Section set + order | matches (When/Why/Implementation/Edge Cases/Review Checklist) | OK |
| Ownership-table columns | `# | Concept | Owns (anchor) | Kind | Represents` | OK |
| Owns (anchor): one backtick path, no link/:line/method-list | documents row uses `[src/...](../../../src/...)` links | Defect |
| Location .claude/rules/domains/ | correct | OK |

## Claims checked
| Claim (doc says) | Code shows (grep/read) | Status |
| --- | --- | --- |
| path src/shared/api/documents/ | exists | Confirmed |
| path src/shared/api/organizations/document/ | exists | Confirmed |
| path src/shared/api/knowledge-base/ | exists | Confirmed |
| Routes.UPSERT_CERTIFICATE | exists | Confirmed |
| Routes.UPSERT_COMPANY_DOCUMENT | exists | Confirmed |
| Routes.UPSERT_DOCUMENT (knowledge-base row) | not found; real route is Routes.UPSERT_INSTRUCTION | Stale doc |
| ownership: "company docs never per-user" | code adds a per-user companyDoc.ownerId field | Code drift |
| enum TECH_DOC_TYPE = CERT/CHKL/MANL | matches knowledge-base.schemes.ts | Confirmed |
| i18n key documentation.document-types.* | greps to nothing | Hallucination |

## Summary
- Conformance defect: 2 · Confirmed: 6 · Stale doc: 1 · Code drift: 1 · Hallucination: 1

## Decisions needed
- Code drift — company-doc ownerId: revert the code to honor "company docs are per-organisation, not per-user", OR change the rule to allow per-user ownership? (external-ish: affects the ownership model — pick deliberately) — recommend: revert code.
- (Conformance defects need no decision — they are surgical doc-only reshapes to the template: add frontmatter, delink the paths.)

## Decision
- `Apply recommended` → conformance defects reshaped to the template (add frontmatter, delink the documents-row paths); stale-doc + hallucination fixed surgically; code-drift per the recommendation above (revert code).
- `Adjust per-finding` → walk the findings one by one.
- `Stop` → take no action now.
```

Note how each row names *what the code actually shows*, not just "wrong" — and how Code drift becomes a decision (revert code vs change rule), never a silent doc rewrite that blesses the divergence.
