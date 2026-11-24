# MCP server

Lightdash serves a Model Context Protocol server over Streamable HTTP. An MCP client (Claude, Cursor, a script) connects with a personal access token or OAuth, lists Lightdash tools, and calls them to explore the semantic layer, run queries, read content and render charts in the user's projects.

## Sub-features

- `mcp-auth` accepts a PAT or OAuth bearer and rejects anonymous calls.
- `mcp-list` lists the tools with their schemas.
- `mcp-query` runs the composer `query` tool and returns rows.
- `mcp-result` pages a finished or still-running query via `get_query_result`.
- `mcp-content` reads, edits and creates composer charts through `read_content`, `edit_content`, `create_content` with `type: "composer_chart"` (create `from: "node"` with `sessionId`, `nodeId`, `dashboardSlug`, or `from: "json"`).
- `mcp-chart-app` serves the `render_chart` UI resource `ui://render-chart/chart.html`.
- `mcp-other` covers the other tools (`run_metric_query`, `run_sql`, `find_content`, data app and custom chart type tools).
- `mcp-record` stores every tool call for audit.

## How to get to it (user POV)

- Project-pinned endpoint `$ENV_URL/api/v1/mcp/projects/$P`, the URL a user pastes into an MCP client.
- Org-wide endpoint `$ENV_URL/api/v1/mcp`, with the project in tool arguments or the `X-Lightdash-Project: $P` header.
- OAuth discovery at `$ENV_URL/.well-known/oauth-protected-resource/api/v1/mcp` for clients that sign in interactively.

## Driving it

Preconditions:

- `P=3675b69e-8324-4110-bdca-059031aa8da3` (seed project `SEED_PROJECT`).
- MCP on for the org: `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/aiAgents/settings"` shows `"mcpEnabled": true`. Rainbow sets `MCP_ENABLED=true`; elsewhere the `ai-copilot` flag also enables it.
- `query` is listed only with the `compose-sql-runner` flag on (it is in previews), a caller who can manage Explore, and, on an agent-pinned connection, the agent's `enableDataAccess` and `enableComposerQueries`; `sql` nodes also need SQL Runner access. `get_query_result` comes with any of `query`, `run_sql`, `run_metric_query`.
- Every request sends `-H "Authorization: ApiKey $PAT" -H 'Content-Type: application/json' -H 'Accept: application/json, text/event-stream'`; below, `$H` stands for these three headers.

- **Reject anonymous.** `curl -i -X POST "$ENV_URL/api/v1/mcp/projects/$P" -H 'Content-Type: application/json' -d '{}'`. Status 401 with `WWW-Authenticate: Bearer resource_metadata="$ENV_URL/api/v1/oauth/.well-known/oauth-protected-resource"`.
- **Initialize (optional).** `curl $H "$ENV_URL/api/v1/mcp/projects/$P" -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"proof","version":"1"}}}'`. `result.serverInfo.name` is `Lightdash MCP Server`; the response header `Mcp-Session-Id` names the client session.
- **List tools.** `curl $H "$ENV_URL/api/v1/mcp/projects/$P" -d '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'`. `result.tools[].name` includes `query`, `run_metric_query`, `run_sql`, `get_query_result`, `read_content`.
- **Run a query.** `curl $H "$ENV_URL/api/v1/mcp/projects/$P" -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"query","arguments":{"projectUuid":"'$P'","queries":[{"sourceType":"sql","nodeId":"numbers","title":"Numbers","description":"Synthetic numbers","sql":"SELECT generate_series(1,40) AS value","limit":500}]}}}'`. `result.structuredContent` has `status: "done"`, `rowCount: 40`, every terminal row in `rows`, `sessionId`, and `nodes[]` with `queryUuid`, `columns` and `sample` (null on the terminal node); `result.content[0].text` repeats it as text with the rows as CSV. Node kinds: `semanticLayer`, `sql`, `duckdb`, `merge` (joins semanticLayer nodes), `python`, `external` (DuckDB over uploaded or connected tables).
- **Reuse a node.** Call `query` again with `"sessionId":"<sessionId>"` and only the new node `{"sourceType":"duckdb","nodeId":"total","title":"Total","description":"Sum of numbers","sql":"SELECT sum(value) AS total FROM numbers","references":["numbers"],"limit":10}`. It returns `total` = 820 without resubmitting `numbers`.
- **Read rows.** `tools/call` `get_query_result` with `{"queryUuid":"<nodes[].queryUuid>"}`. Returns the node's rows.
- **Tool error.** A bad call returns HTTP 200 with `result.isError: true` and the reason in `result.content[0].text`; protocol errors use JSON-RPC `error`.
- **Second side.** `guest: runuser -u postgres -- psql -d postgres -XAt -c "select tool_name, status, error_message, duration_ms, client_name from mcp_tool_call where project_uuid='$P' order by created_at desc limit 5"`. One row per call, `tools/list` included, `direction` = `inbound`. `client_name` stays null unless an `initialize` with the same User-Agent came first.

## Gotchas

- An `Accept` header without both `application/json` and `text/event-stream` gets 406 `Not Acceptable`.
- The transport is stateless: each POST stands alone, so `tools/call` works without `initialize`.
- `query` waits up to 50 s, then answers `status: "running"` with a `queryUuid`; poll `get_query_result` with it.
- A `query` call returns at most 5 unread nodes; more fail with a message asking to combine them.
- Tool descriptions cached by an MCP client or proxy can predate the deploy, and the committed `mcp-tools-1.0.json` snapshot omits runtime inputs such as `query`'s `sessionId`. Read the live `tools/list` before claiming a schema or description change.
- MCP project access is set with `PATCH $ENV_URL/api/v1/aiAgents/admin/settings` and `{"mcpProjectAccess":{"mode":"selected","projectUuids":["<uuid>"]}}` (an unknown uuid is 400 `Invalid MCP project selection`); restore `{"mode":"all"}`. A project left out gets HTTP 403 `{"error":"MCP access to this project is disabled for your organization"}` on its pinned endpoint, and on the org-wide endpoint HTTP 200 with `result.isError: true` and `structuredContent.refusal.reason: "mcp_project_not_allowed"`.
- A `Bearer ldpat_...` header works too; the server rewrites it to `ApiKey`.
