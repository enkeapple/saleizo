# <short, business-oriented story title>

*(one story per file: `NN-<story-slug>.md` inside a feature folder, or a single `stories/…md` when the requirement has only one story)*

As a <role>, I want <capability>, so that <business value>.

## In Scope

- <flow or behaviour included in this story>
- <flow or behaviour included in this story>

## Out of Scope

- <related flow deliberately excluded>
- <related flow deliberately excluded>

## Entry Points

*(include only when UI behaviour is added or changed; omit this whole heading for backend/integration-only stories)*

- <App> → <Page> → <sub-page or action>
- <App> → <Page>

## Functional Overview

<1–3 sentences, behaviour only. E.g. "This enables voucher-based bookings from an external channel. The system processes each incoming booking, creates a booking linked to the correct line and category, and issues a confirmation. On a cancellation it processes the cancellation or rebooking.">

## Acceptance Criteria

### Success Scenarios

1. **<high-level success condition>:**
   1. <detailed, testable rule>
   2. <detailed, testable rule>
2. **<high-level success condition>:**
   1. <rule>

### Failure Scenarios

3. **<high-level failure condition>:**
   1. <rule>
4. **<high-level failure condition>:**
   1. <rule>

### Edge Cases

5. **<high-level edge case>:**
   1. <rule>
6. **<high-level edge case>:**
   1. <rule>

## Supporting Details

*(story-specific only; shared tables live in the feature's `requirements.md`)*

### Affected Apps and Services

| Business App / Service | Affected Flow |
| --- | --- |
| <app or service> | <what changes in it> |

### Texts

*(new page / pop-up / button / input / error names introduced by this story)*

| Element | Text |
| --- | --- |
| <element> | <exact copy> |

### <Status / state / transition table, if the ACs depend on one>

| State | Meaning / transition |
| --- | --- |
| <state> | <description> |

### Open Questions

| # | Question |
| --- | --- |
| 1 | <specific decision needing confirmation> |
