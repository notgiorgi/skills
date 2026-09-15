---
name: proof-of-work
description: Produce linked, product-level evidence for a change.
disable-model-invocation: true
---

# Proof of work

Use **sealed verification**: one fresh Codex proof agent independently proves the claim and packages the evidence. The primary agent carries only the user's claim, checkout path, and returned proof.

Delegate to that proof agent unless the user asks this agent to run the proof itself (typical when the session was started fresh for exactly that). Then read `references/procedure.md`, execute it completely, and hand off the same contract.

## Spawn the proof agent

Choose by harness:

- **Codex**: spawn exactly one native sub-agent with no inherited conversation context (`fork_turns: "none"`).
- **Any other harness** (Claude Code, etc.): follow the `/herdr` skill to run Codex via CLI. Split a sibling pane, `herdr agent start proof --kind codex --pane <pane-id>`, then deliver the prompt with `herdr agent prompt proof "<prompt>" --wait --timeout 3600000`. On `blocked`, inspect with `herdr agent get proof` and `herdr agent read proof` before answering.

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

Inspect the returned artifact. Confirm the document and every local media path exist, all required links are present, the verdict answers the claim, and a fix or improvement shows its baseline capture. Send the proof agent a focused follow-up if the contract is incomplete.

Completion: the proof agent completed the procedure and the primary agent handed off its checked proof document, verdict, links, and caveats.
