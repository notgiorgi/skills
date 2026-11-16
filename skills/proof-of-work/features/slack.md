# Slack agent

A Slack user mentions the Lightdash bot in a channel mapped to an AI agent. The agent answers in a thread: a status line, the answer text, then tables and charts as native Slack blocks or PNG image cards with `Explore in Lightdash` buttons. Replies in the thread continue the conversation, and the same thread opens in the web app.

## Sub-features

- `slack-mention` starts an agent thread from an @-mention.
- `slack-answer` posts the answer text in the Slack thread.
- `slack-table` posts results as a native `data_table`.
- `slack-chart` posts charts as native `data_visualization` (flag `ai-agent-slack-native-charts`) or PNG cards.
- `slack-follow-up` continues the thread from a Slack reply.
- `slack-harness` renders or posts a chart from rows without the agent (dev only).

## How to get to it (user POV)

- In `<test-channel>`, send `@<bot> <question>`; follow up by replying in the bot's thread.
- The thread link in the answer opens `$ENV_URL/projects/$P/ai-agents/$AGENT/threads/$THREAD` in the web app.

## Driving it

Preconditions:

- The placeholders in angle brackets resolve from `~/.config/proof-of-work/local.md`, a private file on this machine.
- Slack reaches only a local dev server. A Rainbow env cannot receive Slack events.
- The local server runs the claimed revision with `SITE_URL=https://<tunnel-host>` and the Slack app variables (`SLACK_CLIENT_ID`, `SLACK_CLIENT_SECRET`, `SLACK_SIGNING_SECRET`, `SLACK_STATE_SECRET`) copied from `<slack-env-file>` into the instance's gitignored `.env.development.local`. No `SLACK_APP_TOKEN`: events arrive over HTTP.
- Its database holds the Slack installation (`slack_auth_tokens`) and one agent mapped to `<test-channel>` (agent `integrations: [{"type":"slack","channelId":"<test-channel-id>"}]`). Copying the main dev database brings both, plus the linked Slack identity.
- `PSQL` is the command that reaches the instance's Postgres, e.g. `docker exec <db-container> psql -U postgres`.
- `$ENV_URL` is `https://<tunnel-host>`, `$PAT` the instance's PAT, `P=3675b69e-8324-4110-bdca-059031aa8da3`.

- **Expose the server.** Run `<tunnel-command> <frontend-port>` in the background. `curl -s https://<tunnel-host>/api/v1/health` returns 200, and `curl -s -o /dev/null -w '%{http_code}' -X POST https://<tunnel-host>/slack/events` returns 401 (signature check), so Slack events reach the app.
- **Check the bot.** `BOT=$($PSQL -Atc "select installation->'bot'->>'token' from slack_auth_tokens s join organizations o using (organization_id) where o.organization_uuid='172a2270-000f-42be-9c68-c4752c23ae51'")`, then `curl -s -H "Authorization: Bearer $BOT" https://slack.com/api/auth.test` returns `"ok": true`.
- **Ask in Slack.** Post `@<bot> <question>` in `<test-channel>` as the user, with the Slack MCP send-message tool or the Slack desktop app. The bot replies in a thread: a plan/status message, then the answer.
- **Read the reply.** `curl -s -H "Authorization: Bearer $BOT" "https://slack.com/api/conversations.replies?channel=<test-channel-id>&ts=<mention-ts>"`. `messages[].blocks[].type` shows the layout, e.g. `plan, rich_text` for the answer, then `data_table`, `data_visualization`, `actions` or `card` in the data reply.
- **Link to the agent thread.** `$PSQL -Atc "select ai_thread_uuid from ai_slack_thread where slack_channel_id='<test-channel-id>' and slack_thread_ts='<mention-ts>'"` gives `$THREAD`; read its tool calls as in `ai-agent-thread.md`.
- **Follow up.** Reply in the bot's thread with `@<bot> <next question>`. A new answer posts in the same Slack thread and adds a prompt to the same `$THREAD`.
- **Toggle native charts.** `$PSQL -Atc "update feature_flag_overrides set enabled=false where flag_id='ai-agent-slack-native-charts' and organization_uuid='172a2270-000f-42be-9c68-c4752c23ae51' and user_uuid is null returning enabled"`. The next answer posts bar and line charts as image cards, with no restart. Set it back to `true`.
- **Render a chart without Slack.** `curl -H "Authorization: ApiKey $PAT" -H 'Content-Type: application/json' -o chart.png "$ENV_URL/api/v1/projects/$P/aiAgents/visualize/slack-preview" -d '{"title":"Orders by status","columns":[{"reference":"status","type":"string"},{"reference":"orders","type":"number"}],"rows":[{"status":"placed","orders":12},{"status":"shipped","orders":9}],"vizConfig":{"type":"bar","x":"status","y":["orders"],"y2":null,"groupBy":null,"stack":null,"horizontal":null,"labels":null}}'`. Returns a PNG; this route also works on a Rainbow env.
- **Post a chart without the agent.** Send the same body plus `"channel":"<test-channel-id>","threadTs":"<existing-ts>","route":"auto"` to `$ENV_URL/api/v1/projects/$P/aiAgents/visualize/slack-send`. Returns `route`, `reason`, `ts`, `permalink`. Development mode only, and it ignores the native-charts flag.

## Gotchas

- One tunnel connector serves the host. If another instance's connector is running, Slack events go there; stop it or point it here before testing.
- Point the tunnel at the frontend port: Vite proxies `/api` and `/slack/events` to the API. `SITE_URL` must be the tunnel host, or Slack cannot fetch chart images.
- Re-running the dev bootstrap resets `SITE_URL` to localhost; set it back and restart the PM2 processes, which keep their start-time env.
- When several agents fit the channel (e.g. the org's multi-agent channel), the bot first posts an agent picker and waits. Map exactly one agent to `<test-channel>`.
- `aiRequireOAuth` on the installation makes the mentioning Slack user need a linked Lightdash identity.
- `slack-send` rejects `"threadTs": null` with 422 despite its docs; pass an existing thread ts.
- Post a notice in the channel before toggling org flags, and restore every flag, agent setting and tunnel target you changed.
