#!/usr/bin/env bash
# Set up a machine: global agent instructions + every skill I use (this repo + externals).
# Add new externals here so other machines can replay them.
set -euo pipefail
cd "$(dirname "$0")"

# one global instructions file, symlinked for every agent; existing real files kept as .bak
link() { mkdir -p "$(dirname "$2")"; [ -e "$2" ] && [ ! -L "$2" ] && mv "$2" "$2.bak"; ln -sfn "$1" "$2"; }
link "$PWD/global/AGENTS.md" ~/.agents/AGENTS.md
link "$PWD/global/CLAUDE.md" ~/.claude/CLAUDE.md
link ~/.agents/AGENTS.md ~/.codex/AGENTS.md

# executor MCP (linear/pylon/sentry/lightdash behind one server); needs `executor` CLI on PATH
if command -v executor >/dev/null; then
  claude mcp add -s user executor -- executor mcp 2>/dev/null || true
  codex mcp add executor -- executor mcp 2>/dev/null || true
fi

add() { npx skills add "$@" -g --agent '*' -y; }

# this repo
add notgiorgi/skills --skill '*'

add mattpocock/skills \
  --skill ask-matt \
  --skill code-review \
  --skill codebase-design \
  --skill diagnosing-bugs \
  --skill domain-modeling \
  --skill grill-me \
  --skill grill-with-docs \
  --skill grilling \
  --skill handoff \
  --skill implement \
  --skill implement-spec \
  --skill improve-codebase-architecture \
  --skill prototype \
  --skill research \
  --skill resolving-merge-conflicts \
  --skill retro \
  --skill setup-matt-pocock-skills \
  --skill tdd \
  --skill teach \
  --skill to-questionnaire \
  --skill to-spec \
  --skill to-tickets \
  --skill triage \
  --skill wait-what \
  --skill wayfinder \
  --skill wizard \
  --skill writing-for-agents \
  --skill writing-great-skills

add github/gh-stack \
  --skill gh-stack

add ogulcancelik/herdr \
  --skill herdr

add pbakaus/impeccable \
  --skill impeccable

add humanlayer/skills \
  --skill show-me \
  --skill visual-pr

add typesafe-ai/skills \
  --skill typesafe-ai
