---
description: 'A function/method/wrapper must earn its existence — delete a pure pass-through that only forwards its arguments to another callable and adds no behavior, name, boundary, or reuse. Distinct from simplicity (fewest/plainest constructs) and reuse-before-reimplement (forking existing code). Area-specific to TS/JS.'
paths:
  - '**/*.{ts,tsx,js,jsx}'
---

# No Needless Indirection — A Function Must Earn Its Existence

## When

STOP the moment you are about to write — or leave in place — a function, method, or arrow whose entire body is a call to one other callable with the same arguments: `(...a) => other(...a)`, `x => other(x)`, `method(a) { return dep.method(a); }`, or a const alias/arrow declared solely to re-splat that way (a receiver-preserving `.bind()` is not the target). It shows up as a "service" method that only delegates to a repository, a re-exported helper that only splats its arguments onward, or a hook/util that wraps a single call and adds nothing of its own.

## Why

A pure pass-through adds a layer to read, name, step through in a debugger, and keep in sync — and returns nothing for it. It hides the real callee behind a synonym and doubles the surface a reader must hold in mind. A function earns its place only when it adds something over forwarding: real behavior (validation, mapping, retries, logging), a genuinely better boundary, type narrowing, or reuse across more than one caller (renaming alone is not a reason — surface a name by re-export/bind, see Implementation). Strip those away and the body is "call the other thing" — the layer is noise. Simplicity here is the fewest hops between the caller and the code that actually does the work, which is also the easiest thing to test: fewer indirections, fewer seams a test must reach through.

## Implementation

**Before adding a wrapper, name what it adds beyond forwarding. Nothing → delete it and call the target directly.**

- **Forwarding function/arrow → inline the target call.** A `(...args) => target(...args)`, or a method that only `return`s another callable with the same arguments, is deleted; callers call `target` directly.
- **Delegating layer method → collapse or justify.** A service/manager method whose body is only `return other.method(sameArgs)` adds no boundary **by default** — but first check it is not a deliberate architectural seam (an application-service or port that keeps persistence out of the caller). If it earns a *stated* boundary (see Edge Cases), keep it and justify it in one line; otherwise collapse it and call the lower layer directly.
- **Surface a name by re-exporting or binding, not re-wrapping.** To expose a callable under a name, `export { fn } from '…'` or bind it (`obj.method.bind(obj)` when `this` matters) instead of `const fn = (...a) => obj.method(...a)`.
- **A wrapper you keep must justify itself in one line** — the behavior, boundary, or reuse it adds.

```text
❌ WRONG — a "service" method whose whole body forwards to the repository; no behavior, no boundary (illustrative)
  class OrderService {
    getOrder(id: string) { return orderRepository.findById(id); }
    cancelOrder(id: string) { return orderRepository.cancel(id); }
  }

❌ WRONG — a re-exported helper that only splats its arguments onward (illustrative)
  const track = (...args: Parameters<typeof analytics.track>) => analytics.track(...args);
  track('checkout_start', { id });

✅ CORRECT — call the target directly; the pass-through added nothing
  const order = await orderRepository.findById(id);
  analytics.track('checkout_start', { id });

✅ CORRECT — surface a name without a wrapper: re-export, or bind when `this` matters
  export { track } from '@/lib/analytics';
  const onTrack = analytics.track.bind(analytics);
```

## Edge Cases

- **A wrapper that adds real behavior is not needless** — validation, argument/response mapping, retries, error handling, logging, or type narrowing all earn the layer. When the project centralizes such behavior in its own client/service, calling *through* it is required — see [reuse-before-reimplement](./reuse-before-reimplement.md) (see-also, not required to apply this rule).
- **An adapter / anti-corruption boundary with a real reason** — decoupling code from a vendor's type or signature — earns its place even with a single method today; state the reason in one line. The test is "does it add a boundary", not "does it have more than one method".
- **`this`-binding matters** — when a bare method reference would lose its receiver, bind it (`obj.method.bind(obj)`); that is not the target. Prefer the bound reference over a `(...a) => obj.method(...a)` arrow that only re-splats.
- **Not the linter's job:** an unused variable or an unreferenced import is linter territory, not this rule. This rule targets a *live* pass-through that adds no value, not dead code.
- **Distinct from its siblings:** [simplicity](./simplicity.md) targets the fewest/plainest constructs for the stated problem; this rule targets one specific shape — a callable that only forwards. [reuse-before-reimplement](./reuse-before-reimplement.md) targets forking code that already exists. [concise-functions](./concise-functions.md) governs the opposite move — splitting one over-loaded function into single-purpose ones; when such a split leaves a pure forwarding wrapper, that wrapper is *this* rule's target (concise-functions defers it here). All cross-links are see-also; none is required to apply this rule.

## Review Checklist

- [ ] No function/method/arrow whose body is only `other(sameArgs)` / `(...a) => other(...a)` was added or left in place without a one-line justification of what it adds.
- [ ] No "service"/"manager" layer method that only delegates to a lower layer with the same arguments — either the caller uses the lower layer directly, or the boundary is justified in one line.
- [ ] To surface a callable under a name, it is re-exported or bound (when `this` matters), not re-wrapped in a forwarding arrow.
- [ ] Not a duplicate of `simplicity` (plainest construct) or `reuse-before-reimplement` (forking existing code); those are cross-linked, not restated.
