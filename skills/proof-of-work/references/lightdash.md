# Lightdash instance

How to get, check, drive and tear down the instance a proof runs on. Preview env mechanics (`create_env`, `exec`, `logs`, redeploy, egress) are in the Lightdash repo's `rainbow-env` skill, and flag semantics in its `docs/preview-feature-flags.md`. This file holds the literal forms those leave to lookup.

## Launch

Default to a **Rainbow env**, through `tools.rainbow.*` on the `executor` MCP. Run locally only when the user says so or the feature needs it; see Local instance.

- **Pinned**: `create_env({repo: "lightdash/lightdash", branch, name: "<proof-dir-name>-proof"})`, an env this proof owns, named exactly so in lowercase, so every round redeploys to the same URL. Use the pull request's `lightdash--pr-<N>` only when the user names it; it belongs to the PR's reviewers, and its CI drives it too.
- **Baseline**: `create_env({repo: "lightdash/lightdash", branch: "<baseline sha>", name: "<proof-dir-name>-base"})`. `branch` accepts a sha Rainbow has fetched; a just-merged sha answers `neither on origin nor a local ref`, so pass the branch name instead and check the served `sha` in Doctor.
- Create both envs before pinning the claim and pin it while they build. A fork of a recent warm image is ready in under a minute; a revision with no warm image builds from scratch, 5 to 35 minutes, and a failed build ends `task_status` with the failing stage.
- **Redeploy** after a push: `create_env` again with the same name; the URL stays.
- **One build per commit at a time.** A push that changes `rainbow.toml` `[runtime].build` rebuilds the base image (~10 min). Two builds of the same new commit at once (the PR preview and your `create_env`) collide in `wt-image-<sha>`: one fails with `file has vanished`, the other with `git ls-files ... exit status 128`, and the PR's `rainbow-machine/preview` and `Deploy Preview` checks go red. Wait for the PR's build (`pr_status`) before `create_env` on that commit, and re-run once after a collision.
- **Waiting**: `create_env`, and an `exec` running past ~25 s, answer `{status: "working", task_id}`. Then run [`../scripts/wait-healthy`](../scripts/wait-healthy) `<env-url> [timeout-seconds]` (the URL is `https://<name>.lightdash.rainbowmachine.dev`), or call `task_status({task_id, wait_sec: 25})` until it returns the call's result. `url` answers `no environment` until `create_env` completes; the URL above works for curl and the browser meanwhile. A PR preview waits with one `pr_status({repo: "lightdash/lightdash", pr, wait_sec})`; `build_log({repo: "lightdash/lightdash", pr})` explains a failure.

## Doctor

Run before the first drive and after anything surprising. With `ENV_URL` set to the env's base URL and `PAT=ldpat_deadbeefdeadbeefdeadbeefdeadbeef` (the public seed token):

- `list_envs`: the env is `running` or `hibernated` (the first request wakes it in seconds) and its `sha` equals the revision under proof. This is the freshness check. One exception: a 422 naming a request field the branch added means stale generated API routes; run `guest: cd /usr/app && pnpm -F backend generate-api && systemctl restart rainbow-dev.service`, then Doctor again.
- `curl -fsS "$ENV_URL/api/v1/health"` returns `results.healthy: true` and `mode: "pr"`.
- `curl -fsS -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/user"` returns `demo@lightdash.com`.

A `sha` behind the pushed head means the preview is still building: wait as above, then run Doctor again.

## Drive

Feature recipes are in [`../features/`](../features/README.md). Shared facts:

**Seed.** Project `Jaffle shop`, uuid `3675b69e-8324-4110-bdca-059031aa8da3`, in org `Jaffle Shop`. Every persona's password is `demo_password!`.

| Persona | Email | Role |
| --- | --- | --- |
| admin | `demo@lightdash.com` | org admin; owns the seed PAT |
| editor | `demo2@lightdash.com` | org editor |
| viewer | `demo3@lightdash.com` | org viewer |
| outsider | `another@lightdash.com` | admin of a second org with no project |

- A project-scoped persona (a role narrower than viewer): `POST /api/v1/invite-links` with `{"email":"<synthetic>","role":"member"}`, `POST /api/v1/user` with its `inviteCode`, create a project role holding `view:Dashboard`, `view:SavedChart`, `view:Space`, `view:Project`, `view:JobStatus@self`, then `POST /api/v2/projects/$P/roles/assignments/user/<userUuid>` with `{"roleId":"<id>","sendEmail":false}`. Org-level scopes such as `view:Organization` are refused at project level. The new user first sees a `What's your role` modal.
- Other projects: the seed adds four agent-restriction projects to the org, `Agents: no restrictions`, `Agents: no raw SQL`, `Agents: find and query only` and `Agents: nothing allowed` (uuids `5a1f7c1e-0b7d-4d0e-9c11-a6e1d000000<1-4>`). For a project the run owns: `POST /api/v1/projects/$P/createPreview` with `{"name":"Proof copy","copyContent":false}`; remove it with `DELETE /api/v1/org/projects/<uuid>`.
- A PAT for another persona: sign in with a cookie jar as that persona, then `POST /api/v1/user/me/personal-access-tokens` with `{"description":"proof","expiresAt":null,"autoGenerated":false}`.
- Warehouse: the guest's own Postgres, schema `jaffle` (`jaffle.orders`, `jaffle.payments`, `jaffle.customers`).

**Sign in.**

- Browser: open `$ENV_URL/login`, then evaluate `fetch('/api/v1/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'demo@lightdash.com',password:'demo_password!'})}).then(r=>r.status)` and reload. The same call with another email switches persona. To prove the sign-in form itself, fill `input[name="email"]`, click `Continue`, fill `input[name="password"]`, click `Sign in`.
- API from outside: the PAT header, or a session with `curl -c jar -H 'Content-Type: application/json' -d '{"email":"demo3@lightdash.com","password":"demo_password!"}' "$ENV_URL/api/v1/login"` then `curl -b jar ...`.
- API inside the guest: the PAT against `http://localhost:8080`. The session cookie is secure-only, so it works from outside alone.
- After `set_env` or a redeploy, run `wait-healthy` and see `fetch('/api/v1/user')` return 200 in the page before driving; a sign-in during the restart lands on `We are currently unable to reach the server`. In the form, wait for `input[name="password"]` after `Continue`.

**Feature flags.** `GET $ENV_URL/api/v2/feature-flag` lists resolved values, and is the source of truth for preview defaults; `POST .../feature-flag/<id>` with `{"enabled": true}` sets an org override; `DELETE` on the same URL drops it. Only an org admin can call these. Set an override only when the claim is about a flag's state, and drop it at cleanup.

**Settings.** `set_env({env, set})` changes a server variable and restarts in ~20 s, but refuses any value equal to a stored secret's value, and `"true"` is one: a boolean setting cannot be turned on this way. Read `get_env` before and after. Turn a boolean on with a systemd drop-in instead: `guest: install -d /etc/systemd/system/rainbow-dev.service.d && printf '[Service]\nEnvironment=<NAME>=true\n' > /etc/systemd/system/rainbow-dev.service.d/proof.conf && systemctl daemon-reload && systemctl restart rainbow-dev.service`, then `wait-healthy`; delete the file and restart the same way at cleanup.

**Emulated model.** Use it when main and the change must receive the identical model answer. Every env built from main at or after `ed43a6cce5` runs the `emulate-ai` service ([emulate](https://github.com/vercel-labs/emulate) 0.14.0, `ai`) on guest `localhost:4014`, idle until the env opts in:

- Opt in with `set_env({env, set: {AI_DEFAULT_PROVIDER: "openai", OPENAI_BASE_URL: "http://localhost:4014/v1"}})`, or `set` on `create_env`; `OPENAI_API_KEY` comes from the stored secret. Opt out with `unset` on both. Only the OpenAI provider works: emulate's Anthropic route rejects the `anthropic-version` header the SDK always sends.
- The seed, `scripts/rainbow/emulate-ai.yaml`, answers every streamed agent turn (the UI, `/stream`) with the same ~1,180-word Markdown guide (49 blocks, 29 links, a SQL block, a table), one word per chunk 15 ms apart. Non-streamed calls (`/generate`, title generation) get emulate's default: an echo of the latest user text.
- `guest: curl -s localhost:4014/_ai/calls` lists each model request: `format`, `stream`, `matched` rule, declared `tools`, `messages`. `DELETE` the same URL clears it.
- Script other answers with `guest: curl -X PUT localhost:4014/_ai/rules -H 'content-type: application/json' -d '{"strict":false,"rules":[...]}'`. It replaces every rule and the timing, and `POST localhost:4014/_ai/reset` restores the seed: reset at cleanup. Match on `stream`, `format`, `tool` and `hasToolResult`, not `textContains`: it reads only the latest user message, and the app can append a skill or catalog context as a later one. A `tool_call` reply must name a tool in that request's `tools`.
- A baseline env needs the same service and opt-in. An env from a sha before `ed43a6cce5` lacks both files; base it on a branch carrying main's `rainbow.toml` and seed.

**Query storage.** When queries or app uploads fail with `KeyInactive` or `Authentication required`, the preview's results bucket credentials are stale. In the guest create a MinIO user and bucket (`mc admin user add`, `mc admin policy attach readwrite`), then `set_env` `RESULTS_S3_ENDPOINT=http://127.0.0.1:9000`, `RESULTS_S3_BUCKET`, `RESULTS_S3_ACCESS_KEY`, `RESULTS_S3_SECRET_KEY`, `RESULTS_S3_AUTH_MODE=default`, leaving out the region (`us-east-1` and `minioadmin` match stored secrets), and run `wait-healthy`. App and custom chart type installs use the managed `S3_*` keys, which `set_env` refuses: those scenarios are UNREACHABLE on the first failure.

**Database.** `guest: runuser -u postgres -- psql -d postgres -XAt -c "select 1"`. `exec` runs as root with no `PG*` variables, the socket admits only the OS user `postgres`, and the app database is named `postgres`.

**Files.** Out of the guest: write under `/usr/app/packages/frontend/build/<dir>/`, fetch `$ENV_URL/<dir>/<file>`, delete the dir. Into the guest: base64 the file into an `exec` command. `exec` output is cut at 64 KB. The guest has `grep`, `python3` and `node`, and no `rg` or `jq`.

**Direct invocation.** Backend code runs in the guest with its config: `cd /usr/app/packages/backend && env NODE_ENV=test SITE_URL=http://localhost:8080 LIGHTDASH_SECRET=x S3_BUCKET=proof S3_REGION=us-east-1 S3_ENDPOINT=http://localhost:9000 pnpm exec tsx -e '<code>'`.

## Evidence

- **Captures**: Use the T3 preview browser when running in T3 Code. For pointer-visible video, drive the whole scenario with `agent-browser --session <slug>`. Outside T3, use `agent-browser` from the first step. A 1440x1000 viewport for desktop proof, a claim-specific one for responsive behaviour. Text snapshot by default, screenshot for anything visual, `agent-browser record start <file> --cursor` for video. Capture after the page settles: a tile still loading is not evidence. Hover-only controls need a real pointer move before the click. Run `agent-browser --help` before first use.
- **Second side**: database rows, API reads, the app log (`logs` with service `dev`, or `guest: grep ... /var/log/rainbow/dev.log`; journalctl holds only service starts), and mail the app sent (`guest: curl -s localhost:8025/api/v1/messages`).
- **Downloaded files**: render a PDF with `sips -s format png <file> --out <png>`; open an SVG in the browser.
- **Traces**: previews export none; use the second-side sources above.
- **Where rows live**: `saved_queries` and `saved_queries_versions`; `dashboards`, `dashboard_versions`, `dashboard_tiles`; `feature_flag_overrides`; `query_history`; `ai_thread`, `ai_prompt`, `ai_agent_tool_call`, `ai_agent_tool_result`; `mcp_tool_call`.

## Cleanup

- Keep the pinned env running for the reviewer unless the user said to remove it; then Try it gives the `create_env` call and `r<N>/setup` command instead of a URL. A `lightdash--pr-<N>` env belongs to its pull request.
- Touch only envs this run created. `kill_env({env: "<name>"})` every one of them except the pinned env, the baseline always, then read `list_envs` and paste the names that remain into the proof's Cleanup section.
- Restore what the run changed on the pinned env: flag overrides, agent settings, minted PATs, and emulated-model rules (`POST localhost:4014/_ai/reset`).
- Fixtures are code: `r<N>/setup.*` creates the Try it records against an env URL and `r<N>/cleanup.*` removes them. Leave the Try it records up unless the brief says to remove them; Try it then says to run setup.
- Evidence files stay.

## Local checks

- In Codex, `rm -f` and `rm -rf` stop for approval; plain `rm` and `rm -r` do not.
- Vitest on a `*.snapshot.test.ts` re-sorts its committed `.snap`; restore it with `git checkout` before finishing.
- Tickets: read Linear with the executor's `tools.linear.get_issue` when the native connector asks for re-auth.

## Unreachable on previews

Each of these makes a scenario UNREACHABLE with the prerequisite shown:

- **Other warehouses**: only the seeded Postgres exists. Needs user-supplied credentials, for example a BigQuery service-account key, to create a project.
- **Image and PDF deliveries, unfurls**: no headless browser service. CSV and XLSX deliveries work and land in the guest's mail catcher.
- **Slack**: a preview cannot receive Slack events. Needs a local instance; see [`../features/slack.md`](../features/slack.md).
- **Git write-back and GitHub App access**: the project has no git repo (`hasGithub: false`), and previews set no `GITHUB_APP_ID` or `GITHUB_PRIVATE_KEY`, so the agent's GitHub MCP preset reads `available: false`. Needs a real dbt git connection, or a GitHub App key and installation.
- **Outbound calls**: only `[[egress.allow]]` hosts connect; `egress` lists refused hosts. Needs the host added to `rainbow.toml` on the branch.
- **Browser notifications**: the automation browser denies the permission. Needs a context that grants it.

## Local instance

For Slack, or when the user asks for local. The `lightdash-setup-worktree` skill creates and tears down an isolated instance with its own ports and database; a baseline is a second such instance at the baseline revision.

- Identify the instance that belongs to the checkout from `PORT` and `FE_PORT`, and confirm the browser, API and database point at it.
- Fresh means each server process started after the last source change on its revision, and generated artifacts such as the OpenAPI spec match the source.
- Traces: the Lightdash repo's `debug-local` skill.
- Doctor there is the freshness check above plus the health and user calls against `http://localhost:$FE_PORT`.
