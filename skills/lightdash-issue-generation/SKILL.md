---
name: lightdash-issue-generation
description: Write Lightdash GitHub or Linear issues from support, bug, repro, or investigation context. Use when the user asks to draft, create, file, or publish a Lightdash bug report, GitHub issue, Linear ticket, customer-facing issue summary, or repro steps.
---

# Lightdash Issue Generation

Generate product-facing Lightdash issues that are reproducible, sanitized, and useful to maintainers.

## Process

1. **Sanitize**
   - Remove customer names, domains, private data, unredacted screenshots, tokens, URLs, emails, workspace names, and exact business data.
   - Use generic actors: "a user", "a customer", "a project", "a custom role".
   - Completion: no customer-specific or secret material remains.

2. **Frame**
   - Lead with what the user experiences and what they expected.
   - Keep implementation detail minimal. Mention only useful keywords: endpoint, CLI command, span name, status code, payload shape/size, version.
   - Do not include recommended fixes unless the user explicitly asks.
   - Completion: a non-engineer can understand the bug, and an engineer has enough anchors to search.

3. **Reproduce**
   - Prefer the seeded project and local Jaffle dbt project:
     - `SEED_PROJECT` in `packages/common/src/index.ts`
     - dbt models in `examples/full-jaffle-shop-demo/dbt/models/`
   - If needed repro content is missing, create the smallest local model/chart/dashboard/content needed.
   - If repro uses content-as-code, include locally verified content-as-code under a `<summary>` tag.
   - If repro uses the Lightdash CLI, include exact commands.
   - Completion: steps can be followed locally without customer context.

4. **Publish Shape**
   - For GitHub bugs, match `.github/ISSUE_TEMPLATE/bug_report.yml`: Description, Steps to Reproduce, version, Cloud or self-hosting.
   - For Linear, use the workspace's issue style and link related issue IDs when already known.
   - Keep titles user-facing: broken capability + condition.
   - Completion: the issue body fits the target tracker and contains no unused sections.

## GitHub Bug Body

```markdown
## Description

[What the user sees. What they expected. Actual error/status if useful.]

## Steps to Reproduce the Bug or Issue

1. [Set up role/project/content]
2. [Run command or use UI]
3. [Observe expected baseline]
4. [Run failing action]
5. [Observe failure]

## version

[Known version, local main, or omit if unknown]

## Cloud or self-hosting

[cloud/self-hosting/unknown]
```

## Repro Blocks

Content-as-code:

````markdown
<details>
<summary>Locally verified content-as-code repro</summary>

```yaml
[minimal content]
```

</details>
````

CLI:

```bash
lightdash config set-url http://localhost:3000
lightdash config set-project <project_uuid>
lightdash preview --name "<name>"
```
