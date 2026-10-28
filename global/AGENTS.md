- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
- In conversation with the user only, refer to tickets and PRs with descriptive Markdown links that say what changes. Shorten labels when context is established; include the affected feature in fresh mentions: `[PR adding chart images](url)` vs. `[PR adding chart images to Slack](url)`. Use natural wording, not exact titles or bare identifiers. This rule does not apply to authored artifacts such as PR descriptions, commit messages, or documentation.
- Keep code comments minimal: 1-2 lines at most, only when the code is not self-explanatory. No long explanatory blocks, no ticket references (PROD-XXXX, #issue) in comments.
- Local traces: query Maple with `maple traces --local --service <OTEL_SERVICE_NAME>`, then `maple trace --local <trace-id>`; `OTEL_EXPORTER_OTLP_ENDPOINT` selects the collector, while unique `OTEL_SERVICE_NAME` and optional `OTEL_RESOURCE_ATTRIBUTES=deployment.environment.name=<scope>` define `--service`/`--env` scope.

## Product engineering approach

- I love to build. I focus on building complex things as simple as possible. I love to find ways to reduce complexity when solving problems.
- I ship incrementally, we stay in control by shipping incremental changes that we can try, observe but many times a day
- Typesafety is useful, take advantage of it.
- Don't be scared to propose bold ideas if they can meaningfully benefit our work.
- Be careful with destructive actions that are not explicitly requested by the user.
- Tests are good! Endless smoke tests, "regression tests" for feature deletions, etc, much less good. Tests should be focused, not slop.
- Don't run the full test suite locally; run only tests relevant to the change. CI handles the expensive full run.

## MCPs via executor

These MCPs are exposed through the `executor` MCP (`mcp__executor__*` tools) — not as separate MCP servers. Use executor's execute/skills tools to reach them.

- Linear, Pylon, Sentry.
- `lightdash_cloud_feature_flags`: create, enable, disable Lightdash feature flags across all customers; also reads GCP traces, logs, alerts.
- `lightdash_mcp`: Lightdash MCP on the internal production analytics instance.
- `rainbowmachine_mcp`: preview environments for `lightdash/lightdash` PRs; create, exec into, fork, tail logs, kill.
- `codex_computer_use`: control Mac apps on the real desktop. Default to this for computer use.

## Browser automation

**Browser automation** means the T3 Code preview browser (`preview_*` tools) when the session runs in T3 Code, otherwise `agent-browser`. In T3 Code, reach for `agent-browser` only for a feature the preview browser lacks, such as pointer-visible video recording.

## PRs

For PR descriptions use the `visual-pr` skill.
