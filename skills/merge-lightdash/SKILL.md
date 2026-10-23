---
name: merge-lightdash
description: Merge a Lightdash PR once required checks and Build & Test CI pass, allowing verified unrelated flaky tests.
disable-model-invocation: true
---

# Merge Lightdash

Only run when explicitly invoked by the user. Invocation authorizes merging the selected Lightdash PR once these gates pass on its latest head:

- All GitHub-required checks.
- Build & Test CI: build, lint, format, and unit tests. Resolve the actual jobs from the PR's live checks and workflow definitions; names may be `Build & Test`, or `Build & Lint` plus `Unit Tests` matrix jobs.

Use the Lightdash checkout (usually `../lightdash`) to identify the repository and selected/current-branch PR. Ask if the target is ambiguous.

Check the PR's live CI jobs against the workflow definitions. Missing, skipped, cancelled, or stale Build/Unit test results do not count as passing. Recheck after any head change.

Optional e2e checks are often flaky: their pending or failed status does not block this workflow. Required e2e checks still gate merging. Do not rerun or fix optional e2e tests merely to make everything green.

Any failing test, including a unit test, may be treated as nonblocking when logs show the same failure on recent `main` runs and the failure is unrelated to the PR's changes. Verify both before applying this exception; do not infer flakiness from a red check alone. Report the ignored failures and supporting run links. GitHub-required checks still must satisfy branch protection.

Monitor until the gates pass, using the host's PR watcher when available. If a gating check fails, report the blocker. Once gates pass, merge the verified head using the repository's normal merge method, respecting branch protection and required approvals. Never bypass protections.

Report the merged PR, or the exact blocker if merging is unavailable.
