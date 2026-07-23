---
name: ship-change
description: "Implement, verify, review, optionally security-review, and submit a change."
disable-model-invocation: true
---

# Ship Change

## Inputs

- **Change** — required ticket, document, plan, or inline requirements.
- **Verification** — required method or acceptance procedure.
- **Security review** — optional.

## 1. Implement

Implement the change. Continue until every requested behavior is implemented.

## 2. Verify

Verify using the provided method and capture evidence. If it fails, go to step 1.

## 3. Review

Spawn a _fresh_ sub-agent to review the change. Validate its findings. If any are valid and in scope, go to step 1. Repeat until no valid, in-scope findings remain.

## 4. Security review

Only run this step if the user requested it. Use `herdr` to spawn Claude and run `/security-review`. If it has useful findings, go to step 1 and repeat the loop.

## 5. Submit

Use Graphite to commit and submit the PR.

## 6. Handoff

Summarize the changes and present concrete validation proof: test output, browser screenshots, `psql` data, API responses, or equivalent evidence.

Offer to set up the validation so the user can run it manually, with exact steps.
