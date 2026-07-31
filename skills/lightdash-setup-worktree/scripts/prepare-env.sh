#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
main_root="$(dirname "$common_dir")"

if [ "$repo_root" = "$main_root" ]; then
    echo "ERROR: current checkout is the primary checkout, not a linked worktree" >&2
    exit 1
fi

source_env="$main_root/.env.development.local"
source_envrc="$main_root/.envrc"
target_env="$repo_root/.env.development.local"
target_envrc="$repo_root/.envrc"

test -f "$source_env" || { echo "ERROR: missing $source_env" >&2; exit 1; }
test -f "$source_envrc" || { echo "ERROR: missing $source_envrc" >&2; exit 1; }

dry_run=false
instance_arg=""
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=true ;;
        -*) echo "Usage: $0 [instance-id] [--dry-run]" >&2; exit 2 ;;
        *)
            test -z "$instance_arg" || { echo "Usage: $0 [instance-id] [--dry-run]" >&2; exit 2; }
            instance_arg="$arg"
            ;;
    esac
done

if [ -n "$instance_arg" ]; then
    instance_id="$instance_arg"
elif [[ "$repo_root" == */.codex/worktrees/*/* ]]; then
    instance_id="codex-$(basename "$(dirname "$repo_root")")"
else
    instance_id="$(basename "$repo_root")"
fi

instance_id="$(printf '%s' "$instance_id" | tr '[:upper:]_' '[:lower:]-' | sed -E 's/[^a-z0-9-]+/-/g; s/^-+//; s/-+$//')"
test -n "$instance_id" || { echo "ERROR: could not derive instance ID" >&2; exit 1; }

cd "$repo_root"
if [ "$dry_run" = false ]; then
    ./scripts/dev-ports.sh claim --instance-id "$instance_id" >/dev/null
fi
eval "$(./scripts/dev-ports.sh env --instance-id "$instance_id")"

if [ "$dry_run" = true ]; then
    dry_run_dir="$(mktemp -d)"
    trap 'rm -rf "$dry_run_dir"' EXIT
    target_env="$dry_run_dir/.env.development.local"
    target_envrc="$dry_run_dir/.envrc"
fi

cp "$source_envrc" "$target_envrc"
cp "$source_env" "$target_env"

tmp="${target_env}.tmp"

upsert() {
    local key="$1" value="$2"
    awk -v key="$key" -v value="$value" '
        BEGIN { found = 0 }
        {
            normalized = $0
            sub(/^export[[:space:]]+/, "", normalized)
            if (normalized ~ ("^" key "=")) {
                if (!found) print "export " key "=" value
                found = 1
                next
            }
            print
        }
        END { if (!found) print "export " key "=" value }
    ' "$target_env" > "$tmp"
    mv "$tmp" "$target_env"
}

remove_key() {
    local key="$1"
    awk -v key="$key" '
        {
            normalized = $0
            sub(/^export[[:space:]]+/, "", normalized)
            if (normalized ~ ("^" key "=")) next
            print
        }
    ' "$target_env" > "$tmp"
    mv "$tmp" "$target_env"
}

upsert LD_INSTANCE_ID "$LD_INSTANCE_ID"
upsert PGHOST localhost
upsert PGPORT "$LD_PG_PORT"
upsert PGUSER postgres
upsert PGPASSWORD password
upsert PGDATABASE postgres
upsert PGCONNECTIONURI "postgresql://postgres:password@localhost:${LD_PG_PORT}/postgres"
upsert PORT "$PORT"
upsert FE_PORT "$FE_PORT"
upsert SCHEDULER_PORT "$SCHEDULER_PORT"
upsert DEBUG_PORT "$DEBUG_PORT"
upsert SDK_TEST_PORT "$SDK_TEST_PORT"
upsert SPOTLIGHT_PORT "$SPOTLIGHT_PORT"
upsert LIGHTDASH_PROMETHEUS_PORT "$LIGHTDASH_PROMETHEUS_PORT"
upsert SITE_URL "http://localhost:${FE_PORT}"
upsert INTERNAL_LIGHTDASH_HOST "http://localhost:${FE_PORT}"
upsert LIGHTDASH_API_URL "http://localhost:${PORT}"
upsert LIGHTDASH_URL "http://localhost:${FE_PORT}"
upsert DBT_DEMO_DIR "$repo_root/examples/full-jaffle-shop-demo"
upsert ALLOW_MULTIPLE_ORGS true
upsert DEV_SCOPED_COOKIE_NAMES_ENABLED true
upsert S3_ENDPOINT http://localhost:9000
upsert HEADLESS_BROWSER_HOST localhost
upsert HEADLESS_BROWSER_PORT 3001
upsert EMAIL_SMTP_HOST localhost
upsert EMAIL_SMTP_PORT 1025
upsert EMAIL_SMTP_SECURE false
upsert EMAIL_SMTP_USE_AUTH false
upsert EMAIL_SMTP_ALLOW_INVALID_CERT true

remove_key NATS_URL
remove_key NATS_WORKER_CONCURRENCY
remove_key NATS_WORKER_PORT

cookie_lines="$(grep -Ec '^(export[[:space:]]+)?DEV_SCOPED_COOKIE_NAMES_ENABLED=true$' "$target_env")"
test "$cookie_lines" -eq 1 || { echo "ERROR: scoped cookie invariant failed" >&2; exit 1; }
if grep -Eq '^(export[[:space:]]+)?NATS_(URL|WORKER_CONCURRENCY|WORKER_PORT)=' "$target_env"; then
    echo "ERROR: NATS invariant failed" >&2
    exit 1
fi

if [ "$dry_run" = true ]; then
    echo "DRY-RUN READY: instance=$LD_INSTANCE_ID frontend=$FE_PORT api=$PORT postgres=$LD_PG_PORT"
else
    echo "READY: instance=$LD_INSTANCE_ID frontend=$FE_PORT api=$PORT postgres=$LD_PG_PORT"
fi
echo "ENV: $target_env"
echo "ENVRC: $target_envrc"
