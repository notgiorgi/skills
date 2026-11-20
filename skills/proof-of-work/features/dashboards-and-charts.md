# Dashboards and saved charts

A user opens a dashboard of chart, markdown and other tiles, narrows it with dashboard filters and parameters, switches to edit mode to add, move or remove tiles and saves; duplicates or deletes it from the actions menu; opens a saved chart on its own page; and sees only what their role and space access allow. The same dashboard renders chrome-free on the minimal page and, for an allowlisted dashboard, inside an embed.

## Sub-features

- `dash-open` opens a dashboard in view mode and runs every tile.
- `dash-edit` enters edit mode, adds a saved-chart tile, saves or cancels.
- `dash-filter` applies, changes and per-tile-targets a dashboard filter.
- `dash-param` sets a parameter value that reaches the tiles referencing it.
- `dash-duplicate` copies a dashboard under a new uuid and slug.
- `dash-delete` removes a dashboard (and the charts it owns).
- `chart-open` opens a saved chart page and runs its query.
- `role-view` shows the same content to an editor, a viewer or an outsider.
- `dash-minimal` renders the minimal page used by image and PDF capture.
- `dash-embed` renders an allowlisted dashboard from an embed JWT (a chart embeds at `/embed/$P/chart/$C`).
- `dash-history` lists a dashboard's or chart's versions and restores one.
- `dash-date-zoom` the filter bar's `Default zoom` regroups date axes on every tile.
- `dash-promote` copies a dashboard and its charts into the project's upstream project (`Dashboard actions` > `Promote dashboard`).
- `dash-toolbar` the edit toolbar's undo/redo, tidy, zoom, canvas background and filter visibility, and a selected tile's `Tile actions`.

## How to get to it (user POV)

- Sidebar `Browse` > `All dashboards` (nav anchor `[data-tour-nav="all-dashboards"]`), or `/projects/$P/dashboards`.
- Dashboard URL `/projects/$P/dashboards/$D/view`; edit mode `/edit`; a tab `/view/tabs/$TAB`. In-app navigation rewrites both ids to slugs (`/projects/jaffle-shop/dashboards/<slug>/edit`), so assert on the suffix.
- Version history `/projects/$P/dashboards/$D/history` and `/projects/$P/saved/$C/history`.
- `New` > `Dashboard` (`[data-tour-nav="new"]` then `[data-tour-nav="new-dashboard"]`).
- Saved chart `/projects/$P/saved/$C/view`; list `/projects/$P/saved`.
- Minimal `/minimal/projects/$P/dashboards/$D`; embed: the URL `get-embed-url` returns.

## Driving it

Preconditions:

- Signed in per `../references/lightdash.md`; `P=3675b69e-8324-4110-bdca-059031aa8da3`.
- `D` from `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/dashboards"`: pick `Jaffle dashboard` (slug `jaffle-dashboard`, two dashboard filters: `orders_is_completed` and `orders_order_date_year`).
- Mutations use a proof-owned dashboard: `curl -X POST -H "Authorization: ApiKey $PAT" -H 'Content-Type: application/json' -d '{"name":"Proof dashboard","tiles":[],"tabs":[]}' "$ENV_URL/api/v1/projects/$P/dashboards"` returns 201 and `results.uuid`.

- **Open.** Navigate to `/projects/$P/dashboards/$D/view`. Every tile leaves its loading state; snapshot shows the tile titles and the filter pills. API: `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/dashboards/$D"` returns `results.tiles`, `tabs`, `filters`, `parameters`.
- **Enter edit.** First visit opens a 6-step `Welcome to the new dashboard editor` tour over the toolbar: click `Skip tour`, or pre-dismiss it per persona with `POST /api/v1/user/onboarding` `{"tour":"dashboardEditTour"}` in that persona's session. Click button `Edit dashboard` (aria-label). URL ends `/edit`; the header shows `Save changes` (disabled until a change) and `Cancel`, and the floating toolbar `[aria-label="Dashboard editing tools"]` holds `Add tile`.
- **Add a tile.** Click `[data-tour-anchor="add-tile"]` (`Add tile`), menu item `Saved chart` (`[data-tour-anchor="add-saved-chart"]`), type a chart name into `[data-tour-anchor="chart-picker"]` (placeholder `Search...`), pick `[data-tour-anchor="chart-option"][data-tour-value="<chart name>"]`, click `Add` (`[data-tour-anchor="add-charts-submit"]`). A new tile appears; `Save changes` enables.
- **Save.** Click `Save changes`. URL returns to `/view`; `GET /api/v1/dashboards/$D` shows one more tile and `GET /api/v1/dashboards/$D/history` one more version.
- **Add a tile by API.** `PATCH /api/v1/dashboards/$D` with body `{"tiles":[...all current tiles..., {"type":"saved_chart","x":0,"y":0,"w":12,"h":9,"properties":{"savedChartUuid":"$C","title":"Proof tile"}}],"tabs":<current>,"filters":<current>}` returns 200. The body replaces the tile list.
- **Filter.** In edit mode click `Add filter`, search the field in `Search field...`, set a value, open tab `Tiles` (`Tabs & tiles` on a dashboard with several tabs) to uncheck tiles, click `Apply`, then `Save changes`. Proof: `GET /api/v1/dashboards/$D` shows the rule in `filters.dimensions[]` with `tileTargets`.
- **Filter reaches a tile.** `POST /api/v2/projects/$P/query/dashboard-chart` with `{"chartUuid":"$C","tileUuid":"$T","dashboardUuid":"$D","dashboardFilters":{"dimensions":[...],"metrics":[],"tableCalculations":[]},"dashboardSorts":[],"context":"dashboardView","invalidateCache":true}` returns `results.queryUuid`; poll `GET /api/v2/projects/$P/query/$Q?page=1&pageSize=500` until `status` is `ready`; rows reflect the filter.
- **Parameter.** Project parameters: `GET /api/v2/projects/$P/parameters`; a dashboard's own: `GET /api/v2/projects/$P/dashboards/$D/parameters`. No seed chart uses one: create a chart with dimension `orders_date_custom_param_test` and add it as a tile, which then shows the `date_custom_parameter` control; changing it sends `parameters: {"date_custom_parameter": ...}` on the `dashboard-chart` call. Saved values persist in the dashboard's `parameters`.
- **Date zoom.** In view mode click `Default zoom` and pick a menu item (`Day`, `Week`, `Month`, `Quarter`, `Year`; handles `[data-tour-anchor="zoom-option"][data-tour-value="Month"]`). Every `dashboard-chart` call then carries `dateZoom: {"granularity":"Month","xAxisFieldId":"<field>"}`. Saved defaults live in the dashboard's `config.dateZoomGranularities` and `defaultDateZoomGranularity`.
- **Promote.** Needs an upstream project: create a second project (`../references/lightdash.md`), then `PATCH /api/v1/projects/$P/metadata` with `{"upstreamProjectUuid":"<second uuid>"}`; without it `promoteDiff` returns 404 `This dashboard's project does not have an upstream project`. `GET /api/v1/dashboards/$D/promoteDiff` lists `spaces`, `dashboards`, `charts`, `composerCharts`, `sqlCharts`, `dataApps` with their actions. In the UI `Promoting dashboard` shows `To be created (n)` per kind; `Promote` (or `POST /api/v1/dashboards/$D/promote`) writes the copy upstream under new uuids. Restore `upstreamProjectUuid` to `null` at cleanup.
- **Duplicate.** Click `Dashboard actions` > `Duplicate`, rename in `Duplicate Dashboard`, click `Create duplicate`. API: `POST /api/v1/projects/$P/dashboards?duplicateFrom=$D` with `{"dashboardName":"Copy","dashboardDesc":""}` returns 201 and a new `uuid` and `slug`.
- **History.** `GET /api/v1/dashboards/$D/history` lists versions; in the UI `Dashboard actions` > `Version history`, a row's dots menu > `Restore this version`, then `Restore`. API restore: `POST /api/v1/dashboards/$D/rollback/<versionUuid>`.
- **Delete.** Click `Dashboard actions` > `Delete`, confirm `Delete` in the `Delete dashboard` dialog. API: `DELETE /api/v1/dashboards/$D` returns 200; a later `GET` returns 404; charts the dashboard owned are gone too.
- **Saved chart.** Open `/projects/$P/saved/$C/view`; the chart renders with its name as heading. API: `GET /api/v1/saved/$C` (definition), `GET /api/v1/saved/$C/history` (versions), `POST /api/v2/projects/$P/query/chart` with `{"chartUuid":"$C","context":"chartView"}` then poll as above.
- **As a viewer.** In the page run `fetch('/api/v1/login',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({email:'demo3@lightdash.com',password:'demo_password!'})})`, reload. `Edit dashboard` is absent. Create a private space as admin (`POST /api/v1/projects/$P/spaces` with `{"name":"Private proof","inheritParentPermissions":false}`), then a dashboard with that `spaceUuid` in the create body: the viewer gets 403 on it and its charts; `another@lightdash.com` (other org) gets 403 on every seed dashboard.
- **Minimal page.** Navigate to `/minimal/projects/$P/dashboards/$D`. Wait for `#lightdash-ready-indicator` to be attached (it is `hidden`, and mounts once every tile settles): `data-status` is `ready` or `completed-with-errors`, and `data-tiles-total`, `data-tiles-ready`, `data-tiles-errored` are counts.
- **Embed.** These two calls take an admin session (cookie jar per `../references/lightdash.md`); a PAT gets 403 `pat Account is not session auth`. `GET /api/v1/embed/$P/config` lists allowlisted `dashboardUuids`; the seed allowlists one arbitrary dashboard, so use `dashboardUuids[0]` as `$E`, or `PATCH` the same URL (body includes `allowAllDashboards`) and restore the saved config at cleanup. `POST /api/v1/embed/$P/get-embed-url` with `{"content":{"type":"dashboard","dashboardUuid":"$E"},"expiresIn":"1h"}` returns `results.url`; open it in the browser. Embed API calls take header `lightdash-embed-token: <url part after #>`, e.g. `POST /api/v1/embed/$P/dashboard`.

## Gotchas

- Seed dashboard and space uuids are generated by the seed; resolve them by name or slug each run.
- `PATCH /api/v1/dashboards/$D` replaces tiles, tabs and filters wholesale: read first, send all three back.
- `context` takes the enum strings `dashboardView` and `chartView`, not `dashboard` or `chart`.
- `Save changes` stays disabled until the layout or filters differ from the saved version.
- Preview defaults keep the shipped filter popover: `dashboard-controls` (filter sidebar), `in-dashboard-chart-editor` and `dashboard-custom-metrics` are off. Turning one on changes the handles above. `dashboard-fit-to-screen-default` and `dashboard-edit-ergonomics` are on, so view mode fits the screen and tile positions use a 72-column grid, unlike production defaults.
- A private space for a role check: delete it with `DELETE /api/v1/projects/$P/spaces/$S`.
- Soft delete is off in previews, so delete is permanent and restore has nothing to restore.
- An embed JWT and the embed config's `secret` are credentials: keep them out of artifacts; mint a fresh JWT to replay.
- The outsider persona has its own org and no project: use it for cross-org 403s, not for role checks.
