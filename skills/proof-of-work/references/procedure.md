# Proof procedure

## 1. Pin the claim

Read the user request, current branch/diff, and originating ticket or spec when available. Resolve a ticket only from explicit input, branch/commit metadata, or an authoritative tracker; never invent one. Record the branch and exact revision.

Turn the claim into observable scenarios with explicit expected outcomes. Include negative or continuation paths when they are part of the claim, such as approve and deny.

Completion: every material part of the claim maps to an observable scenario and expected outcome.

## 2. Pin the product instance

Identify the running instance that belongs to this checkout before testing. Verify URLs, processes, and environment against the worktree rather than assuming defaults. In Lightdash, check `OTEL_SERVICE_NAME`, `PORT`, and `FE_PORT`, then confirm the browser, API, database, and trace scope point at that instance.

Completion: the proof can name the checkout, revision, product URL, and runtime/trace scope it exercised.

## 3. Choose causal evidence

Use the smallest combination that proves the claim end to end. A boundary-crossing claim needs evidence on both sides of the boundary.

| Claim | Typical evidence |
| --- | --- |
| Visible state or layout | Product URL + screenshot |
| Interaction, approval, denial, or continuation | Video + final product state |
| Agent/tool/runtime path | Product result + trace + persisted tool-call or log evidence |
| Persistence | Product/API result + targeted database before/after evidence |
| Endpoint authorization | Real requests as allowed and denied identities, status/body, and trace/log when execution path matters |
| CLI or content-as-code | Real CLI command + resulting server or product state |
| Pure non-product behavior | Focused automated test or direct invocation |

Tests and source inspection can support proof, but cannot substitute for product evidence when the claim is about product behavior.

Completion: each scenario has enough independent evidence to rule out a merely plausible UI, mocked response, or unexecuted backend path.

## 4. Execute and capture

Exercise the real product with sanitized synthetic data. Preserve user work and connected state. Verification is read-only with respect to source code: report a failing claim instead of implementing a fix.

Use `agent-browser` for browser interaction, screenshots, videos, and product URLs. First run `agent-browser --help` and use its current built-in guidance; keep command knowledge in the tool, not this skill. For desktop proof, set a `1440x1000` viewport before target navigation and capture. Use a claim-specific viewport for responsive or device behavior.

Use the product's native interfaces where they strengthen causality. For local trace discovery and inspection, start with `maple --help`. Also consider targeted logs, `psql`, `curl`, a development CLI, or content-as-code. Inspect each tool's current help and repository guidance before use. Capture compact, relevant output rather than broad dumps.

For a temporal claim, capture one continuous video from the triggering action through the final continued state. Use separate scenarios when decisions lead to different paths.

For every trace mentioned, include its clickable trace URL when the environment exposes one. Otherwise include the trace ID and exact command that reopens it. Link every created thread, dashboard, chart, saved content item, or other relevant product location.

Prefer durable product links. Clean disposable intermediates after capture. If cleanup would break evidence links, preserve those evidence records through handoff and list their identifiers and cleanup action in the proof document.

Completion: all scenarios ran against the pinned instance; captured artifacts expose no credentials, customer data, or unrelated private information.

## 5. Package the proof

Copy [`../assets/PROOF.md`](../assets/PROOF.md) to the checkout root. Name it `PROOF-<TICKET>.md` when a ticket exists. Without a ticket, derive a short lowercase kebab-case slug from the claim and name it `PROOF-<slug>.md`, such as `PROOF-homepage-ask-ai.md`. Put media beside it in the matching `PROOF-<TICKET>.assets/` or `PROOF-<slug>.assets/` directory and use relative paths. Duplicate the evidence block for each scenario and remove unused fields and every placeholder.

Keep the summary short. Embed every image with Markdown. Embed every video with HTML `<video controls>` and add a normal link as fallback. Link all product locations and every linkable trace. Include targeted database, request, CLI, or log evidence inline or in compact `<details>` blocks.

Keep the proof document and assets untracked. Never stage or commit them.

Completion: the document contains the verdict, tested scenarios, revision/instance, all media, all relevant product and trace links, supporting evidence, caveats, and cleanup state.

## 6. Audit the artifact

Open the finished document and verify every local path exists, images render, videos play, external links target the pinned instance, and evidence supports the stated verdict. Check `git status` confirms the proof artifacts are untracked and no unrelated files changed.

Return:

- proof document absolute path;
- PASS, FAIL, or BLOCKED verdict;
- one line per scenario;
- product and trace links;
- preserved evidence records and cleanup state;
- exact blockers or caveats.

Completion: another person can open one document and independently inspect every claimed proof surface.
