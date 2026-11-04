---
name: review-loop
description: Review a change before it ships by sequencing code-review and sol-loop, plus a risk round and a PR claims check.
disable-model-invocation: true
---

# Review loop

Every change gets the loop before it ships. Size sets how many rounds, never whether the loop runs.

The loop sequences other skills. Read each one when its step comes up; its rules live there.

## 1. Scope

Pin base and diff as `$sol-loop` step 1 does, and find the standards files as `$code-review` step 3 does. Use that one base for every step. Mark the change **hot path** when it changes behaviour on shared code with many callers and no flag gating it.

Done: base SHA, diff command, standards file list, hot path yes/no.

## 2. Standards

Run `$code-review` against the base. Tests are code: read every new or changed test against the standards' test rules, bulk-edited ones (sed, codemod) included. Fix hard violations before step 3.

Done: every Standards finding fixed or declined with the rule cited.

## 3. Intent

Run `$sol-loop`. Add this line to its round 1 brief so Sol judges against the standards too:

```
Standards: <standards files>. Read them; a breach is a should.
```

Done: sol-loop's stop condition.

## 4. Risk (hot path only)

Intent approval does not cover blast radius; run this even after APPROVE. One fresh Sol review through sol-loop's route, same base diff, with the Intent line replaced by:

```
Risk review. Answer each with file:line or a test name:
- Reachability: every caller that now hits the changed path; which ones tests cover.
- Failure: for each failure (throw, timeout, empty, stale), does the caller get an error or silently get wrong data? Silent wrong data is a blocker.
- Cache: does the key cover every input that changes the result? Are empty or error results cached? What invalidates, and how stale can a hit be?
```

Answer findings per sol-loop step 3. One re-check round if fixes changed behaviour.

Done: every question answered with evidence; no blocker or should open.

## 5. PR claims

If steps 3-4 changed code, rerun step 2 on the final diff first. Then, before writing or pushing the PR body, list each behaviour claim in it (what it does, fixes, leaves unchanged). Each cites a proof artifact (`$proof-of-work` output, screenshot, trace) or a test that shows it. Rewrite a claim the proof contradicts to what the proof shows; delete a claim nothing covers.

Done: every behaviour claim in the PR body cites its proof.

Report: findings per step, whether risk ran and why, claims cut or rewritten.
