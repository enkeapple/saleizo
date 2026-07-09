---
description: 'Enforces single-responsibility functions - split a function that does several unrelated things (fetch AND validate AND transform AND log AND persist) into named single-purpose functions composed together; not about length, a long cohesive function is fine.'
paths:
  - '**/*.{ts,tsx,js,jsx}'
---

# Concise Functions — one task per function

## When

STOP and check before writing or approving a function body: if the only way to describe it strings together **unrelated concerns** with "and" ("fetches the user AND validates it AND writes to the log"), it has several reasons to change — split it. Steps that build toward one outcome ("parse AND verify AND extract" to decode a token) are one responsibility even though "and" appears — judge by reasons-to-change, not by counting "and"s (see Edge Cases).

## Why

A capable agent under time pressure tends to grow the function it is already inside rather than open a new one, because adding one more step to an existing body is the path of least resistance. The result is a function with several reasons to change (a validation rule, a logging format, a persistence detail) all bundled in one place, so an unrelated edit risks breaking unrelated behavior and the diff for a single-concern change touches code that concern doesn't own.

## Implementation

**Give each function exactly one reason to change, and name that reason in its function name.**

- **Split on responsibility, not on size:** if a function mixes fetching, validating, transforming, logging, and persisting, extract one function per concern and compose them — the composing function becomes a short list of named calls.
- **Name each piece for what it decides or does:** `validateOrderPayload`, `normalizeOrderTotals`, not `helper1`/`processStep2`.
- **The composing function orchestrates, it does not itself validate/transform/persist:** if it still contains a raw `if` branch doing business logic alongside the calls, a responsibility was left behind.
- **Stop splitting once each piece has exactly one reason to change** — do not keep decomposing past that point (see Edge Cases).

```text
❌ WRONG — one function, five reasons to change (illustrative):
async function handleOrder(raw: unknown) {
  const data = JSON.parse(raw as string);           // parsing
  if (!data.id || !data.items?.length) {            // validation
    throw new Error('invalid order');
  }
  const total = data.items.reduce(                   // transformation
    (sum: number, i: any) => sum + i.price * i.qty, 0,
  );
  console.log(`order ${data.id} total=${total}`);    // logging
  await db.orders.insert({ ...data, total });         // persistence
}

✅ CORRECT — one task per function, composed (illustrative):
function parseOrder(raw: unknown): OrderInput {
  return JSON.parse(raw as string);
}

function validateOrder(order: OrderInput): void {
  if (!order.id || !order.items?.length) {
    throw new Error('invalid order');
  }
}

function computeOrderTotal(order: OrderInput): number {
  return order.items.reduce((sum, i) => sum + i.price * i.qty, 0);
}

async function handleOrder(raw: unknown) {
  const order = parseOrder(raw);
  validateOrder(order);
  const total = computeOrderTotal(order);
  logger.info(`order ${order.id} total=${total}`);
  await db.orders.insert({ ...order, total });
}
```

## Edge Cases

- **Not about length.** A long function that performs one cohesive task (a single state-machine transition, a single parsing pass over a fixed grammar) is fine as-is — do not split by line count alone.
- **Performance hot paths** may inline steps deliberately to avoid call overhead or preserve locality; note the reason in a comment rather than splitting reflexively.
- **When NOT to apply:** trivial one-line wrappers, generated code, and test setup/fixture functions that intentionally sequence several calls for readability, not because they own several responsibilities.
- **Do not over-correct into pointless indirection** — splitting is warranted by genuinely distinct responsibilities, not by a line-count trigger; a one-line function that only forwards to another is a smell, not a fix — see-also [no-needless-indirection](./no-needless-indirection.md).
- A function with several sequential steps toward ONE outcome (e.g. building up a single return value) is one responsibility, not several.
- **Efficacy basis.** Unlike a pure-policy sibling (e.g. [clear-names](./clear-names.md)'s export-floor half), this RED-steers even a capable model on the incremental-growth case — adding an Nth concern to a function you are already inside — and on the orchestrator-purity check; it is not clean-authoring no-op, so it needs no export-floor carve-out.

## Review Checklist

- [ ] No function body mixes fetch/validate/transform/log/persist concerns (manual read — no reliable grep; look for one function that both calls I/O and branches on business rules).
- [ ] Each extracted function name states the one thing it does (no `helper`, `process`, `handleStuff`).
- [ ] The orchestrating/composing function contains only calls and control flow, no inline business logic of its own.
- [ ] No new function is a pure one-line pass-through introduced solely to satisfy this rule.
- [ ] A flagged "long" function is re-checked against reasons-to-change, not line count, before splitting.
