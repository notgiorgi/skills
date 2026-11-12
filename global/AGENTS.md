- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
- In conversation with the user only, refer to tickets and PRs with descriptive Markdown links that say what changes. Shorten labels when context is established; include the affected feature in fresh mentions: `[PR adding chart images](url)` vs. `[PR adding chart images to Slack](url)`. Use natural wording, not exact titles or bare identifiers. This rule does not apply to authored artifacts such as PR descriptions, commit messages, or documentation.
- Keep code comments minimal: 1-2 lines at most, only when the code is not self-explanatory. No long explanatory blocks, no ticket references (PROD-XXXX, #issue) in comments.
- Local traces: query Maple with `maple traces --local --service <OTEL_SERVICE_NAME>`, then `maple trace --local <trace-id>`; `OTEL_EXPORTER_OTLP_ENDPOINT` selects the collector, while unique `OTEL_SERVICE_NAME` and optional `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=<scope>` define `--service`/`--env` scope.

## Product engineering approach

- I love to build. I focus on building complex things as simple as possible. I love to find ways to reduce complexity when solving problems.
- I ship incrementally, we stay in control by shipping incremental changes that we can try, observe but many times a day
- Typesafety is useful, take advantage of it.
- Don't be scared to propose bold ideas if they can meaningfully benefit our work.
- Via negativa: the principle that we know what is wrong with more clarity than what is right, and that knowledge grows by subtraction. Also, it is easier to know that something is wrong than to find the fix. Actions that remove are more robust than those that add because addition may have unseen, complicated feedback loops. (Nassim Nicholas Taleb, *Skin in the Game*)
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good! Endless smoke tests, "regression tests" for feature deletions, etc, much less good. Tests should be focused, not slop.
- Don't run the full test suite locally; run only tests relevant to the change. CI handles the expensive full run.

## MCPs via executor

These MCPs are apps behind the `executor` MCP (`mcp__executor__*`), not separate MCP servers.

Paths are `tools.<app>.<upstream tool>`, e.g. `tools.rainbow.create_env`. `search({namespace, query})` returns exact paths but ranks loosely; if you know the upstream tool name, `describe({paths})` it directly for the full signature. `call` returns `{ok, value}` per call, where `value` is the MCP result: check `value.isError`, then read `value.structuredContent`, falling back to `JSON.parse(value.content[0].text)` (Linear, Lightdash, Console return text only). `skills({app, name: "tools"})` reads a server's own instructions when it ships them; `skills({})` lists which do. A slow call that times out may still be running upstream: check state (e.g. Rainbow `list_envs`) before repeating it.

- `linear`, `pylon`, `sentry`, `fathom`, `mobbin`.
- `console`: create, enable, disable Lightdash feature flags across all customers; also reads GCP traces, logs, alerts.
- `lightdash`: Lightdash MCP on the internal production analytics instance.
- `rainbow`: preview environments for `lightdash/lightdash`; usage in the repo's `rainbow-env` skill.

Each app is a small `mcpRouter` wrapper; sources in `~/.executor/v2-apps/<app>`. Add one with `executor apps create` then `executor apps deploy`.

## Browser automation

**Browser automation** means the T3 Code preview browser (`preview_*` tools) when the session runs in T3 Code, otherwise `agent-browser`. In T3 Code, reach for `agent-browser` only for a feature the preview browser lacks, such as pointer-visible video recording.

To check UI on a Rainbow env: get its URL (rainbow `url` tool), open it with `preview_navigate`, and read it with `preview_snapshot` (text by default). Add `includeImage` only for visual checks such as spacing or colors.

## PRs

For PR descriptions use the `visual-pr` skill.
