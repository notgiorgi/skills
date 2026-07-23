# Local Debugging

Use these commands for local Lightdash debugging in `/Users/giorgi/develop/lightdash`.

Always source the local env file first so the shell targets the right parallel stack:

```bash
source /Users/giorgi/develop/lightdash/.env.development.local
```

## Local Server

- Use `SITE_URL` from `.env.development.local`. Do not hardcode `localhost:3000`; another local stack may be running on a different port such as `3033`.
- Health check:
  - `curl "$SITE_URL/api/v1/health"`

## Local API Auth

- Use `LIGHTDASH_API_KEY` from `.env.development.local`.
- Example authenticated request:
  - `curl -H "Authorization: ApiKey $LIGHTDASH_API_KEY" "$SITE_URL/api/v1/user"`

## Local Postgres

Credentials live in `/Users/giorgi/develop/lightdash/.env.development.local`. Use the exported `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, and `PGDATABASE` from that file. Do not assume the database name is `postgres`; it may be something like `postgres3`.

Use:

```bash
source /Users/giorgi/develop/lightdash/.env.development.local
psql
```

Or run directly:

```bash
source /Users/giorgi/develop/lightdash/.env.development.local
psql -c '\conninfo'
psql -c '\dt'
```

## Local CLI

Run the local CLI from the repo root with:

```bash
pnpm -F cli dev [commands]
```

Useful commands:

```bash
pnpm -F cli dev diagnostics
pnpm -F cli dev download --help
pnpm -F cli dev upload --help
pnpm -F cli dev lint --help
pnpm -F cli dev run-chart --help
```

Use the env-configured API key inline when needed:

```bash
pnpm -F cli dev diagnostics
```

## Related Skill

For Lightdash content, YAML, semantic layer, dashboards, or chart-as-code work, also read:

- `/Users/giorgi/develop/lightdash/skills/developing-in-lightdash/SKILL.md`
