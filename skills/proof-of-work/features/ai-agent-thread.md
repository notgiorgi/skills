# AI agent thread

A user picks an AI agent in a project, asks a data question in a thread, and watches the agent call tools (query, visualize, runSql) and answer with text plus chart or table artifacts. A SQL step can pause for the user's approval. Follow-up prompts continue the same thread.

## Sub-features

- `agent-pick` lists the project's agents, or creates one.
- `thread-start` starts a thread from a first prompt.
- `thread-metadata` attaches caller metadata to an API-created thread and surfaces it in admin thread review.
- `turn-wait` runs a turn to completion.
- `tool-calls` shows the turn's tool calls and results.
- `artifact` renders the chart or table the turn produced.
- `sql-approval` approves or rejects a paused SQL step.
- `follow-up` adds a turn to an existing thread.
- `stop-steer` stops a running turn or sends it guidance (`Stop agent`, `Send guidance`; `POST .../messages/$MSG/interrupt`, `.../steers`).
- `share` shares a thread (`Share thread`; `POST .../threads/$THREAD/shares` returns `results.shareUrl`, `$ENV_URL/share/<nanoid>`). Opening it as a project user copies the shared turns into a new thread of theirs.
- `save-chart` saves an answer's chart to a dashboard from the artifact panel (`Save chart`).
- `tile-ask-ai` opens Ask AI from a dashboard tile (`Ask AI Agent` on the tile header, composer tiles included) with that tile and dashboard pinned as context.

## How to get to it (user POV)

- Top bar button `Ask AI`, or `$ENV_URL/projects/$P/ai-agents`, which redirects to the user's default agent, else the first one `GET .../aiAgents` lists, at `.../ai-agents/$AGENT/threads`. Switch or create agents from the header's agent selector (the agent's name; it lists `Create new agent`).
- New thread page `$ENV_URL/projects/$P/ai-agents/$AGENT/threads`; an open thread lives at `.../threads/$THREAD`.
- Org admin review opens under Settings → Ask AI → Threads (`/generalSettings/ai/threads?projects=$P&agents=$AGENT`).
- API, as an integration would: `/api/v1/projects/$P/aiAgents/...`.

## Driving it

Preconditions:

- `P=3675b69e-8324-4110-bdca-059031aa8da3` (seed project `SEED_PROJECT`) and `H=(-H "Authorization: ApiKey $PAT" -H 'Content-Type: application/json')`.
- Copilot reachable for the org. `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/aiAgents/settings"` shows `"isCopilotEnabled": true` or `"isTrial": true`. A fresh preview's org is in the AI trial, so threads run with the `ai-copilot` flag off. When both are false, run `curl -X POST "${H[@]}" -d '{"enabled":true}' "$ENV_URL/api/v2/feature-flag/ai-copilot"` and `DELETE` the same URL at cleanup.
- A provider key reaches the server. Rainbow previews read `ANTHROPIC_API_KEY` from stored secrets; without one, turns fail. For an answer that is identical on both sides of a comparison, opt the env into the emulated model instead (`../references/lightdash.md`, Emulated model).
- Composer `query`/`visualize` tools need the `compose-sql-runner` flag (on in previews) and the agent's `enableDataAccess: true` and `enableComposerQueries: true`.

- **Pick an agent.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/aiAgents"`. Newer seeds return `Jaffle Shop Agent` (all tools on, SQL auto-approval on). An empty list means create one.
- **Create an agent.** `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents" -d '{"projectUuid":"'$P'","name":"Proof analyst","description":"","instruction":"","imageUrl":null,"integrations":[],"tags":[],"groupAccess":[],"userAccess":[],"spaceAccess":[],"enableDataAccess":true,"enableSelfImprovement":false,"enableSqlMode":true,"enableSqlAutoApproval":true,"enableComposerQueries":true,"enableContentTools":true,"version":2}'`. `results.uuid` is `$AGENT`.
- **Start a thread (UI).** Open the new thread page, type into the textbox (`[role=textbox]`, a contenteditable div) with placeholder `Ask <agent name> anything about your data...`, click button `Send message`. The URL gains `/threads/<uuid>` and the prompt bubble appears.
- **Start a thread (API).** `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads" -d '{"prompt":"Show revenue by order status as a bar chart"}'`. `results.uuid` is `$THREAD`; the thread holds a `pending` assistant message and nothing runs yet.
- **Caller metadata.** Add `"metadata":{"environment":"staging"}` to the thread create body. Thread GET returns `results.metadata`. Filter the admin API with `GET /api/v1/aiAgents/admin/threads?metadataKey=environment&metadataValue=staging`. In the admin Threads table, open the row with a field count in the Metadata column to see the caller-supplied pairs.
- **Run the turn (API).** `curl -X POST --max-time 600 "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/generate"`. It returns only when the turn ends, with `results.response` as the answer text.
- **Wait for the turn.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD"`. Done when the last `results.messages[]` with `role: "assistant"` has `status: "idle"` and a non-null `message`; `status: "error"` may carry `errorMessage`; a message still `pending` after 5 minutes reads `error` with none. In the UI the answer shows `copy`, `upvote` and `downvote` buttons.
- **Read tool calls (API).** The same message carries `toolCalls[]` (`toolCallId`, `toolName`, `toolArgs`), `toolResults[]` and `artifacts[]` (`artifactUuid`, `versionUuid`, `title`).
- **Read tool calls (UI).** Expand the `<title> ·N steps` row above the answer. The title follows the turn's tools: `How this chart was built` after a successful query, `How this was calculated` after a successful `runSql`, `Research steps` for searches only, and `Steps taken` otherwise (`How this dashboard was built`, `How this content was created`). `Debug information` on the answer appears only when it has artifacts.
- **Read tool calls (DB, second side).** `guest: runuser -u postgres -- psql -d postgres -XAt -c "select c.tool_name, c.tool_args, r.result, r.metadata from ai_agent_tool_call c join ai_prompt p using (ai_prompt_uuid) left join ai_agent_tool_result r using (ai_prompt_uuid, tool_call_id, tool_name) where p.ai_thread_uuid='$THREAD' order by c.created_at"`. Prompt text, answer and error are `ai_prompt.prompt`, `response`, `error_message`.
- **Open the artifact.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/artifacts/$ARTIFACT/versions/$VERSION"`. In the UI a card titled as in `artifacts[].title` sits between the steps row and the answer text; the chart renders in a right-side panel under the same title.
- **Approve or reject SQL.** Set `"enableSqlAutoApproval": false` with `curl -X PATCH "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT" -d '{"uuid":"'$AGENT'","enableSqlAutoApproval":false}'`, then prompt for raw SQL, e.g. `Run this SQL and show me the result: select status, count(*) from jaffle.orders group by 1`. The step shows `awaiting approval` and buttons `Approve`, `Approve & don't ask again this thread` and `Reject`. API: run the turn with `/stream`, not `/generate`: `curl -N -X POST --max-time 600 "${H[@]}" -d '{}' "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/stream" > stream.txt &`. Within seconds the thread GET lists a `toolCalls[]` entry with no matching `toolResults[]`; that `toolCallId` is `$TOOL_CALL_ID`. Decide with `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/tool-calls/$TOOL_CALL_ID/sql-approval" -d '{"decision":"approved"}'` (or `"rejected"`), which returns `results.decision`. A rejection lands as the tool result `User rejected this SQL execution...`. Calls that pause: `runSql`, `query` and `runComposerQueries` carrying SQL, `runContentQuery`, `createContent`, `editContent`.
- **Follow up.** `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/messages" -d '{"prompt":"Now as a line chart"}'`, then `/generate` again. In the UI type into the same textbox. A second assistant message appears.
- **Deterministic turn (emulated model).** On an opted-in env, start the turn from the UI or run it with `/stream`; the answer is the seeded guide. To script a tool step, `PUT` rules such as `{"strict":false,"rules":[{"id":"load-tools","match":{"tool":"loadAgentTools","hasToolResult":false},"times":1,"reply":[{"type":"tool_call","name":"loadAgentTools","arguments":{}}]},{"id":"answer","match":{"hasToolResult":true},"reply":[{"type":"text","text":"The query returned 42."}]}]}`: the turn calls the tool, then settles on that text. `_ai/calls` shows both requests and the rule each matched.
- **Which model answered.** The thread API's `modelConfig` is null; read `guest: runuser -u postgres -- psql -d postgres -XAt -c "select function_id, provider, model from ai_usage_ledger where thread_uuid='$THREAD' order by created_at"`. `function_id` is `generateAgentResponse` for `/generate` turns.

## Gotchas

- `/generate` blocks for the whole turn, often over 15 s. Run it with a long client timeout, or in the browser as a background `fetch` assigned to `window`, then poll the thread. A browser tool's evaluate call times out first.
- agent-browser's 25 s default wait is shorter than a turn: set `AGENT_BROWSER_DEFAULT_TIMEOUT=60000` and drive one browser session at a time.
- Content tools (`findContent`, `readContent`, `runContentQuery`, `editContent`, `createContent`) take `type: "composer_chart"`; see `composer-charts.md`.
- With copilot off and no trial, thread calls return 403 `Copilot is not enabled`.
- Thread deletion returns 403 `Thread deletion is disabled for this organization` (`ai-disable-thread-deletion` is on in previews). Clean up by deleting the proof-owned agent: `curl -X DELETE "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT"`.
- A thread created with `$PAT` records `createdFrom: "api"`; a browser session records `"web_app"`. Match the origin the claim is about.
- `/generate` cannot be approved: it stores tool calls only after the step finishes, so no pending call is visible while it waits. With auto-approval off it blocks 5 minutes, then answers that the SQL approval timed out. Drive approval through `/stream` or the UI and decide from a second request.
- The viewer persona sees no agents, and gets 403 on an admin-created one, so a role check stops at agent access before it reaches the claim. Grant access first: `curl -X PATCH "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT" -d '{"uuid":"'$AGENT'","userAccess":["<persona userUuid>"]}'`, the uuid from that persona's `GET /api/v1/user`.
- At a 390px viewport the Ask AI launcher is hidden on dashboards; this is existing behaviour, not a finding.
- With the emulated model, `/generate` is not streamed and settles on an echo of the prompt, not the seeded guide; use `/stream` or the UI.
- To test SQL approval with the emulated model, disable SQL auto-approval and script the Composer agent’s `query` tool in a streamed turn. Use arguments `{"title":null,"description":null,"terminalNodeId":null,"queries":[{"sourceType":"sql","nodeId":"sample","title":"Sample","description":"Returns one number","sql":"select 42 as answer","limit":10}]}`. Match `tool: "query"` and approve or reject the resulting tool call as above.
- `loadAgentTools` does not appear in the thread's `toolCalls[]`; read it from `_ai/calls`.
- Restore what you changed: the `ai-copilot` override, agent settings, agents you created, emulated-model rules.
