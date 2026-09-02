---
name: proof-of-work
description: Produce linked, product-level evidence for a change.
disable-model-invocation: true
---

# Proof of work

Use **sealed verification**: one fresh sub-agent independently proves the claim and packages the evidence. The primary agent carries only the user's claim, checkout path, and returned proof.

## Primary agent

Spawn exactly one sub-agent with no inherited conversation context (`fork_turns: "none"`). Give it a self-contained prompt:

```text
You are the proof agent. Do not invoke $proof-of-work recursively.

Checkout: <absolute-checkout-path>
Claim: <user's exact request>
Ticket: <ticket-id, or "discover if present">

Read <absolute-skill-path>/references/procedure.md and execute it completely. Decide which product evidence surfaces are necessary. Return the proof document path, verdict, evidence links, and cleanup state.
```

Pass factual constraints the user supplied, but no proposed proof plan or implementation conclusions. Wait for the sub-agent; do not perform proof work in parallel.

Inspect its returned artifact. Confirm the document and every local media path exist, all required links are present, the verdict answers the claim, and a fix or improvement shows its baseline capture. Send the sub-agent a focused follow-up if the contract is incomplete.

Completion: one fresh sub-agent completed the procedure and the primary agent handed off its checked proof document, verdict, links, and caveats.
