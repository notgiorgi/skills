# Proof procedure

Instance mechanics (launch, doctor, login, database, cleanup) are in [`lightdash.md`](lightdash.md): read it before step 2. Per-feature recipes are indexed in [`../features/README.md`](../features/README.md): read the matching files before step 4.

## 1. Pin the claim

The brief gives the user's Request and its Sources. Read them, the branch diff, and the originating ticket or pull request description. Resolve a ticket only from explicit input, branch or commit metadata, or an authoritative tracker. Record the branch, the exact revision, and the **baseline** revision with why it was chosen: a revision the user named; else, for a stacked branch, the parent branch's head; else the merge-base with the default branch.

Write the claim **in your own words**, as outcomes a user of the product can observe, each naming its exact surface. A source sentence about implementation becomes the behaviour it causes. One with no observable behaviour goes under Not proven as out of scope.

Turn the claim into scenarios with stable ids (`S1`, `S2`, ...) and explicit expected outcomes. On round N, read the ledger first and pin the claim again from the current Sources: keep the ledger's ids, give new ids to anything the Sources added, re-prove the open ones, the new ones and the ones the new diff touches, and **carry** the rest. A carried scenario keeps its earlier status and the revision it was proven at. An id whose part of the claim the current Sources withdrew gets a `WITHDRAWN` row and a line under Not proven.

Classify each scenario:

- **Fix**: red then green. The defect reproduces on the baseline revision, then the same steps succeed on the pinned revision. A security fix goes red and green the same way, through a harmless synthetic input that reaches the vulnerable path.
- **Improvement**: a comparison. Capture the same measurement or interaction on the baseline and on the pinned revision, side by side. For a performance number, follow the `benchmark-checklist` skill.
- **Feature**: the new behaviour on the pinned revision.

For each scenario, name the **changed path** it exercises: the code in the diff that must run for the outcome to appear.

Depth follows the Request. With none stated, cover the main path of each material part of the claim and the negative or continuation paths the claim names, such as approve and deny.

Completion: every material part of the claim maps to a scenario with an expected outcome and a changed path; every fix or improvement scenario names its baseline capture.

## 2. Pin the instance

Get the pinned instance and, when a scenario needs one, the baseline instance, as `lightdash.md` Launch describes. Run its Doctor on each before the first drive and again after anything surprising.

Completion: the proof can name the checkout, the revision and the URL of each instance, and each passed Doctor at its revision.

## 3. Choose causal evidence

Each scenario climbs the **evidence ladder** as far as the claim needs, and records the rung it reached:

1. `claimed`: someone said so.
2. `read`: a `file:line` shows it.
3. `tested`: an automated test or direct invocation ran it.
4. `observed`: the real product showed it through the user's surface.
5. `corroborated`: observed, plus a second side that agrees: a database row, an API read, a log or trace, or red on baseline against green on pinned.

A claim about product behaviour passes at `observed`. A fix, and any claim that crosses a boundary, passes at `corroborated`. Pure non-product behaviour passes at `tested`.

| Claim | Typical evidence |
| --- | --- |
| Visible state or layout | Product URL + screenshot |
| Interaction, approval, denial, or continuation | Video + final product state |
| Agent/tool/runtime path | Product result + persisted tool-call, log or trace evidence |
| Persistence | Product/API result + targeted database before/after evidence |
| Endpoint authorization | Real requests as allowed and denied identities, with status and body |
| CLI or content-as-code | Real CLI command + resulting server or product state |
| Pure non-product behaviour | Focused automated test or direct invocation |

Completion: each scenario has a target rung, and its planned evidence rules out a merely plausible UI, a mocked response, and an unexecuted backend path.

## 4. Execute and capture

Exercise the real product with sanitized synthetic data, in character as its user. First split each scenario into its fixture and its surface under proof. The fixture is everything the claim takes as given; seed it the cheapest way that leaves the proof real (database inserts, stubs, a synthetic user or agent), starting from this proof's earlier `r<N>/` scripts or the `features/` recipes. The surface under proof is the behaviour the claim is about; produce it only through the path a real user would take. To prove agent compaction: seed the user and agent in the database, then start a thread from the product and send enough messages to trigger a compact. Every input typed into the product reads like a real user's, a plain question or task; ticket ids and proof labels stay in the proof document. Preserve user work and connected state. Verification is read-only with respect to source code: report a failing claim instead of implementing a fix.

Show that the **changed path** ran: a log line, database row, tool call or response field that only the new code produces. An outcome that appears without it proves the old path.

Run a scenario whose outcome varies between runs, such as model behaviour, at least three times per side, alternating baseline and pinned, and report the counts. Record which model answered.

When an observation contradicts the expectation, check the observation method first: the instance, the persona, the flag state, the capture. Then check the recipe against the source; recipes can trail the product.

For a temporal claim, capture one continuous video from the triggering action through the final continued state, with the pointer visible. Use separate scenarios when decisions lead to different paths. Capture compact, relevant output rather than broad dumps.

Completion: every scenario ran through the user's surface against the pinned instance, baseline captures ran against the baseline instance, each scenario's changed path is shown to have run, and captured artifacts expose no credentials, customer data, or unrelated private information.

## 5. Assess regression

Follow the `blast-radius` skill on the diff: find the one fact the change is safe because of, prove it as far up the evidence ladder as is cheap, and list the risks you confirmed and the ones you cleared. Probe the top confirmed risk in the product as scenario `R1`.

When the Request limits depth, write `Regression: not assessed, depth limited by request`.

Completion: the safety fact is stated with its rung, or marked unproven.

## 6. Judge

Give each scenario one status:

- **PASS**: the expected outcome reached its target rung.
- **DEFECT**: the change misbehaves. Before recording it, run the same steps on the baseline; identical behaviour there makes it PRE-EXISTING. When the surface does not exist on the baseline, record `baseline: surface absent` instead. Give it a severity: `blocker` when the intended case is wrong, `should` when it is a real case users will hit inside the claim, `nit` for anything else.
- **PRE-EXISTING**: wrong on the baseline too.
- **INCONCLUSIVE**: it ran, and the evidence stops below the target rung or the difference is within run-to-run variation.
- **UNREACHABLE**: it could not be run. Name the prerequisite and the route you attempted. A scenario you chose not to run is INCONCLUSIVE, with the reason.
- **WITHDRAWN**: the Sources no longer claim it. It stays out of the tally.

The verdict follows from the statuses:

- **FAIL**: at least one blocker or should defect.
- **PASS**: every scenario passed. Nits and pre-existing behaviour are listed.
- **PARTIAL**: no blocker or should defect, and at least one scenario is INCONCLUSIVE or UNREACHABLE.
- **BLOCKED**: no scenario could run.

The verdict line carries the tally over every id in the ledger, latest row per id, and names each scenario that did not pass and each carried one, for example `PARTIAL: 5 of 6 pass (2 carried), S4 unreachable (needs BigQuery credentials)` or `PASS: 6 of 7 pass, S4 pre-existing`.

Completion: every ledger id has a status and rung in the table, every DEFECT has a severity and its baseline result, and the verdict line follows from the table.

## 7. Package the proof

Name the directory after the ticket id; when the ticket spans several pull requests, `<ticket>-<short-pr-slug>`. With no ticket, derive a short lowercase kebab-case slug from the claim, such as `homepage-ask-ai`. The proof lives in `~/.local/proofs/<repo>/<name>/`, outside the checkout so it survives the worktree; `<repo>` is the origin's repository name.

- `proof.md` is the current truth: every round, write it fresh from [`../assets/PROOF.md`](../assets/PROOF.md), covering every ledger id, carried ones included. Remove unused fields and every placeholder. Earlier rounds live in the ledger and their media folders, never in copies of `proof.md`.
- `ledger.tsv` is the history: copy [`../assets/ledger.tsv`](../assets/ledger.tsv) on round 1 and append one row per scenario every round, carried ones included. Rows are never edited; a later row for the same id supersedes an earlier one.
- Media and fixture scripts go in `r<N>/` beside them, referenced by relative path.
- Cite source as repo-relative `path:line` text; checkout paths die with the worktree.

The verdict line and the captures that carry the claim come first, ahead of any provenance. Embed every image with Markdown, captioned with what it proves. Embed every video with HTML `<video controls>` and add a normal link as fallback. Put targeted database, request, CLI, or log evidence inline or in compact `<details>` blocks. Product links die with their instance, so each scenario's proof rests on captured media and output; links are for the reviewer's Try it window.

Completion: the document has the verdict line, the carrying captures, the scenario table, per-scenario evidence, regression, try-it steps, what was not proven, provenance and cleanup state, and the ledger has this round's rows.

## 8. Clean up and audit

Clean up as `lightdash.md` Cleanup describes: the pinned instance stays up for the reviewer, everything else this run started goes, and the Cleanup section lists what remains with the command that removes it.

Run [`../scripts/check-proof`](../scripts/check-proof) `<proof-dir>` unmodified until it prints `ok`; when it rejects something this procedure allows, return that as a skill gap. Then view every contact sheet it wrote to `contact/` and confirm each shows what its scenario states, and that the Try it URL answers.

Return:

- proof document absolute path;
- the verdict line;
- one line per scenario with its status;
- the regression safety fact and its rung;
- the Try it URL and what remains running;
- exact blockers or caveats.

Completion: another person can open one document, see whether the change works from its first screen, and independently inspect every claimed proof surface.
