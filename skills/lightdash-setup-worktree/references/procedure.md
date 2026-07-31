# Delegated Lightdash worktree procedure

Treat **isolation** as the invariant: the worktree owns its Herdr workspace, application ports, PostgreSQL container, volume, and cookie name. It may reuse fixed MinIO, browser, and Mailpit services. Leave every existing app process and database running.

## Setup

### 1. Map the live machine

Run read-only checks before allocating anything:

```bash
pwd
git rev-parse --show-toplevel
git status --short --branch
herdr workspace list
herdr worktree list --cwd "$PWD" --json
./scripts/dev-ports.sh list
docker ps --format '{{.Names}}\t{{.Ports}}\t{{.Labels}}'
```

Check listeners for default ports, claimed instance ports, and shared ports `9000`, `3001`, and `1025`. Treat registry entries as claims, not proof that services are live.

Completion: identify every existing Lightdash checkout, Herdr workspace, claimed slot, live listener, and dirty file that setup must preserve.

### 2. Open the worktree through Herdr

Choose a friendly `WORKTREE_LABEL` from the delegated task context. Prefer `<lowercase-task-code>-<short-kebab-case-description>`, for example `zap-721-transcript-serialization`; without a task code, use the short description, then fall back to the checkout directory name. Use the same label when opening or creating the worktree.

Use Herdr's first-class worktree command:

```bash
WORKTREE_LABEL="<friendly-label>"
ROOT="$(git rev-parse --show-toplevel)"
MAIN="$(dirname "$(git rev-parse --path-format=absolute --git-common-dir)")"
herdr worktree open --cwd "$MAIN" --path "$ROOT" --label "$WORKTREE_LABEL" --no-focus --json
```

If the linked worktree does not exist, create it with `herdr worktree create --cwd "$MAIN" --branch <branch> --base <ref> --path <path> --label "$WORKTREE_LABEL" --no-focus --json`, then continue from the returned checkout path. Use Herdr rather than raw `git worktree` so workspace ownership is established at creation.

`already_open: true` is success. Read the returned workspace, tab, and root-pane IDs. Rename an unused initial tab to `dev-server`; reuse an existing `dev-server` tab when present.

Completion: the returned workspace label equals `WORKTREE_LABEL`, and `workspace.worktree.checkout_path` and the server pane cwd both equal `ROOT`.

### 3. Prepare isolated environment

If this worktree already has `pnpm dev`, stop only that Herdr pane before replacing its env; restart it in step 6.

Run the bundled script from the repository root:

```bash
~/.agents/skills/lightdash-setup-worktree/scripts/prepare-env.sh
```

It derives a stable instance ID, claims a free slot, copies the main checkout's `.envrc` and `.env.development.local` without printing secrets, reconciles every instance port, removes NATS overrides, and leaves exactly one `DEV_SCOPED_COOKIE_NAMES_ENABLED=true`.

Verify its non-secret output against `./scripts/dev-ports.sh show --instance-id <id>` and `lsof`. Resolve any collision before continuing.

Completion: the registry path is this worktree, ports are unowned or owned by this instance, and the env contains one effective scoped-cookie declaration set to `true`.

### 4. Prepare dependencies in Herdr

Use the worktree's Herdr pane for all package commands. Keep the server stopped during installation and build.

```bash
direnv allow
corepack enable pnpm
pnpm install
pnpm clean:build
```

If `venv/bin/dbt1.11` is absent and the main checkout has a working `venv`, link this worktree's `venv` to it before `direnv allow`. Use `pnpm clean:build` as the single build command; do not build packages piecemeal.

Inspect `git status` after the build. Generated `routes.ts` or `swagger.json` changes are setup artifacts until classified; never mix them into unrelated work.

Completion: `pnpm` resolves in the Herdr shell, `dbt1.11` resolves, the build succeeds, and every worktree diff is accounted for.

### 5. Prepare infrastructure

Reuse live MinIO (`9000`), headless browser (`3001`), and Mailpit (`1025`). Start only a missing shared service, never an entire competing shared stack. Do not start NATS.

Load the claimed instance variables and start only its PostgreSQL service:

```bash
eval "$(./scripts/dev-ports.sh env --instance-id <id>)"
docker compose -p "$LD_COMPOSE_PROJECT" -f docker/docker-compose.dev.instance.yml --env-file .env.development up -d db-dev
```

Read [database-template.md](database-template.md) when the instance database is empty, a reusable template exists, or migration compatibility is uncertain. Follow its proof gate before publishing or consuming a shared template.

Completion: only the current instance's PostgreSQL container was created or changed, `pg_isready` succeeds, migrations are compatible, seed/project data exists, and local warehouse credentials target `LD_PG_PORT`.

### 6. Start Lightdash

From the `dev-server` Herdr pane:

```bash
direnv allow
pnpm dev
```

Use this direct command. Keep PM2 and dotenv wrappers out of the worktree workflow; `direnv` is the environment source of truth.

Completion: the pane title is `pnpm dev`, its foreground cwd belongs to this worktree, and no other workspace process changed.

### 7. Prove isolation

Verify all four layers:

```bash
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$PORT/api/v1/health"
curl -s -o /dev/null -w '%{http_code}\n' "http://localhost:$FE_PORT/"
lsof -nP -iTCP:"$PORT" -sTCP:LISTEN
lsof -nP -iTCP:"$FE_PORT" -sTCP:LISTEN
lsof -nP -iTCP:"$LD_PG_PORT" -sTCP:LISTEN
```

Confirm the backend process has `DEV_SCOPED_COOKIE_NAMES_ENABLED=true`; development sessions must use `connect.sid.$PORT`, so localhost cookies do not cross worktree ports. Query the instance DB for the seed user/project and run one ordinary Jaffle Shop query when runtime proof matters.

Report the Herdr workspace/pane, frontend/API/PostgreSQL ports, reused shared services, template provenance, migration status, and remaining worktree diffs.

Completion: frontend and API return `200`, listeners map to this worktree and instance, the DB query succeeds on the claimed port, scoped cookies are effective, and all untested paths are named.

## Teardown

Run `~/.agents/skills/lightdash-setup-worktree/scripts/teardown.sh`. Use `destroy --confirm-destroy <instance-id>` only when the user explicitly requests deletion of this instance's PostgreSQL volume. The script owns teardown behavior; do not reproduce its steps manually.

Completion: the script reports that this worktree's owned processes and claims are released; preserve the PostgreSQL volume unless its deletion was explicitly requested, and report what remains.

## Hard guardrails

- Target Herdr, Docker, and database commands with explicit IDs resolved from live output.
- Preserve existing workspaces, containers, volumes, ports, and processes.
- Publish a shared template only after its applied migration list is compatible with the checkout; meaningful branch-only migration data makes it branch-specific.
- Use `docker exec ... psql`; do not use `scripts/reset-db.sh`.
- Treat `stop-all`, shared-volume replacement, and migration-row deletion as separate destructive operations requiring explicit user direction.
