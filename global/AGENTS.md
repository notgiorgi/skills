- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
- Never co-sign as an agent: no `Co-Authored-By: Claude/Codex ...` or "Generated with ..." lines in commit messages, and no "Generated with" footers or agent session links in PR titles/bodies.
- Keep code comments minimal: 1-2 lines at most, only when the code is not self-explanatory. No long explanatory blocks, no ticket references (PROD-XXXX, #issue) in comments.
- Local traces: query Maple with `maple traces --local --service <OTEL_SERVICE_NAME>`, then `maple trace --local <trace-id>`; `OTEL_EXPORTER_OTLP_ENDPOINT` selects the collector, while unique `OTEL_SERVICE_NAME` and optional `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=<scope>` define `--service`/`--env` scope.

## Product engineering approach

- I love to build. I focus on building complex things as simple as possible. I love to find ways to reduce complexity when solving problems.
- I ship incrementally, we stay in control by shipping incremental changes that we can try, observe but many times a day
- Typesafety is useful, take advantage of it.
- Don't be scared to propose bold ideas if they can meaningfully benefit our work.
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good! Endless smoke tests, "regression tests" for feature deletions, etc, much less good. Tests should be focused, not slop.

## MCPs via executor

Linear, Pylon, and Sentry MCPs are exposed through the `executor` MCP (`mcp__executor__*` tools) — not as separate MCP servers. Use executor's execute/skills tools to reach them.

## Chrome

Use `agent-browser` for browser automation over chrome mcp.

## PRs

For PR descriptions use the `visual-pr` skill.
