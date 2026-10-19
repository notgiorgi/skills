---
name: proof-of-work
description: Produce linked, product-level evidence for a change.
disable-model-invocation: true
---

# Proof of work

Use **sealed verification**: one fresh Codex proof agent independently proves the claim and packages the evidence. The primary agent carries only the user's claim, checkout path, and returned proof.

Delegate to that proof agent unless the user asks this agent to run the proof itself (typical when the session was started fresh for exactly that) or no Codex spawn path exists. Then read `references/procedure.md`, execute it completely, and hand off the same contract.

## Spawn the proof agent

Choose by harness:

- **Codex**: spawn exactly one native sub-agent with no inherited conversation context (`fork_turns: "none"`).
- **Claude Code in T3 Code**: call `delegate_task` with `target: { providerInstanceId: "codex" }`, `role: "test"`, `mode: "async"`, shared isolation (the proof must run against this checkout), and a `clientRequestId`. Keep the returned `taskId` and end the turn; completion wakes this thread. On `hasPendingQuestion`, read it through `t3_pending_request_list` / `t3_pending_request_read` with the `childThreadId`, answer with `t3_pending_request_respond` from facts the user gave, and otherwise relay it to the user.
- **Any other harness**: no spawn path; run the procedure yourself.

Give it a self-contained prompt:

```text
You are the proof agent. Do not invoke $proof-of-work recursively.

Checkout: <absolute-checkout-path>
Claim: <user's exact request>
Ticket: <ticket-id, or "discover if present">

Read <absolute-skill-path>/references/procedure.md and execute it completely. Decide which product evidence surfaces are necessary. Return the proof document path, verdict, evidence links, and cleanup state.
```

Pass factual constraints the user supplied, but no proposed proof plan or implementation conclusions. Wait for the proof agent; do not perform proof work in parallel.

## Check the proof

Inspect the returned artifact. Confirm the document and every local media path exist, all required links are present, the verdict answers the claim, and a fix or improvement shows its baseline capture. If the contract is incomplete, send the proof agent a focused follow-up; in T3 Code that is a new `delegate_task` round carrying the original prompt plus the gap, with its own `clientRequestId`.

Completion: the proof agent completed the procedure and the primary agent handed off its checked proof document, verdict, links, and caveats.
