# Content as code

A user downloads a project's charts and dashboards as YAML with the `lightdash` CLI, edits the files, and uploads them back; the server creates, updates or skips each item and reports what it did. The same documents are readable and writable over the `/api/v1/projects/{p}/code/...` endpoints the CLI calls.

## Sub-features

- `cac-download` writes `charts/<slug>.yml` and `dashboards/<slug>.yml` (SQL charts `<slug>.sql.yml`) for a project or selected items.
- `cac-download-linked` a `--dashboards` download also writes the charts those dashboards use.
- `cac-upload-noop` an unedited upload changes nothing.
- `cac-upload-edit` an edited file updates the item and adds a version.
- `cac-upload-create` a file for a slug the project lacks creates the item.
- `cac-api-read` `GET .../code/charts|dashboards?ids=` returns the documents.
- `cac-api-write` `POST .../code/charts|dashboards/{slug}` upserts one document and reports the action.
- `cac-lint` `lightdash lint` validates local files without a server write.

## How to get to it (user POV)

- Terminal: `lightdash download`, `lightdash upload`, `lightdash lint` (each takes `--help`).
- API: `/api/v1/projects/{projectUuid}/code/charts`, `/code/dashboards`, `/code/sqlCharts` and `POST` to the same paths plus `/{slug}`.
- No browser entry; the UI shows the result on the chart or dashboard page and its history.

## Driving it

Preconditions:

- CLI matches the revision under proof: in a checkout at the env's served sha, `pnpm -F @lightdash/cli build`, then run `node packages/cli/dist/index.js`. Record its `--version`.
- Shell env: `export LIGHTDASH_URL="$ENV_URL" LIGHTDASH_API_KEY="$PAT" LIGHTDASH_PROJECT=3675b69e-8324-4110-bdca-059031aa8da3 HOME="$(mktemp -d)"`. The env vars override any saved `lightdash login`; the temp `HOME` keeps your own `~/.config/lightdash` out of the run.
- Inside the guest instead: `guest: cd /tmp && LIGHTDASH_URL=http://localhost:8080 LIGHTDASH_API_KEY=$PAT LIGHTDASH_PROJECT=$P lightdash download --path /tmp/cac`.
- Work in a proof-owned dashboard (create one per `dashboards-and-charts.md`) so uploads never touch seed content.

- **Download selected.** Run `node packages/cli/dist/index.js download --path ./cac --dashboards <dashboard-slug> --skip-spaces`. Exit 0; `./cac/dashboards/<dashboard-slug>.yml` exists plus one `./cac/charts/<chart-slug>.yml` per chart on it.
- **Download project.** Run `node packages/cli/dist/index.js download --path ./cac-all`. Exit 0; the summary counts charts and dashboards; spot-check a known slug such as `charts/how-much-revenue-do-we-have-per-payment-method.yml`.
- **No-op upload.** Run `node packages/cli/dist/index.js upload --path ./cac --skip-spaces`. Exit 0 with `All content was skipped (no local changes detected)`. Server side: `GET /api/v1/saved/$C/history` length unchanged.
- **Edited upload.** Wait 31 s after download, change `name:` in `charts/<chart-slug>.yml`, rerun upload. Output shows `Total charts updated: 1`; `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/saved/$C"` returns the new name and `/history` gained one version.
- **Forced upload.** Add `--force` (optionally `--charts <slug>` / `--dashboards <slug>`) to send files regardless of mtime. Use it for an immediate edit or a fresh target project.
- **Round trip.** Download again into a new path and `diff -r -x .lightdash-metadata.json` against the edited copy: no differences.
- **API read.** `curl -H "Authorization: ApiKey $PAT" "$ENV_URL/api/v1/projects/$P/code/charts?ids=<chart-slug>"` returns `results.charts[0]` (same fields as the YAML) and `results.missingIds` for unknown slugs; `code/dashboards?ids=<dashboard-slug>` likewise.
- **API write.** POST the document read above, as JSON, to `$ENV_URL/api/v1/projects/$P/code/charts/<chart-slug>` (`-H 'Content-Type: application/json'`). 200 with `results.charts[0].action` one of `no changes`, `create`, `update`; `results.dashboards[]` and `results.spaces[]` report side effects. Add `"force": true` to the body to bypass the server's unchanged check.
- **Lint.** `node packages/cli/dist/index.js lint --path ./cac` exits 0 for valid files and non-zero naming the file and field for an invalid one.
- **Second side.** Pair every CLI claim with server state: `GET /api/v1/saved/$C/history`, `GET /api/v1/dashboards/$D/history`, the chart or dashboard page in the browser, or `guest: runuser -u postgres -- psql -d postgres -XAt -c "select count(*) from saved_queries_versions v join saved_queries q using (saved_query_id) where q.slug='<chart-slug>'"`.

## Gotchas

- The upload skips a file whose mtime is within 30 s of its download time (kept in `<path>/.lightdash-metadata.json`): an immediate edit looks unchanged. Wait, `touch` the file later, or pass `--force`.
- `--force` re-sends unchanged content; a forced chart upload can append a version with identical content (seen on composer charts). Measure no-op behaviour without `--force`.
- An identical dashboard upload reports `update` and appends a dashboard version, while its charts report `no changes`. Compare history counts, not the action label, before calling a no-op a regression.
- The guest's `lightdash` is rebuilt only when `packages/cli/**` changes; a change in `packages/common` alone leaves it on the old schema. Build from the checkout when common changed.
- The published npm CLI differs from the checkout build; name which one produced each transcript.
- Seed charts are shared fixtures: upload only into proof-owned dashboards and spaces, and delete them at cleanup.
