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
- **Claude Code in T3 Code**: call `delegate_task` with `target: { providerInstanceId: "codex", options: { reasoningEffort: "medium" } }`, `role: "test"`, `mode: "async"`, shared isolation (the proof must run against this checkout), and a `clientRequestId`. Keep the returned `taskId` and end the turn; completion wakes this thread. On `hasPendingQuestion`, call `t3_pending_request` with `threadId` set to the `childThreadId`: `action: "list"`, then `"read"`; answer with `"respond"` from facts the user gave, and otherwise relay it to the user. A permission prompt reaches the user directly.
- **Any other harness**: no spawn path; run the procedure yourself.

Fill in this brief and send nothing else:

```text
You are the proof agent.

Checkout: <absolute-checkout-path>
Request: "<the user's words, verbatim>"
Sources: <PR URL, ticket id, or spec path the user named; else "discover">
Environment: <facts the user stated or Preflight observed that references/lightdash.md lacks: an instance the user named, where credentials are, what to leave running; else "none">
Round: <1, or N plus the ledger path>

Read <absolute-skill-path>/references/procedure.md and execute it completely. Return the proof document path, the verdict line, one line per scenario, evidence links, and cleanup state.
```

The brief is **sealed**: the proof agent derives the claim and the scenarios from Request and Sources. Every line you write names a location or a fact about the environment. What the change does, how it works, what to test and what to expect reach the proof agent only through Sources and through words the user typed, which go into Request unedited.

Environment holds only facts the user stated or Preflight observed that `references/lightdash.md` lacks. The baseline, a cleanup policy the user never stated, what flag or fixture the feature needs, and rules `lightdash.md` already states stay out of it. A workaround a proof discovers belongs in `lightdash.md`, so the next brief needs no copy.

When another agent relays the request, Request quotes only the human words it relayed (`none relayed` when it relayed none), and the relaying agent's own plan goes under Sources as a file labelled with its author. A Source is something the user or the change's authors wrote; a note you wrote for the proof is a leak, not a Source.

While the proof runs, do only work that leaves the checkout, the branch and the instance untouched; a push waits for the verdict.

Completion: the brief is the template filled in, with Request quoted verbatim.

## Check the proof

A proof exists only as a document with a verdict line. When the proof agent stops without one, report the proof as unfinished and start a new round; pushing and merging wait for a verdict.

Run `<absolute-skill-path>/scripts/check-proof <proof-dir>`: it checks the verdict line, the template sections, every local path, the scenario table against the ledger's latest rows and the verdict against the table, and writes one contact sheet per scenario (its images plus a frame per video) to `<proof-dir>/contact/`. View every sheet and the Look here first captures at full size, and confirm each shows what its scenario states, and that every DEFECT carries its baseline result. Send any gap back as a new round.

Completion: `check-proof` prints `ok`, and every contact sheet and Look here first capture has been viewed.

## Hand off

The reply alone lets the user decide. Write it from `proof.md` and the ledger, which `check-proof` echoes on `ok`; the proof agent's reply is a summary of them, not a source. Write it in this order, in words a teammate would say; when the requester sets its own format, these seven go inside it:

1. One sentence with the verdict and its tally; when the proven revision is behind the branch head, say so.
2. The one or two captures that carry the claim, embedded inline, each captioned with what it shows; before and after together for a fix. Link the videos. A proof without images gets one excerpt of at most 10 lines instead.
3. One line per scenario, with the proof's status, and `carried` for one not re-run this round. A DEFECT says what a user would see, the example that triggered it, and its severity. An UNREACHABLE or INCONCLUSIVE scenario says what would settle it.
4. Regression, on a pass too: the one fact the change is safe because of, how far it was proven, and the risks left.
5. Try it: the live URL, the persona to sign in as, and the steps.
6. Each call waiting on the user, with your pick.
7. The proof document path.

Hashes, ports and commands appear only where the user needs one to act.

## Put the proof on the pull request

When the change has a pull request, its description carries the proof too: one line saying how the change was proven and the verdict, then the proof document's Look here first captures with their captions, before and after together for a fix. Link videos; GitHub won't embed them.

GitHub renders only hosted images, and instance URLs die with the instance. Run `<absolute-skill-path>/scripts/pr-captures <pr> <round> <png>...` (add `--gist <id>` on later rounds): it hosts the PNGs in a secret gist, checks each URL serves an image, and prints one commit-pinned Markdown embed per file. Edit the existing description rather than replacing it. Every later round replaces the proof block with its own.

For a security fix, the description gets the verdict line alone; captures would demonstrate the attack in public.

Completion: `gh pr view <pr> --json body` shows the latest round's verdict line and every embed `pr-captures` printed.

## Rounds

A re-run is a new **round** of the same proof: the same brief with `Round: N` and the ledger path, and new Sources when the claim grew. The proof agent re-proves the open ids, the new ones and whatever the new diff touches, carries the rest, and the ledger keeps every earlier row.

When a baseline does not reproduce the defect, hand off with what would reproduce it; the next round waits for the user. Budget three rounds; a round that only adds scenarios for a widened claim does not spend one. When a blocker or should defect is still open after the third, show both sides in two lines each and let the user decide; a spent budget leaves the verdict at FAIL.

Completion: the primary agent handed off a checked proof document with its verdict, captures, regression note, try-it steps and open calls, and any pull request carries the captures.
