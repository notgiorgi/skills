# AI agent thread

A user picks an AI agent in a project, asks a data question in a thread, and watches the agent call tools (query, visualize, runSql) and answer with text plus chart or table artifacts. A SQL step can pause for the user's approval. Follow-up prompts continue the same thread.

## Sub-features

- `agent-pick` lists the project's agents, or creates one.
- `thread-start` starts a thread from a first prompt.
- `turn-wait` runs a turn to completion.
- `tool-calls` shows the turn's tool calls and results.
- `artifact` renders the chart or table the turn produced.
- `sql-approval` approves or rejects a paused SQL step.
- `follow-up` adds a turn to an existing thread.

## How to get to it (user POV)

- Top bar button `Ask AI`, or `$ENV_URL/projects/$P/ai-agents`, then an agent card.
- New thread page `$ENV_URL/projects/$P/ai-agents/$AGENT/threads`; an open thread lives at `.../threads/$THREAD`.
- API, as an integration would: `/api/v1/projects/$P/aiAgents/...`.

## Driving it

Preconditions:

- `P=3675b69e-8324-4110-bdca-059031aa8da3` (seed project `SEED_PROJECT`) and `H=(-H "Authorization: ApiKey $PAT" -H 'Content-Type: application/json')`.
- Copilot on for the org. `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/aiAgents/settings"` shows `"isCopilotEnabled": true`. When false, run `curl -X POST "${H[@]}" -d '{"enabled":true}' "$ENV_URL/api/v2/feature-flag/ai-copilot"` and `DELETE` the same URL at cleanup.
- A provider key reaches the server. Rainbow previews read `ANTHROPIC_API_KEY` from stored secrets; without one, turns fail.
- Composer `query`/`visualize` tools need the `compose-sql-runner` flag (on in previews) and the agent's `enableComposerQueries: true`.

- **Pick an agent.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/aiAgents"`. Newer seeds return `Jaffle Shop Agent` (all tools on, SQL auto-approval on). An empty list means create one.
- **Create an agent.** `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents" -d '{"projectUuid":"'$P'","name":"Proof analyst","description":"","instruction":"","imageUrl":null,"integrations":[],"tags":[],"groupAccess":[],"userAccess":[],"spaceAccess":[],"enableDataAccess":true,"enableSelfImprovement":false,"enableSqlMode":true,"enableSqlAutoApproval":true,"enableComposerQueries":true,"version":2}'`. `results.uuid` is `$AGENT`.
- **Start a thread (UI).** Open the new thread page, type into the textbox with placeholder `Ask <agent name> anything about your data...`, click button `Send message`. The URL gains `/threads/<uuid>` and the prompt bubble appears.
- **Start a thread (API).** `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads" -d '{"prompt":"Show revenue by order status as a bar chart"}'`. `results.uuid` is `$THREAD`; the thread holds a `pending` assistant message and nothing runs yet.
- **Run the turn (API).** `curl -X POST --max-time 600 "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/generate"`. It returns only when the turn ends, with `results.response` as the answer text.
- **Wait for the turn.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD"`. Done when the last `results.messages[]` with `role: "assistant"` has `status: "idle"` and a non-null `message`; `status: "error"` carries `errorMessage`. In the UI the answer shows `copy`, `upvote` and `downvote` buttons.
- **Read tool calls (API).** The same message carries `toolCalls[]` (`toolCallId`, `toolName`, `toolArgs`), `toolResults[]` and `artifacts[]` (`artifactUuid`, `versionUuid`, `title`).
- **Read tool calls (UI).** Expand the `How this chart was built ·N steps` row under the answer, or click `Debug information` on the answer.
- **Read tool calls (DB, second side).** `guest: runuser -u postgres -- psql -d postgres -XAt -c "select c.tool_name, c.tool_args, r.result, r.metadata from ai_agent_tool_call c join ai_prompt p using (ai_prompt_uuid) left join ai_agent_tool_result r using (ai_prompt_uuid, tool_call_id, tool_name) where p.ai_thread_uuid='$THREAD' order by c.created_at"`. Prompt text, answer and error are `ai_prompt.prompt`, `response`, `error_message`.
- **Open the artifact.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/artifacts/$ARTIFACT/versions/$VERSION"`. In the UI the chart renders under the answer, titled as in `artifacts[].title`.
- **Approve or reject SQL.** Set `"enableSqlAutoApproval": false` with `curl -X PATCH "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT" -d '{"uuid":"'$AGENT'","enableSqlAutoApproval":false}'`, then prompt for raw SQL. The answer shows buttons `Approve`, `Approve & don't ask again this thread` and `Reject`. API: `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/tool-calls/$TOOL_CALL_ID/sql-approval" -d '{"decision":"approved"}'` (or `"rejected"`), where `$TOOL_CALL_ID` is the `runSql` or `query` call without a result.
- **Follow up.** `curl -X POST "${H[@]}" "$ENV_URL/api/v1/projects/$P/aiAgents/$AGENT/threads/$THREAD/messages" -d '{"prompt":"Now as a line chart"}'`, then `/generate` again. In the UI type into the same textbox. A second assistant message appears.

## Gotchas

- `/generate` blocks for the whole turn, often over 15 s. Run it with a long client timeout, or in the browser as a background `fetch` assigned to `window`, then poll the thread. A browser tool's evaluate call times out first.
- `set_env AI_COPILOT_ENABLED` is refused on Rainbow because it is a stored secret. Toggle the `ai-copilot` org flag instead; it reads `false` on fresh previews.
- With copilot off, thread calls return 403 `AI copilot is not enabled for this organization`.
- A thread created with `$PAT` records `createdFrom: "api"`; a browser session records `"web_app"`. Match the origin the claim is about.
- A paused SQL approval holds `/generate` open until decided; decide from a second request.
- Restore what you changed: the `ai-copilot` override, agent settings, agents you created.
- The SQL approval steps come from source and have not been driven end to end yet.
