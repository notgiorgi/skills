# Proof: <ticket or change>

**Verdict:** <PASS | FAIL | PARTIAL | BLOCKED>: <n> of <m> pass<, each defect, inconclusive or unreachable scenario by id and reason>

<The claim in your own words, then what was observed. Two sentences.>

## Look here first

![<What this capture proves>](<relative-image-path>)

<The one or two captures that carry the claim. Before and after together for a fix or improvement.>

## Scenarios

| Id | Scenario and expected outcome | Status | Rung | Evidence |
| --- | --- | --- | --- | --- |
| S1 | <scenario> | <PASS, DEFECT (severity), PRE-EXISTING, INCONCLUSIVE or UNREACHABLE> | <rung reached> | [S1](#s1) |

## Evidence

### S1

<Scenario and expected outcome. Changed path: `<file:symbol>`, shown to run by <log line, row or field>.>

**Baseline (red / before):** <observed defect or measurement> (fix and improvement only)

**Pinned (green / after):** <observed outcome or measurement>

<video controls src="<relative-video-path>"></video>

[Open video](<relative-video-path>)

![<What the screenshot proves>](<relative-image-path>)

<details>
<summary>Second side</summary>

```text
<targeted database, request, CLI, or log evidence>
```

</details>

## Regression

- Safe because: <the one fact>, reached `<rung>`.
- Risks: <how it breaks, where, how likely and how bad, how to check>
- Cleared: <what was checked and why it is fine>
- Before merge: <the cheapest check that catches the real bug>

## Try it

- Open [<product location>](<url>) as `<persona email>`.
- <The steps, as a user would do them.>
- Stays up until <condition>; remove with `<command>`.

## Not proven

<Each INCONCLUSIVE or UNREACHABLE scenario with what would settle it, and anything left out of scope. "Nothing" when empty.>

## Provenance

- Round: <N>, ledger [`ledger.tsv`](ledger.tsv)
- Request: "<the user's words>"
- Revision: `<branch>@<sha>`
- Instance: [<name>](<product-url>)
- Baseline: `<sha>` at [<name>](<baseline-url>) (fix and improvement only)

## Cleanup

<What was removed; what remains, with its identifier and the command that removes it.>
