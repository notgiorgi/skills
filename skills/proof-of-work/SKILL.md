---
name: proof-of-work
description: Produce linked, product-level evidence for a Lightdash change.
disable-model-invocation: true
---

# Proof of work

Use **sealed verification**: one fresh Codex proof agent writes the claim, proves it in the real product, and packages the evidence. The primary agent carries the user's words, pointers to sources, and the returned proof.

Delegate to that proof agent unless the user asks this agent to run the proof itself (typical when the session was started fresh for exactly that) or no Codex spawn path exists. Then read `references/procedure.md`, execute it completely, and hand off the same contract.

`/proof-of-work` is user-invoked, so other threads and sub-agents have no such skill. When you hand a proof to one, give it this file's absolute path.

## Preflight

Confirm the head is pushed (`git status -sb` shows no `ahead`) and, for a Rainbow proof, that `tools.rainbow.list_envs` answers. When either fails, tell the user what is missing and stop here; a proof agent spawned onto a dead instance returns BLOCKED.

## Spawn the proof agent

Choose by harness:

- **Codex**: spawn exactly one native sub-agent at `medium` reasoning effort with no inherited conversation context (`fork_turns: "none"`).
- **Claude Code in T3 Code**: call `delegate_task` with `target: { providerInstanceId: "codex", options: { reasoningEffort: "medium" } }`, `role: "test"`, `mode: "async"`, shared isolation (the proof must run against this checkout), and a `clientRequestId`. Keep the returned `taskId` and end the turn; completion wakes this thread. On `hasPendingQuestion`, read it through `t3_pending_request_list` / `t3_pending_request_read` with the `childThreadId`, answer with `t3_pending_request_respond` from facts the user gave, and otherwise relay it to the user.
- **Any other harness**: no spawn path; run the procedure yourself.

Fill in this brief and send nothing else:

```text
You are the proof agent.

Checkout: <absolute-checkout-path>
Request: "<the user's words, verbatim>"
Sources: <PR URL, ticket id, or spec path the user named; else "discover">
Environment: <facts the user stated or Preflight observed: instance name, where credentials are, what to leave running>
Round: <1, or N plus the ledger path>

Read <absolute-skill-path>/references/procedure.md and execute it completely. Return the proof document path, the verdict line, one line per scenario, evidence links, and cleanup state.
```

The brief is **sealed**: the proof agent derives the claim and the scenarios from Request and Sources. Every line you write names a location or a fact about the environment. What the change does, how it works, what to test and what to expect reach the proof agent only through Sources and through words the user typed, which go into Request unedited.

While the proof runs, do only work that leaves the checkout and the instance untouched.

Completion: the brief is the template filled in, with Request quoted verbatim.

## Check the proof

A proof exists only as a document with a verdict line. When the proof agent stops without one, report the proof as unfinished and start a new round; pushing and merging wait for a verdict.

Open the document. Look at every image and one frame of every video, and confirm each shows what its scenario states. Confirm every local media path exists, the verdict line matches the scenario table, every DEFECT carries its baseline result, and the ledger has a row for every scenario. Send any gap back as a new round.

Completion: every image has been viewed and every check above holds.

## Hand off

The reply alone lets the user decide. Write it in this order, in words a teammate would say:

1. One sentence with the verdict and its tally.
2. The one or two captures that carry the claim, embedded inline, each captioned with what it shows; before and after together for a fix. Link the videos.
3. One line per scenario. A DEFECT says what a user would see, the example that triggered it, and its severity. An UNREACHABLE or INCONCLUSIVE scenario says what would settle it.
4. Regression: the one fact the change is safe because of, how far it was proven, and the risks left.
5. Try it: the live URL, the persona to sign in as, and the steps.
6. Each call waiting on the user, with your pick.
7. The proof document path.

Hashes, ports and commands appear only where the user needs one to act. When the user wants the proof on the pull request, add one line to its description saying how the change was proven and attach the captures from item 2.

## Rounds

A re-run is a new **round** of the same proof: the same brief with `Round: N` and the ledger path. The proof agent re-proves the open ids and whatever the new diff touches, and the ledger keeps every earlier row.

Budget three rounds. When a blocker or should defect is still open after the third, show both sides in two lines each and let the user decide; a spent budget leaves the verdict at FAIL.

Completion: the primary agent handed off a checked proof document with its verdict, captures, regression note, try-it steps and open calls.
