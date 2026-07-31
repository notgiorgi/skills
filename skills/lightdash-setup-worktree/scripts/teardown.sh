#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 [stop|destroy] [--instance-id ID] [--confirm-destroy ID] [--dry-run]" >&2
}

mode="stop"
instance_arg=""
confirm_destroy=""
dry_run=false

while [ $# -gt 0 ]; do
    case "$1" in
        stop|destroy)
            mode="$1"
            shift
            ;;
        --instance-id)
            test $# -ge 2 || { usage; exit 2; }
            instance_arg="$2"
            shift 2
            ;;
        --confirm-destroy)
            test $# -ge 2 || { usage; exit 2; }
            confirm_destroy="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        *)
            usage
            exit 2
            ;;
    esac
done

repo_root="$(git rev-parse --show-toplevel)"
common_dir="$(git rev-parse --path-format=absolute --git-common-dir)"
main_root="$(dirname "$common_dir")"

if [ "$repo_root" = "$main_root" ]; then
    echo "ERROR: current checkout is the primary checkout, not a linked worktree" >&2
    exit 1
fi

read_env_value() {
    local key="$1" file="$2"
    awk -v key="$key" '
        {
            line = $0
            sub(/^export[[:space:]]+/, "", line)
            if (line ~ ("^" key "=")) {
                sub("^" key "=", "", line)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
                if (line ~ /^".*"$/ || line ~ /^'"'"'.*'"'"'$/) {
                    line = substr(line, 2, length(line) - 2)
                }
                print line
                exit
            }
        }
    ' "$file"
}

env_file="$repo_root/.env.development.local"
env_instance=""
if [ -f "$env_file" ]; then
    env_instance="$(read_env_value LD_INSTANCE_ID "$env_file")"
fi
if [ -n "$instance_arg" ]; then
    instance_id="$instance_arg"
elif [ -n "$env_instance" ]; then
    instance_id="$env_instance"
else
    instance_id=""
fi

if [ -z "$instance_id" ] && [[ "$repo_root" == */.codex/worktrees/*/* ]]; then
    instance_id="codex-$(basename "$(dirname "$repo_root")")"
elif [ -z "$instance_id" ]; then
    instance_id="$(basename "$repo_root")"
fi

if ! [[ "$instance_id" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "ERROR: unsafe instance ID: $instance_id" >&2
    exit 1
fi
if [ -n "$env_instance" ] && [ "$env_instance" != "$instance_id" ]; then
    echo "ERROR: instance $instance_id does not match this worktree's env instance $env_instance" >&2
    exit 1
fi

if [ "$mode" = "destroy" ] && [ "$dry_run" = false ] && [ "$confirm_destroy" != "$instance_id" ]; then
    echo "ERROR: destroy requires --confirm-destroy $instance_id" >&2
    exit 1
fi

cd "$repo_root"
dev_ports_script="${DEV_PORTS_SCRIPT:-./scripts/dev-ports.sh}"
test -x "$dev_ports_script" || { echo "ERROR: missing executable dev-ports script: $dev_ports_script" >&2; exit 1; }
registry_found=false
registry_json=""
if registry_json="$("$dev_ports_script" show --instance-id "$instance_id" 2>/dev/null)"; then
    registry_found=true
    registry_path="$(printf '%s' "$registry_json" | python3 -c 'import json,sys; print(json.load(sys.stdin)["worktreePath"])')"
    if [ "$registry_path" != "$repo_root" ]; then
        echo "ERROR: instance $instance_id belongs to $registry_path" >&2
        exit 1
    fi
    eval "$("$dev_ports_script" env --instance-id "$instance_id")"
else
    LD_INSTANCE_ID="$instance_id"
    LD_COMPOSE_PROJECT="ld-$instance_id"
    LD_VOLUME_PREFIX="ld-$instance_id"
    LD_CONTAINER_PREFIX="ld-$instance_id"
    PORT="$(read_env_value PORT "$env_file" 2>/dev/null || true)"
    FE_PORT="$(read_env_value FE_PORT "$env_file" 2>/dev/null || true)"
    LD_PG_PORT="$(read_env_value PGPORT "$env_file" 2>/dev/null || true)"
fi
export LD_INSTANCE_ID LD_COMPOSE_PROJECT LD_VOLUME_PREFIX LD_CONTAINER_PREFIX LD_PG_PORT

worktree_json="$(herdr worktree list --cwd "$repo_root" --json)"
workspace_id="$(printf '%s' "$worktree_json" | TEARDOWN_REPO_ROOT="$repo_root" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
root = os.environ["TEARDOWN_REPO_ROOT"]
matches = [w.get("open_workspace_id", "") for w in data["result"]["worktrees"] if w.get("path") == root]
print(matches[0] if len(matches) == 1 else "")
')"

pane_id=""
if [ -n "$workspace_id" ]; then
    panes_json="$(herdr pane list --workspace "$workspace_id")"
    pane_id="$(printf '%s' "$panes_json" | TEARDOWN_REPO_ROOT="$repo_root" python3 -c '
import json, os, sys
data = json.load(sys.stdin)
root = os.environ["TEARDOWN_REPO_ROOT"]
matches = []
for pane in data["result"]["panes"]:
    cwd = pane.get("cwd", "")
    foreground = pane.get("foreground_cwd", "")
    owns_path = cwd == root or foreground == root or foreground.startswith(root + os.sep)
    if owns_path and pane.get("terminal_title_stripped") == "pnpm dev":
        matches.append(pane["pane_id"])
if len(matches) > 1:
    raise SystemExit("multiple pnpm dev panes belong to this worktree")
print(matches[0] if matches else "")
')"
fi

container_name="${LD_CONTAINER_PREFIX}-db-dev-1"
container_found=false
if docker ps -a --filter "name=^/${container_name}$" --format '{{.Names}}' | grep -Fxq "$container_name"; then
    container_found=true
fi

echo "TEARDOWN: mode=$mode instance=$instance_id"
echo "HERDR: workspace=${workspace_id:-none} pane=${pane_id:-none}"
echo "DATABASE: project=$LD_COMPOSE_PROJECT container=$container_name found=$container_found"
echo "REGISTRY: claimed=$registry_found"

run() {
    if [ "$dry_run" = true ]; then
        printf 'DRY-RUN:'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

if [ -n "$pane_id" ]; then
    run herdr pane send-keys "$pane_id" ctrl+c
else
    echo "SKIP: no pnpm dev pane owned by this worktree"
fi

if [ "$container_found" = true ]; then
    if [ "$mode" = "destroy" ]; then
        run docker compose -p "$LD_COMPOSE_PROJECT" -f docker/docker-compose.dev.instance.yml --env-file .env.development down --volumes
    else
        run docker compose -p "$LD_COMPOSE_PROJECT" -f docker/docker-compose.dev.instance.yml --env-file .env.development stop db-dev
    fi
else
    echo "SKIP: no instance database container"
fi

if [ "$registry_found" = true ]; then
    run "$dev_ports_script" release --instance-id "$instance_id"
else
    echo "SKIP: no instance port claim"
fi

if [ "$dry_run" = true ]; then
    echo "DRY-RUN COMPLETE: no state changed"
else
    echo "TEARDOWN COMPLETE: mode=$mode instance=$instance_id"
fi
echo "PRESERVED: Git worktree, Herdr workspace, env files, shared services"
if [ "$mode" = "stop" ]; then
    echo "PRESERVED: PostgreSQL volume"
fi
