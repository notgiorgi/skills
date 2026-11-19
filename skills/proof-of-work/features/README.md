# Lightdash feature map

The maintained recipes for driving Lightdash features the way a user does. Read the file that matches each scenario before driving it; a proof that drives one convenient entry point is incomplete when the file lists others the claim covers.

## Conventions

- `$ENV_URL` is the instance's base URL, `$PAT` the seed token, and `guest:` marks a command run inside a preview env through `tools.rainbow.exec`. Instance, personas, sign-in, database and file transfer are in [`../references/lightdash.md`](../references/lightdash.md).
- Treat every command as literal.
- Mutate proof-owned content: create a dashboard, agent or project for the run and leave seed content as it was.
- A recipe that fails because the seed lacks a precondition is a finding for that file's Gotchas, and the scenario is UNREACHABLE; the journey stays as written.

## Features

- [AI agent thread](ai-agent-thread.md): pick an agent, run a turn, read tool calls and artifacts, SQL approval, follow-ups.
- [Dashboards and saved charts](dashboards-and-charts.md): open, edit, filter, parameters, date zoom, history, duplicate, promote, delete, roles, minimal page, embed.
- [Composer charts](composer-charts.md): pipeline charts as dashboard tiles, run, export, versions and rollback, promotion, agent edits.
- [Content as code](content-as-code.md): CLI download and upload, and the `/code/...` API.
- [MCP server](mcp.md): auth, listing tools, the composer `query` tool, node reuse.
- [Slack agent](slack.md): local instance only, through a tunnel.

## Entry contract

Each file opens with an H1 and one paragraph of user-visible behaviour, then exactly four H2s in order: `Sub-features`, `How to get to it (user POV)`, `Driving it` (starting with `Preconditions:`), `Gotchas`. Name only user paths, stable handles, required state, commands and observable proof.

Keep the map honest with the `maintain-verification-skill` skill, pointed at this directory.
