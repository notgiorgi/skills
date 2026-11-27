# Composer charts

A user saves a multi-step AI answer (a pipeline of `semanticLayer`, `sql`, `duckdb`, `python` and `merge` nodes) as a chart tile on a dashboard. Viewers see it drawn like any other tile: it runs the stored pipeline, and dashboard filters and parameters reach its nodes. Restoring a dashboard version brings back each chart's pipeline as of that version, and the chart round-trips as a `.composer.yml` file through content as code. With the `composer-charts` flag off, and in embeds, the tile reads "This chart is not available here".

## Sub-features

- `cc-create` creates a composer chart owned by a dashboard (API, or `Save` on an AI composer answer).
- `cc-tile` adds it as a `composer_chart` tile on view, minimal and edit pages.
- `cc-run` runs the stored pipeline for a tile, with dashboard filters and parameters.
- `cc-export` downloads the tile's data (`Download data` in `Tile actions`) or its picture (`Export image`: PNG or SVG, opaque or transparent; not for table, big number, custom or map charts).
- `cc-lineage` shows the pipeline's nodes (`View lineage` in `Tile actions`).
- `cc-ask-ai` opens Ask AI with the tile pinned (`Ask AI Agent` on the tile header; hidden on minimal and embed pages).
- `cc-agent` lets an AI agent or MCP client read, run, edit and create composer charts; new warehouse SQL in an edit or create waits for SQL approval.
- `cc-promote` promotes a dashboard with fresh copies of its composer charts.
- `cc-rollback` restores a dashboard version and with it each chart's pipeline.
- `cc-duplicate` copies a dashboard with fresh copies of its composer charts; deleting the dashboard deletes them.
- `cc-code` reads and writes `/code/composerCharts`; a changed pipeline adds a chart version.

## How to get to it (user POV)

- AI thread: on a composer answer, `Quick actions` > `Save` opens `Save chart`: `Chart name`, `Next`, pick `Space` and `Dashboard`, `Save`. Afterwards the menu offers `View on dashboard`.
- Dashboard `/projects/$P/dashboards/$D/view`: the tile body is `[data-testid="composer-chart-visualization"]`; hovering it shows `Ask AI Agent` and `Tile actions` (`Copy link to tile`, `View lineage`, `Download data`, `Export image`, `Edit tile content`).
- `Dashboard actions` > `Version history` (`/projects/$P/dashboards/$D/history`): a row's dots menu > `Restore this version`, then `Restore`.

## Driving it

Preconditions:

- `P=3675b69e-8324-4110-bdca-059031aa8da3`, `H=(-H "Authorization: ApiKey $PAT" -H 'Content-Type: application/json')`, and a proof-owned dashboard `$D` (see `dashboards-and-charts.md`). Save as admin: the editor persona gets 403 saving a `sql` node.
- `composer-charts` reads `true` in `GET /api/v2/feature-flag` (the preview default).

- **Create.** `curl "${H[@]}" -X POST "$ENV_URL/api/v2/projects/$P/composer-charts" -d '{"dashboardUuid":"'$D'","name":"Proof composer","description":null,"pipeline":{"schemaVersion":1,"terminalNodeId":"result","nodes":[{"sourceType":"sql","nodeId":"result","title":"Orders","sql":"select status, count(*)::integer as n from jaffle.orders group by 1"}]},"chart":{"schemaVersion":1,"columns":[{"reference":"status","fieldType":"dimension"},{"reference":"n","fieldType":"metric"}],"chartConfig":{"type":"table","config":{}},"pivotConfig":null,"tableConfig":{"columnOrder":["status","n"]}}}'` returns `results.uuid` (`$C`), `slug` and `versionUuid`. No tile is added.
- **Tile.** `PATCH /api/v1/dashboards/$D` with `{"tiles":[{"type":"composer_chart","x":0,"y":0,"w":12,"h":9,"tabUuid":null,"properties":{"title":"Proof composer","composerChartUuid":"'$C'","chartName":null}}],"tabs":[],"filters":{"dimensions":[],"metrics":[],"tableCalculations":[]}}`; the tile uuid `$T` is in `results.tiles`.
- **Run.** `POST /api/v2/projects/$P/composer-charts/$C/run` with `{"dashboardUuid":"'$D'","tileUuid":"'$T'","dashboardFilters":{"dimensions":[],"metrics":[],"tableCalculations":[]},"parameters":{},"excludedParameterKeys":[],"invalidateCache":true}` returns `results.queries[]` (`nodeId`, `queryUuid`) and `chartStageQueryUuid`, which the tile draws instead of the terminal node when the chart groups series. Poll `GET /api/v2/projects/$P/query/$Q?page=1&pageSize=500` until `status` is `ready`.
- **Read.** `GET /api/v2/projects/$P/composer-charts/$C` returns the current `versionUuid`, `pipeline` and `chart`.
- **New version.** Take `results.composerCharts[0]` from `GET /api/v1/projects/$P/code/composerCharts?ids=$SLUG`, change `pipeline`, and POST the whole document to `/api/v1/projects/$P/code/composerCharts/$SLUG`: `results.action` is `update` and the chart gets a new `versionUuid`.
- **Rollback.** Save the dashboard again (GET it, PATCH back its `tiles`, `tabs`, `filters`) so a dashboard version follows the chart change. Pick an earlier `versionUuid` from `GET /api/v1/dashboards/$D/history` (`results.history[]`, newest first) and `POST /api/v1/dashboards/$D/rollback/$V` with `{}`. The chart now shows the pipeline current when that version was saved, under a new `versionUuid`.
- **Agent.** Ask the agent about the chart by name, e.g. `What does the Proof composer chart on the Proof dashboard show?`. Its tool calls include `readContent` with `type: "composer_chart"` and `runContentQuery` on a `dashboardChart` source.
- **Promote.** As `Promote` in `dashboards-and-charts.md`: `promoteDiff` lists the chart under `composerCharts` (`create`), and the upstream dashboard's `composer_chart` tile points at a new chart uuid.
- **DB.** `composer_charts` (owner `dashboard_uuid`), `composer_chart_versions` (`pipeline`, `chart`), `dashboard_tile_composer_charts` (tile to chart per dashboard version); a saved AI answer sets `ai_artifact_versions.saved_composer_chart_uuid`.

## Gotchas

- Add the tile straight after creating: the next dashboard save deletes a chart no dashboard version shows.
- Rollback restores the chart version current when the target dashboard version was saved, so a chart change needs a dashboard save after it to be restorable. Rollback re-runs save checks: an editor restoring a `sql` node or SQL custom field gets 403 and nothing is written.
- Payloads are strict: unknown keys are refused, `nodeId` matches `^[a-zA-Z_][a-zA-Z0-9_]{0,62}$`, the terminal node must read every node, and `columns[].reference` takes the node's output column names (no dots). A mismatch is 400.
- Body validation errors are 422: the as-code `dashboardSlug` is a required string, not `null`. Classic SQL charts (`/sqlRunner/saved`) take a different shape with `config.metadata.version`; keep the two apart.
- Run is bound to its tile: a `tileUuid` not showing `$C` on `$D` returns 403 `This composer chart is not on that dashboard tile`.
- A saved tile runs under composer authority, so its SQL and Python nodes run with `compose-sql-runner` off. Python nodes still need a configured Python sandbox. Check `GET /api/v2/projects/$P/query-sources` for the sources available to the caller.
- Embeds always render the not-available tile.
