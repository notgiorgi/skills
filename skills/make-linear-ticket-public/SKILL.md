---
name: make-linear-ticket-public
description: Cancel a private Linear ticket and republish it as a sanitized public GitHub issue, then restore project/status/owner/PR onto the auto-linked Linear ticket.
disable-model-invocation: true
---

# Make a Linear Ticket Public

Move a private Linear ticket into the public `lightdash/lightdash` tracker: cancel the original, publish a sanitized GitHub issue, and restore the original's state onto the Linear ticket the GitHub sync auto-creates. Use whatever Linear access is available (MCP tools, API); use `gh` for GitHub.

## Steps

1. **Capture** the original Linear ticket: title, description, team, project, status, assignee, and attachments (PR links). Done when every field restored in step 5 is recorded.
2. **Sanitize** title and body for the public repo. Remove customer names, domains, emails, workspace names, tokens, links to private systems, unredacted screenshots, and exact business data; use generic actors ("a user", "a customer", "a project"). Internal code and architecture detail is fine — the repo is open source. Done when nothing in title or body identifies a customer or leaks a secret.
3. **Cancel** the original: set its status to Canceled.
4. **Publish** the GitHub issue: `gh issue create -R lightdash/lightdash` with the sanitized title and body (via `--body-file`). Then poll the issue's comments (10s interval, up to ~2 min) for the `<!-- linear-linkback -->` comment; its link names the auto-created Linear ticket. Done when you have that ticket's identifier (it lands in the PROD team, in Triage).
5. **Restore** the original's state onto the new ticket in one update: team, project, status, assignee, and the original's PR URLs as links. Team and project must be set together — setting a project owned by another team without also setting the team fails with "Discrepancy between issue team and state, cycle or project". Moving teams renumbers the ticket; use the new identifier from then on. Done when re-fetching the new ticket shows team, project, status, assignee, and PR attachment matching the capture from step 1.

Report the GitHub issue URL and the new Linear ticket URL.
