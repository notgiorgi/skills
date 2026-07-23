---
name: debug-lightdash-local
description: Debug Lightdash application issues against a local Lightdash development stack. Use when reproducing bugs on any locally running Lightdash instance, querying the matching local Postgres database with psql via `.env.development.local`, hitting local API endpoints with curl using the env-configured API key, or reproducing Lightdash CLI behavior with `pnpm -F cli dev` in the Lightdash repo.
---

# Debug Lightdash Local

Debug against the local Lightdash app before changing code. Reproduce the issue first, gather evidence from the app, API, database, and CLI, then narrow the failing layer.

## Quick Start

1. Work from the Lightdash repo root.
2. Read [references/local-debugging.md](./references/local-debugging.md) for the local commands and credentials.
3. Source `.env.development.local` before deeper debugging.
4. Reproduce with the narrowest tool that matches the bug:
   - `curl` for API or auth problems
   - `psql` for persisted state, content rows, or backend-side data checks
   - `pnpm -F cli dev ...` for CLI/content-as-code behavior
5. If the issue is about charts, dashboards, YAML, or semantic-layer content, also use [developing-in-lightdash](/Users/giorgi/develop/lightdash/skills/developing-in-lightdash/SKILL.md).

## Workflow

### Reproduce

- Prefer a direct repro over reading code first.
- Capture the exact request, CLI command, chart slug, dashboard slug, project UUID, and any error ID.
- Use `LIGHTDASH_API_KEY` from `.env.development.local` when calling the local API or running authenticated CLI commands.

### Isolate the Layer

- Use `curl` first when the bug may be in routing, auth, payload validation, or API responses.
- Use `pnpm -F cli dev` when the bug is only visible through the Lightdash CLI or content-as-code flows.
- Use `psql` when you need to verify what was stored, updated, or returned from the local Postgres database.
- Read repo code after you know which layer is lying.

### Verify the Fix

- Re-run the original repro with the same local command or request.
- Check for the expected persisted state with `psql` if the bug writes to the database.
- If the issue involves content as code, re-run the relevant `pnpm -F cli dev` command and, when useful, round-trip with download/upload.

## Guardrails

- Source `.env.development.local` before using `curl`, `psql`, or CLI commands that must target a specific local stack.
- Prefer targeted queries and API requests over broad scans.
- Do not assume CLI validation and server-side validation are the same; check both when debugging uploads.
