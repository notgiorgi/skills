# Database and template branch

Use this branch only after the worktree has a claimed instance ID and its PostgreSQL container exists. Resolve all names from `./scripts/dev-ports.sh env --instance-id <id>`.

## Choose a source

Prefer, in order:

1. A compatible `ld-shared_postgres_base_ee` volume.
2. A consistent logical dump of the primary checkout's live `postgres` database.
3. Fresh migrate, seed, and Jaffle Shop dbt build.

Treat a template as compatible only when its PostgreSQL major version and applied Knex migration list match the checkout. Volume existence is not compatibility proof.

## Consume a volume template

Confirm the target names belong to the current instance, then stop only its DB and copy into only its volume:

```bash
docker compose -p "$LD_COMPOSE_PROJECT" -f docker/docker-compose.dev.instance.yml stop db-dev
docker run --rm \
  -v ld-shared_postgres_base_ee:/source:ro \
  -v "${LD_VOLUME_PREFIX}_postgres_data:/target" \
  alpine sh -c 'rm -rf /target/* && cd /source && tar cf - . | (cd /target && tar xf -)'
docker compose -p "$LD_COMPOSE_PROJECT" -f docker/docker-compose.dev.instance.yml start db-dev
```

Wait for `pg_isready`, then run the migration compatibility gate below. A PostgreSQL layout/version error means the template is unusable; recreate only the instance volume before trying another source.

## Copy the primary database logically

Resolve the primary database container from `docker ps` and verify it serves the expected primary port/database. A logical dump is consistent while the source remains running.

```bash
DUMP_FILE="$(mktemp /tmp/lightdash-postgres.XXXXXX.dump)"
docker exec <source-container> pg_dump -U postgres -Fc postgres > "$DUMP_FILE"
docker exec <target-container> psql -U postgres -d template1 -v ON_ERROR_STOP=1 \
  -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'postgres';" \
  -c "DROP DATABASE postgres;" \
  -c "CREATE DATABASE postgres;"
docker exec -i <target-container> pg_restore -U postgres -d postgres --no-owner --no-privileges < "$DUMP_FILE"
```

Remove the temporary dump after verification.

## Migration compatibility gate

From the Herdr pane after `direnv allow`, run:

```bash
pnpm -F backend migrate
```

Success is `Already up to date` or a successful batch. If Knex reports missing applied migrations:

1. List the exact `knex_migrations` rows and lock state.
2. Find each file in the current checkout and `git log --all`.
3. Inspect its schema effect, row counts, data values, and current-code references.
4. Classify it as compatible, an empty orphan, or meaningful branch-specific state.

Repair only the copied instance DB, and only when the evidence shows empty orphan state. Meaningful branch-specific data makes the database and any snapshot branch-specific; do not publish it as a shared template.

## Reconcile local warehouse credentials

Copied credentials retain the source PostgreSQL port. Run the repository's `warehouse-port-fix` reconcile with the same `LIGHTDASH_SECRET` used by the source and the target `PGPORT`. Verify the credential decrypts and reports `localhost:$LD_PG_PORT`.

## Publish a template

Publish only after migrations pass, seed/project rows exist, and the PostgreSQL layout matches `docker-compose.dev.instance.yml`. Never overwrite an existing shared template implicitly.

Stop only the instance DB, create the requested shared volume, copy the instance volume into it, then restart the instance DB. Record the source checkout commit, PostgreSQL version, migration count, and creation time in the handoff.

Completion: a fresh instance can consume the template, pass `pnpm -F backend migrate`, query the seed project, and start without modifying any existing database.
