#!/usr/bin/env bash
# Install every skill I use globally: this repo + external sources.
# Add new externals here so other machines can replay them.
set -euo pipefail

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
