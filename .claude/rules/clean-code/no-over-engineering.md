---
description: 'Build the minimum that solves the stated need — no interface/class/strategy for a single implementation, no config/flag/registry system for a value that does not vary today, no extension point or passthrough for a hypothetical future caller nobody asked for. AI generates defensively and builds for scenarios that do not exist yet; this is the YAGNI counter. Targets speculative *design* (a judgment call); unused imports/dead variables belong to the linter, abandoned files to no-debugging-residue. Area-specific to TS/JS code files.'
paths:
  - '**/*.{ts,tsx,js,jsx}'
---

# No Over-Engineering — Build for the Need, Not the Hypothetical

## When

STOP the moment you are about to add structure the stated task did not ask for: a class / interface / strategy where a single function does, a config loader or feature-flag system for a value that is currently constant, a "handle any case" abstraction sitting behind one concrete caller, or a parameter / hook / `...rest` passthrough added "for when we later need it". That extra generality is the default AI reflex — and the moment this rule applies.

## Why

Every speculative abstraction is code to read, test, type, and maintain for a requirement that may never arrive — and when the requirement does arrive, it rarely matches the guess, so the abstraction is reworked anyway. The cost is paid now and forever; the benefit is hypothetical. AI generates defensively (it has seen a million "extensible" examples), so it reaches for the framework when the task asked for one line. Simplicity is the feature: the smallest thing that solves the *stated* problem is the most correct, most reviewable, and easiest to change when the real second requirement shows up.

## Implementation

**Solve the concrete, stated problem with the least structure that works. Add generality only when a second real, present caller forces it — not before.**

- **One implementation → no abstraction.** A single concrete case does not need an interface, base class, or strategy. Inline it; extract the seam when the *second* caller actually exists.
- **A value that does not vary today → a constant or parameter, not a system.** Read the one value where it is used (an env var, a literal, a function argument). Don't build a layered config object / registry / feature-flag framework for one knob.
- **No extension points for hypotheticals.** No pluggable hook, generic event bus, options bag, or `...rest`/`**kwargs` passthrough unless a current requirement uses it.
- **Pick the smallest sufficient unit:** a function over a class, a parameter over a subclass, a literal over a config entry — until a present need demands more.

```text
❌ WRONG — asked to make ONE timeout configurable; built a config module + interface + class + DI (illustrative)
  // config.ts
  export interface AppConfig { userProfileTimeoutMs: number }
  export function loadConfig(): AppConfig { /* parse env, validate, default */ }
  // userProfileClient.ts
  export class UserProfileClient {
    constructor(private readonly config: AppConfig) {}   // DI + class for one knob
    async fetchProfile(id: string) { /* uses this.config.userProfileTimeoutMs */ }
  }
  // "future timeouts add a field here" — designing for a caller that does not exist

✅ CORRECT — read the one value where it is used (illustrative)
  const TIMEOUT_MS = Number(process.env.USER_PROFILE_TIMEOUT_MS) || 30_000;
  const res = await fetch(url, { signal: AbortSignal.timeout(TIMEOUT_MS) });
  // Promote to a config object only when a SECOND configurable value actually arrives.
```

## Edge Cases

- **A present, named second caller (or a committed near-term requirement) justifies the abstraction** — YAGNI forbids *speculative* generality, not warranted design. State the present need in one line when you keep the structure.
- **Genuinely required configurability is not over-engineering** — when a value really does vary per environment/tenant *today*, a config object is correct. The rule targets config for values that do not vary yet.
- **Library / framework code with real external consumers** legitimately exposes extension points — the rule targets application code building for imagined callers, not a published API designing for its actual ones.
- **Not the linter's job, not this rule's:** unused imports and dead variables are linter territory; abandoned/shadow files are [no-debugging-residue](../anti-patterns/no-debugging-residue.md). This rule targets speculative *design*. (See also [reuse-before-reimplement](./reuse-before-reimplement.md) — the inverse failure of ignoring what exists; not required to apply this rule.)
- **The TS/JS `paths` scope is deliberate, not an omission.** The concept (premature abstraction, config for one constant) is language-agnostic, but the glob is intentionally narrowed to `.ts/.tsx/.js/.jsx`; a consumer repo whose other-language source needs the same guard widens the glob to match its stack — `paths` is tuned per consumer repo, as `reuse-before-reimplement` also notes for its own glob (it narrows a broad default; here you widen a narrow one).
- **Boundary with [simplicity](./simplicity.md).** This rule owns *speculative structure for a hypothetical future* — a config object / options bag / interface / extension point built before a second caller or a second value exists. The present-tense "plainest construct for the shape you have now" (guard clause over pyramid, `map` over `reduce`, a literal in place of a lookup table) is [simplicity](./simplicity.md)'s concern. Test: is the structure built for a future that has not arrived (here), or a needlessly clever construct for the present task (there)? The config-object-for-one-value case lands here.
- **When NOT to apply** — a genuinely complex problem whose essential structure is not speculative. Necessary complexity is not over-engineering; the test is "does the *stated* task need this, or am I guessing at a future?"

## Review Checklist

- [ ] No interface / base class / strategy introduced for a single concrete implementation (no second caller exists).
- [ ] No config / flag / registry system added for a value that does not currently vary — a constant or parameter was used instead.
- [ ] No extension point / generic hook / options-bag / `...rest` passthrough added for a hypothetical future caller.
- [ ] Each abstraction kept is justified by a present, named requirement, not a guessed future one.
- [ ] Smallest sufficient unit chosen (function over class, literal over config) for the stated need.
